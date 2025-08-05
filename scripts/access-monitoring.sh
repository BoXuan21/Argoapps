#!/bin/bash

# Access Script for Prometheus and Grafana
# This script helps you easily access the monitoring UIs

PROJECT_ID="rd-sre-assessment-center"
ZONE="europe-west4-a"
VM_NAME="kind-vm"

echo "🔍 Monitoring Access Helper"
echo "=========================="

# Function to run commands on the KIND VM
run_on_vm() {
    gcloud compute ssh $VM_NAME \
        --zone=$ZONE \
        --project=$PROJECT_ID \
        --command="$1"
}

# Check if monitoring namespace exists
echo "📋 Checking monitoring setup..."
if run_on_vm "kubectl get namespace monitoring &>/dev/null"; then
    echo "✅ Monitoring namespace exists"
else
    echo "❌ Monitoring namespace not found. Please wait for deployment."
    exit 1
fi

# Get pod status
echo ""
echo "📊 Monitoring Pods Status:"
run_on_vm "kubectl get pods -n monitoring"

echo ""
echo "🌐 Access URLs:"
echo "==============="

# Prometheus
echo "🔥 Prometheus:"
echo "   Local: http://localhost:9090"
echo "   Command: gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --ssh-flag=\"-L 9090:localhost:9090\" --command=\"kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090 --address 0.0.0.0\""

echo ""

# Grafana
echo "📈 Grafana:"
echo "   Local: http://localhost:3000"
echo "   Username: admin"
echo "   Password: admin123"
echo "   Command: gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --ssh-flag=\"-L 3000:localhost:3000\" --command=\"kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80 --address 0.0.0.0\""

echo ""

# AlertManager
echo "🚨 AlertManager:"
echo "   Local: http://localhost:9093"
echo "   Command: gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --ssh-flag=\"-L 9093:localhost:9093\" --command=\"kubectl port-forward svc/prometheus-kube-prometheus-alertmanager -n monitoring 9093:9093 --address 0.0.0.0\""

echo ""
echo "💡 Quick Start Commands:"
echo "========================"
echo "# Access Grafana:"
echo "./scripts/access-monitoring.sh grafana"
echo ""
echo "# Access Prometheus:"
echo "./scripts/access-monitoring.sh prometheus"
echo ""
echo "# Access AlertManager:"
echo "./scripts/access-monitoring.sh alertmanager"

# Handle specific service access
if [ "$1" = "grafana" ]; then
    echo ""
    echo "🚀 Starting Grafana port forward..."
    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --ssh-flag="-L 3000:localhost:3000" --command="kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80 --address 0.0.0.0"
elif [ "$1" = "prometheus" ]; then
    echo ""
    echo "🚀 Starting Prometheus port forward..."
    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --ssh-flag="-L 9090:localhost:9090" --command="kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090 --address 0.0.0.0"
elif [ "$1" = "alertmanager" ]; then
    echo ""
    echo "🚀 Starting AlertManager port forward..."
    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID --ssh-flag="-L 9093:localhost:9093" --command="kubectl port-forward svc/prometheus-kube-prometheus-alertmanager -n monitoring 9093:9093 --address 0.0.0.0"
fi 