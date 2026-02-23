#!/usr/bin/env bash
# Install ArgoCD and bootstrap the app-of-apps.
# Run after cluster is created and kubectl is configured.
#
# Usage: ./scripts/install-argocd.sh

set -e

ARGOCD_NAMESPACE=argocd
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Adding ArgoCD Helm repo..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "Creating namespace ${ARGOCD_NAMESPACE}..."
kubectl create namespace "${ARGOCD_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "Installing ArgoCD..."
helm upgrade --install argocd argo/argo-cd \
  -n "${ARGOCD_NAMESPACE}" \
  -f "${REPO_ROOT}/gitops/argocd/values.yaml" \
  --wait

echo "Applying app-of-apps (points to gitops/apps/)..."
kubectl apply -f "${REPO_ROOT}/gitops/app-of-apps.yaml"

echo "Done. Get ArgoCD admin password:"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "Port-forward to access UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
