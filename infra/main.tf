locals {
  db_name = "source-${var.run_name}"
  instance_template = templatefile("${path.module}/templates/startup.sh.tpl", {
    db_name       = local.db_name
    pg_psswd      = var.postgres_passwd
    pg_public_ip  = google_sql_database_instance.source_pg.public_ip_address
    instance_name = google_sql_database_instance.source_pg.connection_name
    bucket_name   = google_storage_bucket.staging.name
  })
}

resource "google_storage_bucket" "staging" {
  project       = var.project
  name          = "${var.run_name}-staging-${var.project}"
  location      = "US-CENTRAL1"
  storage_class = "REGIONAL"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }
  public_access_prevention = "enforced"
}

variable run_name {
}

variable project {}

variable region { default = "us-central1"}
variable zone { default = "us-central1-a"}
variable postgres_passwd { default = "somepassword"}