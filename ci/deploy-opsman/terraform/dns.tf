resource "google_dns_record_set" "ops-manager-dns" {
  name = "opsmgr.${var.domain}"
  type = "A"
  ttl  = 300

  managed_zone = "${var.zone_name}"

  rrdatas = ["${google_compute_address.ops-manager.address}"]
}