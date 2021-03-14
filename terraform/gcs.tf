resource "google_storage_bucket" "em2-site" {
  name     = var.em2_bucket
  location = "US"
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}


#resource "google_storage_bucket_iam_member" "em2-site-iam" {
#  bucket = google_storage_bucket.em2-site.name
#  role = "roles/storage.objectViewer"
#  member = "allUsers"
#}
