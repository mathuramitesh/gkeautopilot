data "google_client_config" "default" {}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.40.0"  # Specify the version you need
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"  # Specify the version you need
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "gke_autopilot" {
  for_each = { for env in var.environments : env.name => env }

  name                  = "${each.value.name}-cluster"
  location              = var.region
  enable_autopilot      = true
  network               = var.network
  subnetwork            = var.subnetwork
  release_channel       = "STABLE"

  # Optional: Private cluster settings
  private_cluster_config {
    enable_private_nodes    = false
    enable_private_endpoint = false
  }

  # Optional: Vertical pod autoscaling settings
  vertical_pod_autoscaling {
    enabled = true
  }

  # Optional: IP alias settings
  ip_allocation_policy {
    use_ip_aliases = true
  }

  # Optional: Master authorized networks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = var.authorized_network
      display_name = "Authorized Network"
    }
  }

 
  lifecycle {
    prevent_destroy = false
  }
}

output "cluster_names" {
  value = { for env in google_container_cluster.gke_autopilot : env.name => env.name }
}

output "cluster_endpoints" {
  value = { for env in google_container_cluster.gke_autopilot : env.name => env.endpoint }
}

output "cluster_master_versions" {
  value = { for env in google_container_cluster.gke_autopilot : env.name => env.master_version }
}
