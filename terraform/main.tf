terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "container" {
  project            = var.project_id
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_container_cluster" "autopilot" {
  name     = var.cluster_name
  location = var.region

  enable_autopilot = true

  # Autopilot clusters require release_channel
  release_channel {
    channel = var.release_channel
  }

  # Optional: configure cluster-level networking (omit for default network)
  network    = var.network
  subnetwork = var.subnetwork != "" ? var.subnetwork : null

  # Optional: private cluster (no public endpoint)
  dynamic "private_cluster_config" {
    for_each = var.enable_private_cluster ? [1] : []
    content {
      enable_private_nodes    = true
      enable_private_endpoint = var.private_endpoint
      master_ipv4_cidr_block  = var.master_ipv4_cidr_block
    }
  }

  # Optional: workload identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Optional: maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_start_time
    }
  }

  # Deletion protection for production
  deletion_protection = var.deletion_protection

  depends_on = [google_project_service.container]
}
