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

resource "google_service_account" "testsa" {
  project    = var.project
  account_id = "test-connectivity"
}

module "data_processing_project_membership_roles" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = google_service_account.testsa.email
  project_id              = var.project
  project_roles           = [
    "roles/storage.objectAdmin",
    "roles/cloudsql.instanceUser",
    "roles/cloudsql.client",
    "roles/monitoring.metricWriter",
    ]
}

variable run_name {}
variable project {}
variable region { default = "us-central1"}
variable zone { default = "us-central1-a"}
variable postgres_passwd { default = "somepassword"}