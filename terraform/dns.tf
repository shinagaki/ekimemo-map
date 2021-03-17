resource "google_dns_managed_zone" "em2-zone" {
  name       = "em2-zone"
  dns_name   = "${var.domain}."
  depends_on = [google_project_service.dns]
}

resource "google_dns_record_set" "owner-txt" {
  name = "${var.domain}."
  type = "TXT"
  ttl  = 300

  managed_zone = google_dns_managed_zone.em2-zone.name

  rrdatas = ["google-site-verification=J1gjHMezc00mytSJ9zhO2JcfZmUkOTo-4FqgwA1axu4"]
}


resource "google_dns_record_set" "cname" {
  name = "${var.domain}."
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.em2-zone.name

  #  rrdatas = ["c.storage.googleapis.com."]
  rrdatas = [google_compute_global_address.lb-static-ip.address]
}
