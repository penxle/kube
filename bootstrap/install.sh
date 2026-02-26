#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Adding helm repositories..."
helm repo add argocd https://argoproj.github.io/argo-helm
helm repo add cilium https://helm.cilium.io/
helm repo update

echo "Installing Cilium..."
helm upgrade --install cilium cilium/cilium \
  --version 1.18.2 \
  --namespace kube-system \
  --values "$SCRIPT_DIR/cilium/values.yaml"

echo "Installing ArgoCD..."
helm upgrade --install argocd argocd/argo-cd \
  --version 8.5.9 \
  --namespace argocd \
  --create-namespace \
  --values "$SCRIPT_DIR/argocd/values.yaml"

echo "Applying root Application..."
kubectl apply -f "$SCRIPT_DIR/../root.yaml"

echo "Done! ArgoCD will now manage the rest."
