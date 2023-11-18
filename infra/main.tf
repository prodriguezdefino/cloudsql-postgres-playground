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