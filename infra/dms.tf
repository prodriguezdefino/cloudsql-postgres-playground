resource "google_database_migration_service_private_connection" "default" {
    count                 = var.setup_dms ? 1 : 0

    project               = var.project
    display_name          = "source-connection-${var.run_name}"
    private_connection_id = "source-connection-${var.run_name}"
    location              = var.region

    vpc_peering_config {
        vpc_name = google_compute_network.net_priv.id
        subnet   = "10.15.0.0/29"
    }
}

resource "google_database_migration_service_connection_profile" "postgresprofile" {
    count                = var.setup_dms ? 1 : 0

    project               = var.project
    connection_profile_id = "source-connection-${var.run_name}"
    display_name          = "source-connection-${var.run_name}"
    location              = var.region

    postgresql {
        host         = google_sql_database_instance.source_pg.private_ip_address
        port         = 5432
        username     = "postgres"
        password     = var.postgres_passwd
        cloud_sql_id = google_sql_database_instance.source_pg.id
    }
}

variable setup_dms {
    default = false
}