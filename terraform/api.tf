resource "google_project_service" "compute" {
  project = var.project
  service = "compute.googleapis.com"
}
resource "google_project_service" "dns" {
  project = var.project
  service = "dns.googleapis.com"
}
