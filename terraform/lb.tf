resource "google_compute_global_address" "lb-static-ip" {
  name         = "lb-static-ip"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

resource "google_compute_global_forwarding_rule" "http" {
  name       = "global-rule"
  target     = google_compute_target_https_proxy.default.self_link
  port_range = "443"
  ip_address = google_compute_global_address.lb-static-ip.address
  depends_on = [google_compute_global_address.lb-static-ip]
}

resource "google_compute_target_https_proxy" "default" {
  name    = "target-proxy"
  url_map = google_compute_url_map.default.self_link
  ssl_certificates = [
    google_compute_managed_ssl_certificate.default.id
  ]
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
resource "google_compute_url_map" "default" {
  name            = "em2-lb"
  description     = "a description"
  default_service = google_compute_backend_bucket.em2-backend.id

  # GCSのbucketをbackendに追加
  #  host_rule {
  #    hosts        = ["*"]
  #    path_matcher = "mysite"
  #  }

  #  path_matcher {
  #    name            = "mysite"
  #    default_service = google_compute_backend_service.default.self_link
  #  }
  depends_on = []

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

