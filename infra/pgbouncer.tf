locals {
    source_pg_ip     = var.setup_dms ? google_sql_database_instance.source_pg.private_ip_address : google_sql_database_instance.source_pg.public_ip_address
    pg_ip            = var.migrated_db_ip == "" ? local.source_pg_ip : var.migrated_db_ip
    pgbouncer_config = templatefile(
        "${path.module}/templates/pgbouncer.ini.tpl",
        {
            db_host            = "${local.pg_ip}"
            db_port            = 5432
            listen_port        = 5432
            auth_user          = ""
            auth_query         = ""
            default_pool_size  = 200
            max_db_connections = 1000
            max_client_conn    = 500
            pool_mode          = "session"
            admin_users        = "postgres"
            custom_config      = ""
        })
    pgbouncer_instance_template = templatefile("${path.module}/templates/pgbouncer_startup_script.sh.tpl", {
        pgbouncer_config = local.pgbouncer_config
        pg_psswd         = var.postgres_passwd
        pg_ip            = local.pg_ip
    })
}

resource "google_compute_instance" "pgbouncer" {
  project      = var.project
  name         = "pgbouncer-${var.run_name}"
  machine_type = "n1-standard-8"
  zone         = var.zone
  tags         = ["allow-ssh", "allow-pg"]

  service_account {
    email  = google_service_account.testsa.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = local.pgbouncer_instance_template

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_priv.self_link
    network_ip = google_compute_address.pgbouncer_address.address

  }

  depends_on = [google_sql_database_instance.source_pg]
}

variable migrated_db_ip {
    default = ""
}
