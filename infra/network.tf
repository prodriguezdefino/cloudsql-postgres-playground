
resource "google_compute_network" "net_priv" {
  name                    = "network-${var.run_name}"
  auto_create_subnetworks = false
  project                 = var.project
}

resource "google_compute_subnetwork" "subnet_priv" {
  name                     = "${var.region}-subnet-${var.run_name}"
  project                  = var.project
  region                   = var.region
  private_ip_google_access = true
  ip_cidr_range            = "10.0.0.0/24"
  network                  = google_compute_network.net_priv.self_link
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-${var.run_name}"
  project                            = var.project
  network = "${google_compute_network.net_priv.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-ssh"]
}

resource "google_compute_address" "nat_ext_address" {
  project  = var.project
  name     = "nat-address-${var.run_name}"
  region   = var.region
}

resource "google_compute_router" "router" {
  name    = "net-router-${var.run_name}"
  project = var.project
  region  = google_compute_subnetwork.subnet_priv.region
  network = google_compute_network.net_priv.self_link

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat-${var.run_name}"
  project                            = var.project
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat_ext_address.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_global_address" "private_ip_address" {
  project       = var.project
  name          = "private-ip-address-${var.run_name}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.net_priv.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.net_priv.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}
