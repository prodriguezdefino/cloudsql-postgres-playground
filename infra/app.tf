
resource "google_service_account" "testsa" {
  project    = var.project
  account_id = "test-connectivity"
}

resource "google_compute_instance" "apps" {
  count        = 1
  name         = "apps-${count.index + 1}"
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

  depends_on = [null_resource.stage_app_jar]
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

resource "google_sql_user" "iam_service_account_user" {
  project  = var.project
  name     = trimsuffix(google_service_account.testsa.email, ".gserviceaccount.com")
  instance = google_sql_database_instance.source_pg.name
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
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