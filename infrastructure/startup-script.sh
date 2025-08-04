#!/bin/bash
set -e

echo "Starting idempotent setup script..."

# Update package list
apt-get update

# Install essential packages (only if not already installed)
if ! command -v git &> /dev/null || ! command -v curl &> /dev/null || ! command -v wget &> /dev/null; then
  echo "Installing essential packages..."
  apt-get install -y git curl wget
else
  echo "Essential packages already installed"
fi

# Install Helm (only if not already installed)
if ! command -v helm &> /dev/null; then
  echo "Installing Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo "Helm already installed"
fi

# Install ArgoCD CLI (only if not already installed)
if ! command -v argocd &> /dev/null; then
  echo "Installing ArgoCD CLI..."
  curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
  install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
  rm -f argocd-linux-amd64
else
  echo "ArgoCD CLI already installed"
fi

# Install Docker (only if not already installed)
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  apt-get install -y docker.io
  systemctl start docker
  systemctl enable docker
  chmod 666 /var/run/docker.sock
else
  echo "Docker already installed"
  # Ensure Docker is running
  systemctl start docker || true
  systemctl enable docker || true
  chmod 666 /var/run/docker.sock
fi

# Install Ansible (only if not already installed)
if ! command -v ansible &> /dev/null; then
  echo "Installing Ansible..."
  apt-get install -y software-properties-common
  add-apt-repository --yes --update ppa:ansible/ansible
  apt-get install -y ansible
else
  echo "Ansible already installed"
fi

# Install Salt-SSH (only if not already installed)
if ! command -v salt-ssh &> /dev/null; then
  echo "Installing Salt-SSH..."
  apt-get install -y salt-ssh
else
  echo "Salt-SSH already installed"
fi

# Install kubectl (only if not already installed)
if ! command -v kubectl &> /dev/null; then
  echo "Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm -f kubectl
else
  echo "kubectl already installed"
fi

# Install KIND (only if not already installed)
if ! command -v kind &> /dev/null; then
  echo "Installing KIND..."
  [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
  chmod +x ./kind
  mv ./kind /usr/local/bin/kind
else
  echo "KIND already installed"
fi

# Wait for Docker to be ready
echo "Waiting for Docker to be ready..."
sleep 10
while ! docker info &> /dev/null; do
  echo "Waiting for Docker daemon..."
  sleep 5
done

# Check if KIND cluster exists, create if not
if ! su - bo -c "kind get clusters | grep -q test-cluster"; then
  echo "Creating KIND cluster..."
  su - bo -c "kind create cluster --name test-cluster"
else
  echo "KIND cluster already exists"
fi

# Check if ArgoCD namespace exists, create and install if not
if ! su - bo -c "kubectl get namespace argocd &> /dev/null"; then
  echo "Installing ArgoCD..."
  su - bo -c "kubectl create namespace argocd"
  su - bo -c "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
  
  # Wait for ArgoCD to be ready
  echo "Waiting for ArgoCD to be ready..."
  su - bo -c "kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd"
else
  echo "ArgoCD already installed"
fi

# Deploy root ArgoCD application (only if not already deployed)
if ! su - bo -c "kubectl get application argo-apps -n argocd &> /dev/null"; then
  echo "Deploying ArgoCD root application..."
  # Wait a bit more for ArgoCD to be fully ready
  sleep 30
  su - bo -c 'kubectl apply -f - <<EOF
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
EOF'
else
  echo "ArgoCD root application already deployed"
fi
