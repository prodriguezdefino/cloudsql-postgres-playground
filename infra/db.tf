
resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database" "source" {
    project = var.project
  name     = local.db_name
  instance = google_sql_database_instance.source_pg.name
}

resource "google_sql_database_instance" "source_pg" {
  name                = "source-instance-${random_id.db_name_suffix.hex}"
  database_version    = "POSTGRES_9_6"
  project             = var.project
  region              = var.region
  root_password       = var.postgres_passwd
  deletion_protection = false

  settings {
    tier = "db-custom-32-122880"

    ip_configuration {
      enable_private_path_for_google_cloud_services = false
      require_ssl                                   = false
      authorized_networks {
          name  = google_compute_address.nat_ext_address.name
          value = google_compute_address.nat_ext_address.address
      }
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }

    database_flags {
      name  = "cloudsql.enable_pglogical"
      value = "on"
    }

    database_flags {
      name  = "cloudsql.logical_decoding"
      value = "on"
    }
  }

  depends_on =[google_service_networking_connection.private_vpc_connection]
}
