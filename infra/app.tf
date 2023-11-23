locals {
  instance_template = templatefile("${path.module}/templates/app_startup.sh.tpl", {
    db_name       = local.db_name
    pg_psswd      = var.postgres_passwd
    pg_ip         = google_compute_address.pgbouncer_address.address
    instance_name = google_sql_database_instance.source_pg.connection_name
    bucket_name   = google_storage_bucket.staging.name
  })
}

resource "google_compute_instance" "testapps" {
  count        = 1
  name         = "testapp-${var.run_name}-${count.index + 1}"
  machine_type = "n1-standard-4"
  project      = var.project
  zone         = var.zone
  tags         = ["allow-ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_priv.self_link
  }

  metadata_startup_script = local.instance_template

  service_account {
    email  = google_service_account.testsa.email
    scopes = ["cloud-platform"]
  }

  depends_on = [null_resource.stage_app_jar, google_compute_instance.pgbouncer]
  lifecycle {
    replace_triggered_by = [
      google_compute_instance.pgbouncer.id
    ]
  }
}

resource "null_resource" "stage_app_jar" {

  triggers = {
    bucket_name = google_storage_bucket.staging.name
    script_sha1 = "${sha1(file("${path.module}/scripts/deploy_jar.sh"))}"
    app_sha1 = "${sha1(filebase64("${path.module}/../app/target/postgres-migration-test-app-1.1-SNAPSHOT.jar"))}"
  }

  provisioner "local-exec" {
    when       = create
    command    = "${path.module}/scripts/deploy_jar.sh ${self.triggers.bucket_name}"
    on_failure = fail
  }

  depends_on = [google_storage_bucket.staging]
}