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

1. **State backend:** Create a GCS bucket for state and lock files (see [docs/TERRAFORM_BACKEND.md](docs/TERRAFORM_BACKEND.md)). Then copy and edit the backend config:
   ```bash
   cd terraform
   cp backend.config.example backend.config
   # Edit backend.config with your bucket and prefix (e.g. gke-autopilot/PROJECT_ID/CLUSTER_NAME)
   ```
2. **Variables:** Copy and edit tfvars, then run Terraform:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your project_id, region, cluster_name
   terraform init -backend-config=backend.config
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

---

## GitHub Actions (repeatable deploys)

The workflow **Deploy GKE Autopilot** (`.github/workflows/gke-autopilot.yaml`) runs Terraform so you can build clusters in different projects, names, and regions from the Actions tab.

### Setup

**Option A: Workload Identity Federation (recommended)**  
No long-lived keys. See [docs/WIF_SETUP.md](docs/WIF_SETUP.md) for step-by-step instructions. Add repo variables `WIF_PROVIDER` and `WIF_SA` when done.

**Option B: Service account key**

1. **GCP service account**  
   Create a service account in the project(s) you will deploy to (or an org-level project) with:
   - **Kubernetes Engine Admin**
   - **Service Usage Consumer** (to enable APIs)  
   Optionally restrict to a single project with IAM conditions.

2. **JSON key**  
   Create a key for that service account and download the JSON.

3. **GitHub secret**  
   In the repo: **Settings → Secrets and variables → Actions** → **New repository secret**  
   - Name: `GOOGLE_CREDENTIALS`  
   - Value: paste the full contents of the JSON key file.

### Running the workflow

1. Open the **Actions** tab and select **Deploy GKE Autopilot**.
2. Click **Run workflow**.
3. Fill in the inputs (required: **project_id**, **region**, **cluster_name**). The rest use defaults.
4. Leave **Run terraform apply** unchecked to only run `terraform plan`; check it to run `terraform apply` and create/update the cluster.

Each run uses the inputs you provide, so you can target different projects, regions, and cluster names without changing code.

**Multiple clusters:** If you use the same repo to manage more than one cluster (different projects/names/regions), configure a [remote backend](https://www.terraform.io/language/settings/backends) (e.g. GCS) and use a state key that includes `project_id` and `cluster_name` (or similar) so each cluster has its own state file. Otherwise each run will overwrite the same local state.

### Destroying a cluster

Use the **Destroy GKE Autopilot** workflow (`.github/workflows/gke-autopilot-destroy.yaml`):

1. **Actions** → **Destroy GKE Autopilot** → **Run workflow**
2. Enter the same **project_id**, **region**, and **cluster_name** (and optional settings) used when the cluster was created.
3. Check **confirm_destroy** to allow the run.
4. Run the workflow.

Destroy only works if Terraform state for that cluster is available (e.g. use a remote backend and the same backend config for deploy and destroy). If the cluster was created with **deletion protection** enabled, run a deploy with `deletion_protection = false` first, then run destroy.
