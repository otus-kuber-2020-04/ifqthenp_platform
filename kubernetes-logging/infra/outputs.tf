output "latest_node_version" {
  value = data.google_container_engine_versions.europe-west2-a.latest_node_version
}

output "latest_master_version" {
  value = data.google_container_engine_versions.europe-west2-a.latest_master_version
}

output "default_cluster_version" {
  value = data.google_container_engine_versions.europe-west2-a.default_cluster_version
}
