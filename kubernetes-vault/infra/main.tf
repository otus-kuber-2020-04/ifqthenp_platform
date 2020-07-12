provider "google" {
  credentials = file(var.credentials_json)
  project     = var.provider_project_name
  region      = var.provider_region
}

data "google_container_engine_versions" "europe-west4-a" {
  location       = var.cluster_zone
  version_prefix = "1.16."
}

resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  network            = "default"
  location           = var.cluster_zone
  description        = var.cluster_description
  node_version       = data.google_container_engine_versions.europe-west4-a.latest_node_version
  min_master_version = data.google_container_engine_versions.europe-west4-a.latest_master_version
  initial_node_count = var.node_count
  logging_service    = var.logging_service
  monitoring_service = var.monitoring_service
}
