#!/bin/bash

echo "🔍 DEBUGGING KIND VM SETUP"
echo "=========================="

# Check 1: Startup script logs
echo "1️⃣ Checking startup script logs..."
gcloud compute ssh kind-vm --zone=europe-west4-a --project=rd-sre-assessment-center --command="sudo journalctl -u google-startup-scripts.service --no-pager -l" | tail -20

echo -e "\n2️⃣ Checking Docker status..."
gcloud compute ssh kind-vm --zone=europe-west4-a --project=rd-sre-assessment-center --command="sudo systemctl status docker --no-pager"

echo -e "\n3️⃣ Checking KIND clusters..."
gcloud compute ssh kind-vm --zone=europe-west4-a --project=rd-sre-assessment-center --command="kind get clusters"

echo -e "\n4️⃣ Checking kubectl contexts..."
gcloud compute ssh kind-vm --zone=europe-west4-a --project=rd-sre-assessment-center --command="kubectl config get-contexts"

echo -e "\n5️⃣ Checking Kubernetes nodes..."
gcloud compute ssh kind-vm --zone=europe-west4-a --project=rd-sre-assessment-center --command="kubectl get nodes"

echo -e "\n6️⃣ Checking ArgoCD namespace..."
gcloud compute ssh kind-vm --zone=europe-west4-a --project=rd-sre-assessment-center --command="kubectl get namespaces | grep argocd"

echo -e "\n7️⃣ Checking ArgoCD pods..."
gcloud compute ssh kind-vm --zone=europe-west4-a --project=rd-sre-assessment-center --command="kubectl get pods -n argocd"

echo -e "\n8️⃣ Checking ArgoCD password file..."
gcloud compute ssh kind-vm --zone=europe-west4-a --project=rd-sre-assessment-center --command="ls -la /home/ubuntu/argocd-password.txt && cat /home/ubuntu/argocd-password.txt"

echo -e "\n9️⃣ Checking ArgoCD service..."
gcloud compute ssh kind-vm --zone=europe-west4-a --project=rd-sre-assessment-center --command="kubectl get svc -n argocd argocd-server"

echo -e "\n🔟 Testing ArgoCD secret directly..."
gcloud compute ssh kind-vm --zone=europe-west4-a --project=rd-sre-assessment-center --command="kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo"

echo -e "\n✅ Debugging complete!"
echo "==========================" 