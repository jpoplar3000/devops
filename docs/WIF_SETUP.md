# Workload Identity Federation Setup

Use Workload Identity Federation (WIF) so GitHub Actions can authenticate to GCP without storing a service account JSON key. GitHub issues short-lived OIDC tokens that GCP exchanges for access tokens.

## Prerequisites

- `gcloud` CLI installed and authenticated (`gcloud auth login`)
- A GCP project for the WIF pool (can be a "CI" project or the same project you deploy clusters to)

---

## Step 1: Create the Workload Identity Pool

```bash
# Replace PROJECT_ID with your GCP project ID (e.g. my-org-ci)
export PROJECT_ID="your-project-id"

gcloud iam workload-identity-pools create "github-pool" \
  --location="global" \
  --display-name="GitHub Actions" \
  --project="${PROJECT_ID}"
```

---

## Step 2: Create the OIDC Provider

This configures the pool to trust GitHub's OIDC issuer.

```bash
# Restrict to your repo (recommended). Examples:
# - Your repo only:     assertion.repository == 'owner/repo'
# - Your org's repos:   assertion.repository_owner == 'your-org'
# - Multiple repos:     assertion.repository in ['owner/repo1','owner/repo2']
export REPO_CONDITION="assertion.repository == 'YOUR_GITHUB_OWNER/YOUR_REPO_NAME'"

gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="${REPO_CONDITION}" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --project="${PROJECT_ID}"
```

**Important:** Set `REPO_CONDITION` to limit which repos can use this identity. For a public repo, use your exact repo (e.g. `assertion.repository == 'jpoplar/devops'`).

---

## Step 3: Create a Service Account

```bash
gcloud iam service-accounts create "github-actions-sa" \
  --display-name="GitHub Actions" \
  --project="${PROJECT_ID}"
```

---

## Step 4: Grant the Pool Permission to Impersonate the Service Account

```bash
# Get your GitHub org or username and repo name
export GITHUB_OWNER="your-github-username-or-org"
export GITHUB_REPO="devops"

gcloud iam service-accounts add-iam-policy-binding \
  "github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')/locations/global/workloadIdentityPools/github-pool/attribute.repository/${GITHUB_OWNER}%2F${GITHUB_REPO}"
```

---

## Step 5: Grant the Service Account GKE Permissions

If you deploy clusters **in the same project** as the WIF pool:

```bash
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageConsumer"
```

If you deploy clusters **in other projects**, run the same `add-iam-policy-binding` commands for each target project, replacing `PROJECT_ID` with the target project ID.

---

## Step 6: Add GitHub Repository Variables

In your repo: **Settings → Secrets and variables → Actions → Variables tab**.

| Name | Value |
|------|-------|
| `WIF_PROVIDER` | `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider` |
| `WIF_SA` | `github-actions-sa@PROJECT_ID.iam.gserviceaccount.com` |

**Get PROJECT_NUMBER:**
```bash
gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)'
```

**Example values:**
- `WIF_PROVIDER`: `projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github-provider`
- `WIF_SA`: `github-actions-sa@my-org-ci.iam.gserviceaccount.com`

---

## Step 7: Update Workflows

The Deploy and Destroy workflows are configured to use WIF when `WIF_PROVIDER` and `WIF_SA` are set. No code changes needed—just add the variables above.

Once WIF is working, you can remove the `GOOGLE_CREDENTIALS` secret.

---

## Troubleshooting

| Error | Fix |
|-------|-----|
| `Permission denied` on pool creation | Ensure you have `iam.workloadIdentityPools.create` (e.g. Owner or `roles/iam.securityAdmin`) |
| `Permission denied` when running workflow | Check the SA has `roles/container.admin` and `roles/serviceusage.serviceUsageConsumer` in the target project |
| `attribute.repository` condition not met | Verify `REPO_CONDITION` matches your repo (owner/repo format, lowercase) |
| `principalSet` binding fails | Use the exact attribute path; `attribute.repository` uses `/` for owner/repo |
