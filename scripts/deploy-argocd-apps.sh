#!/bin/bash

# ArgoCD Apps Deployment Automation Script
# This script automates the deployment of the root ArgoCD application

set -e

PROJECT_ID="rd-sre-assessment-center"
ZONE="europe-west4-a"
VM_NAME="kind-vm"

echo "🚀 Starting ArgoCD Apps Deployment..."

# Function to run commands on the KIND VM
run_on_vm() {
    gcloud compute ssh $VM_NAME \
        --zone=$ZONE \
        --project=$PROJECT_ID \
        --command="$1"
}

# 1. Check if VM is running
echo "📋 Checking VM status..."
VM_STATUS=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --project=$PROJECT_ID --format="value(status)")

if [ "$VM_STATUS" != "RUNNING" ]; then
    echo "🔄 Starting VM..."
    gcloud compute instances start $VM_NAME --zone=$ZONE --project=$PROJECT_ID
    echo "⏳ Waiting for VM to be ready..."
    sleep 30
fi

# 2. Verify ArgoCD is running
echo "🔍 Checking ArgoCD status..."
run_on_vm "kubectl get pods -n argocd | grep Running | wc -l" || {
    echo "❌ ArgoCD is not running properly"
    exit 1
}

# 3. Deploy root ArgoCD application (idempotent)
echo "📦 Deploying root ArgoCD application..."
run_on_vm "kubectl apply -f - <<'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argo-apps
  namespace: argocd
spec:
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
  project: default
  source:
    repoURL: https://github.com/BoXuan21/Argoapps.git
    targetRevision: HEAD
    path: argo-apps/apps
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF"

# 4. Wait for applications to sync
echo "⏳ Waiting for applications to sync..."
sleep 15

# 5. Check application status
echo "📊 Checking application status..."
run_on_vm "kubectl get applications -n argocd"

# 6. Check todo-app deployment
echo "🔍 Checking todo-app deployment..."
run_on_vm "kubectl get pods -n todo-app" || echo "Todo-app namespace might be syncing..."

echo "✅ ArgoCD Apps deployment completed!"
echo ""
echo "🌐 Access ArgoCD at: https://localhost:8081"
echo "👤 Username: admin"
echo "🔑 Password: $(run_on_vm 'kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d')"
echo ""
echo "🚀 To access ArgoCD, run:"
echo "gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --ssh-flag=\"-L 8081:localhost:8080\" --command=\"kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0\"" 