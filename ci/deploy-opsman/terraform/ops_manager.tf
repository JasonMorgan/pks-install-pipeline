resource "google_compute_instance" "ops-manager" {
  name = "${var.env_prefix}-ops-manager"
  machine_type = "${var.opsman_machine_type}"
  zone = "${element(var.zones, 0)}"
  tags = ["${var.env_prefix}-opsman", "allow-https", "allow-ssh"]
  timeouts {
    create = "10m"
  }
  boot_disk {
    initialize_params {
      image = "${var.pcf_opsman_image_name}"
      size  = 100
    }
  }
  network_interface {
    subnetwork = "${google_compute_subnetwork.infrastructure-subnet.name}"
    address = "${cidrhost(var.infrastructure_cidr, 5)}"
    access_config {
      nat_ip = "${google_compute_address.ops-manager-public-ip.address}"
    }
  }
}

resource "google_compute_address" "ops-manager-public-ip" {
  name = "${var.env_prefix}-om-public-ip"
}