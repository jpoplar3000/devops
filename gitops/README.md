# GitOps (ArgoCD + Helm)

ArgoCD syncs Helm charts from this repo to the cluster. Chart definitions live in `apps/`.

## Structure

- **argocd/** – ArgoCD installation (Helm values)
- **apps/** – ArgoCD Application manifests (chart name, version, custom values)

## Adding a chart

1. Copy `apps/_example.yaml` to `apps/<chart-name>.yaml`
2. Set `source.repoURL`, `source.chart`, `source.targetRevision` (version)
3. Add custom values under `source.helm.values` or `valuesObject`
4. Commit and push; ArgoCD syncs automatically (if sync policy is automated)

## Prerequisites

- ArgoCD installed in the cluster (see `docs/GITOPS_PLAN.md`)
- Cluster kubeconfig configured (`gcloud container clusters get-credentials ...`)
