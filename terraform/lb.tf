resource "google_compute_global_address" "lb-static-ip" {
  name         = "lb-static-ip"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

resource "google_compute_global_forwarding_rule" "https" {
  name       = "https-rule"
  target     = google_compute_target_https_proxy.default.self_link
  port_range = "443"
  ip_address = google_compute_global_address.lb-static-ip.address
  depends_on = [google_compute_global_address.lb-static-ip]
}


resource "google_compute_global_forwarding_rule" "http" {
  name       = "http-rule"
  target     = google_compute_target_http_proxy.default.self_link
  port_range = "80"
  ip_address = google_compute_global_address.lb-static-ip.address
  depends_on = [google_compute_global_address.lb-static-ip]
}

resource "google_compute_target_https_proxy" "default" {
  name    = "target-proxy"
  url_map = google_compute_url_map.https.self_link
  ssl_certificates = [
    google_compute_managed_ssl_certificate.default.id
  ]
}

resource "google_compute_target_http_proxy" "default" {
  name    = "target-proxy"
  url_map = google_compute_url_map.http.self_link
}



# Google Managed 証明書
resource "google_compute_managed_ssl_certificate" "default" {
  #  provider = google-beta
  provider = google

  name = "em2-managed-ssl"

  managed {
    domains = [var.domain]
  }
}

# ------------------------------------------------------------------------------
# URL MAP
# ------------------------------------------------------------------------------
resource "google_compute_url_map" "https" {
  name            = "em2-lb"
  description     = "a description"
  default_service = google_compute_backend_bucket.em2-backend.id
}

resource "google_compute_url_map" "http" {
  name            = "http-redirect"
  default_url_redirect {
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    https_redirect         = true
    strip_query            = true
  }
}


# ------------------------------------------------------------------------------
# backend bucket
# ------------------------------------------------------------------------------
resource "google_compute_backend_bucket" "em2-backend" {
  name        = "em2-backend"
  bucket_name = google_storage_bucket.em2-site.name
  //  enable_cdn  = true
  //  enable_cdn = var.cloud_cdn_enabled
}

