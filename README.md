# devops
DevOps Design

## GKE Autopilot (Terraform)

Terraform in `terraform/` provisions a [GKE Autopilot](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview) cluster.

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- [gcloud](https://cloud.google.com/sdk/docs/install) CLI, authenticated:
  - `gcloud auth login`
  - `gcloud auth application-default login`
- A GCP project with billing enabled

### Quick start

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project_id, region, cluster_name
terraform init
terraform plan
terraform apply
```

### Connect to the cluster

After apply, configure kubectl:

```bash
gcloud container clusters get-credentials <cluster_name> --region <region> --project <project_id>
```

Or use the output:

```bash
$(terraform output -raw kubeconfig_command)
```

### Inputs

| Variable | Description | Default |
|----------|-------------|---------|
| `project_id` | GCP project ID | (required) |
| `region` | GCP region (e.g. `us-central1`) | (required) |
| `cluster_name` | Cluster name | (required) |
| `release_channel` | `REGULAR`, `RAPID`, or `STABLE` | `REGULAR` |
| `network` / `subnetwork` | VPC (omit for default) | `default` / empty |
| `enable_private_cluster` | Private nodes (and optionally control plane) | `false` |
| `deletion_protection` | Block cluster deletion | `false` |
