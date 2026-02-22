# Terraform GCS Backend Setup

State and lock files are stored in a Google Cloud Storage bucket. The GCS backend uses the bucket for both state and locking (no separate lock service).

## 1. Create the bucket

Use a dedicated project or an existing one. The bucket can be in a different project than the GKE clusters you create.

```bash
# Set your bucket project and name
export BUCKET_PROJECT_ID="your-terraform-state-project"
export BUCKET_NAME="your-terraform-state-bucket"   # must be globally unique

# Create the bucket
gcloud storage buckets create "gs://${BUCKET_NAME}" \
  --project="${BUCKET_PROJECT_ID}" \
  --location=US

# Enable versioning (recommended: recover from bad state updates; helps with locking)
gcloud storage buckets update "gs://${BUCKET_NAME}" \
  --versioning
```

## 2. Grant the CI identity access to the bucket

Your GitHub Actions identity (WIF service account or the one from `GOOGLE_CREDENTIALS`) needs read/write to the bucket.

**If using Workload Identity Federation** (service account in same project as bucket):

```bash
gcloud storage buckets add-iam-policy-binding "gs://${BUCKET_NAME}" \
  --member="serviceAccount:github-actions-sa@${BUCKET_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```

**If the bucket is in a different project** than the WIF/SA project, use the SA email for the project where the SA lives:

```bash
gcloud storage buckets add-iam-policy-binding "gs://${BUCKET_NAME}" \
  --member="serviceAccount:YOUR_SA_EMAIL" \
  --role="roles/storage.objectAdmin"
```

For local runs, your user or Application Default Credentials need the same access (e.g. `roles/storage.objectAdmin` on the bucket).

## 3. Configure Terraform to use the backend

**Local runs:** copy `terraform/backend.config.example` to `terraform/backend.config`, set `bucket` and `prefix` (e.g. `gke-autopilot/my-project-id/my-cluster-name`), then:

```bash
cd terraform
terraform init -backend-config=backend.config
```

Use a different `prefix` per cluster so each cluster has its own state file. Alternatively pass config on the command line:

```bash
terraform init \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="prefix=gke-autopilot/my-project-id/my-cluster-name"
```

**GitHub Actions:** set a repository variable so the workflows can pass backend config:

| Variable          | Example / description |
|------------------|------------------------|
| `TF_STATE_BUCKET` | Your bucket name (e.g. `my-org-terraform-state`). Required for deploy/destroy workflows. |

Workflows use prefix `gke-autopilot/{project_id}/{cluster_name}` so each cluster has its own state file and deploy/destroy use the same state for that cluster.

## 4. "Gaia id not found" / 404 when using the backend

If Terraform init fails with something like `Gaia id not found for email ...@989320585748.iam.gserviceaccount.com`:

- GCP expects the **project ID** in the service account email (e.g. `excellent-grin-302222`), not the **project number** (e.g. `989320585748`).
- **If using a key (GOOGLE_CREDENTIALS):** Open the JSON key and check `client_email`. It must be `your-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com` (e.g. `github-actions-sa@excellent-grin-302222.iam.gserviceaccount.com`). If it shows the project number, create a new key for the same service account in the GCP console and update the secret.
- **If using WIF:** Ensure the repo variable `WIF_SA` uses the project ID: `github-actions-sa@excellent-grin-302222.iam.gserviceaccount.com`, not the project number.

The workflows set `GOOGLE_CLOUD_PROJECT` and `CLOUDSDK_CORE_PROJECT` to the workflow input `project_id` so the correct project is used for backend and provider calls.

## 5. Locking

The GCS backend uses the bucket for state locking. No extra setup is required. While a run holds the lock, other runs that use the same bucket and prefix will wait or fail. Enable **versioning** on the bucket so you can recover from bad updates and for reliable locking behavior.

## Summary

| Item        | Purpose |
|------------|---------|
| GCS bucket | Holds state objects and lock metadata |
| Versioning | Recommended for recovery and locking |
| prefix     | One per cluster (e.g. `project_id/cluster_name`) so state is isolated |
| IAM        | CI identity and local credentials need `roles/storage.objectAdmin` (or equivalent) on the bucket |
