# GitOps Plan: ArgoCD + Helm Charts

## Overview

Use [ArgoCD](https://argo-cd.readthedocs.io/) for GitOps: it syncs desired state from Git to the cluster. Helm charts are deployed via ArgoCD Applications, each specifying chart, version, and custom values.

## Architecture

```
┌─────────────────┐     sync      ┌──────────────────┐
│  Git repo       │ ───────────► │  ArgoCD          │
│  (this repo)    │               │  (in cluster)    │
│                 │               │                  │
│  gitops/apps/   │               │  Deploys Helm     │
│  - chart defs   │               │  charts to       │
│  - values       │               │  cluster         │
└─────────────────┘               └──────────────────┘
```

## Components

### 1. ArgoCD (cluster add-on)

- Installed in the cluster after GKE is created
- Options: Terraform `helm_release`, or a bootstrap script/workflow
- Namespace: `argocd`

### 2. Chart definitions (Git as source of truth)

Each chart is an ArgoCD **Application** with:

- **source.repoURL** – Helm repo (e.g. `https://charts.bitnami.com/bitnami`)
- **source.chart** – Chart name
- **source.targetRevision** – Version (e.g. `1.2.3`)
- **source.helm.values** or **valuesObject** – Custom variables

Two patterns:

| Pattern | Pros | Cons |
|--------|------|------|
| **One Application per chart** | Explicit, easy to diff | More files |
| **ApplicationSet + config list** | Single list file, DRY | Slightly more complex |

**Recommended:** Start with one Application manifest per chart in `gitops/apps/`. Add an ApplicationSet later if the list grows.

### 3. Directory structure

```
gitops/
├── argocd/                 # ArgoCD installation
│   └── values.yaml         # Helm values overrides
├── apps/                   # Chart definitions (ArgoCD Applications)
│   ├── ingress-nginx.yaml
│   ├── cert-manager.yaml
│   └── _example.yaml       # Template for new charts
└── README.md
```

### 4. Workflow

1. **Bootstrap:** After cluster is created, install ArgoCD (Terraform or manual).
2. **Add charts:** Create an Application manifest in `gitops/apps/` with chart, version, and values.
3. **Commit & push:** ArgoCD picks up changes and syncs.
4. **Optional:** GitHub Action to apply Application manifests or trigger ArgoCD refresh.

## Example Application (Helm chart)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ingress-nginx
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://kubernetes.github.io/ingress-nginx
    chart: ingress-nginx
    targetRevision: "4.8.0"
    helm:
      values: |
        controller:
          replicaCount: 2
          service:
            type: LoadBalancer
  destination:
    server: https://kubernetes.default.svc
    namespace: ingress-nginx
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Implementation steps

1. [ ] Add Terraform/Helm to install ArgoCD on the cluster (or document manual install)
2. [ ] Create `gitops/` directory structure
3. [ ] Add example Application manifests for 1–2 charts
4. [ ] Document how to add new charts (version, values)
5. [ ] Optional: GitHub Action to install ArgoCD after cluster create, or to apply apps

## References

- [ArgoCD Helm Charts](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/)
- [ApplicationSet](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/) (for list-driven deployments)
