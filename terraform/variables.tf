variable "project_id" {
  description = "GCP project ID"
  type        = string
  default    = "excellent-grin-302222"
}

variable "region" {
  description = "GCP region for the cluster (e.g. us-central1)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE Autopilot cluster"
  type        = string
}

variable "release_channel" {
  description = "GKE release channel (REGULAR, RAPID, or STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "network" {
  description = "VPC network name (default creates default network)"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "VPC subnetwork name (default uses default subnet in region)"
  type        = string
  default     = ""
}

variable "enable_private_cluster" {
  description = "Enable private cluster (nodes and optionally control plane have no public IPs)"
  type        = bool
  default     = false
}

variable "private_endpoint" {
  description = "When true, cluster master is only accessible via private endpoint"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the control plane (required when enable_private_cluster is true)"
  type        = string
  default     = "172.16.0.0/28"
}

variable "maintenance_start_time" {
  description = "Start time for daily maintenance window (HHMM format, e.g. 0300 for 3am)"
  type        = string
  default     = "03:00"
}

variable "deletion_protection" {
  description = "Prevent accidental cluster deletion"
  type        = bool
  default     = false
}
