provider "google" {
  credentials = file(var.credentials_json)
  project     = var.provider_project_name
  region      = var.provider_region
}

data "google_container_engine_versions" "europe-west2-a" {
  location       = var.cluster_zone
  version_prefix = "1.16."
}

resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  network            = "default"
  location           = var.cluster_zone
  description        = var.cluster_description
  node_version       = data.google_container_engine_versions.europe-west2-a.latest_node_version
  min_master_version = data.google_container_engine_versions.europe-west2-a.latest_master_version
  logging_service    = var.logging_service
  monitoring_service = var.monitoring_service

  remove_default_node_pool = true
  initial_node_count       = var.node_count
}

resource "google_container_node_pool" "default" {
  name       = "default-pool"
  location   = var.cluster_zone
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    machine_type = var.machine_type

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "google_container_node_pool" "infra" {
  name       = "infra-pool"
  location   = var.cluster_zone
  cluster    = google_container_cluster.primary.name
  node_count = 3

  node_config {
    machine_type = var.machine_type

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    taint {
      effect = "NO_SCHEDULE"
      key    = "node-role"
      value  = "infra"
    }
  }
}
