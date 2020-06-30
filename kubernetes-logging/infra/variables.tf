variable "cluster_description" {
  description = "GKE cluster short description"
  type        = string
  default     = "Otus Kubernetes Homework"
}

variable "cluster_name" {
  description = "Name of GKE cluster"
  type        = string
  default     = "otus-kubernetes-hw"
}

variable "node_count" {
  description = "GKE cluster initial node count"
  type        = number
  default     = 1
}

variable "cluster_zone" {
  description = "GKE cluster zone"
  type        = string
  default     = "europe-west2-a"
}

variable "provider_project_name" {
  description = "GCP project name"
  type        = string
  default     = "otus-hw"
}

variable "provider_region" {
  description = "GCP region"
  type        = string
  default     = "europe-west2"
}

variable "logging_service" {
  description = "Default logging service provided by GKE"
  type        = string
  default     = "none"
}

variable "monitoring_service" {
  description = "Default monitoring service provided by GKE"
  type        = string
  default     = "none"
}

variable "machine_type" {
  description = "A type of virtual machine instance"
  type        = string
  default     = "n1-standard-2"
}

variable "credentials_json" {
  description = "A json file with Terraform service account credentials"
  type        = string
}
