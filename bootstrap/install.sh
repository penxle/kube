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

echo "Installing ArgoCD (with CRDs)..."
# NOTE: ArgoCD Application manages ArgoCD with crds.install=false.
# CRDs are only applied here (initial install or manual upgrade).
helm upgrade --install argocd argocd/argo-cd \
  --version 9.4.4 \
  --namespace argocd \
  --create-namespace \
  --values "$SCRIPT_DIR/argocd/values.yaml"

echo "Migrating ArgoCD CRDs to SSA ownership..."
# ArgoCD manages itself with ServerSideApply. Kubernetes auto-migrates CSA→SSA
# ownership when SSA is first applied, but this migration fails with resourceVersion=0.
# Removing the last-applied-configuration annotation prevents the migration from
# being triggered, letting ArgoCD take fresh SSA ownership on first sync.
for crd in appprojects.argoproj.io applications.argoproj.io applicationsets.argoproj.io; do
  kubectl annotate crd "$crd" kubectl.kubernetes.io/last-applied-configuration-
done

echo "Applying root Application..."
kubectl apply -f "$SCRIPT_DIR/../root.yaml"

echo "Done! ArgoCD will now manage the rest."
