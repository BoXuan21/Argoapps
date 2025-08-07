#!/bin/bash
set -e

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

# Create KIND configuration with NodePort mapping
echo "Creating KIND configuration..."
su - bo -c 'cat > /home/bo/kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 80
    protocol: TCP
  - containerPort: 30443
    hostPort: 443
    protocol: TCP
  - containerPort: 30008
    hostPort: 8080
    protocol: TCP
EOF'

# Check if KIND cluster exists, create if not
if ! su - bo -c "kind get clusters | grep -q test-cluster"; then
  echo "Creating KIND cluster with NodePort host port mapping..."
  su - bo -c "kind create cluster --name test-cluster --config /home/bo/kind-config.yaml"
else
  echo "KIND cluster already exists"
fi

# Install NGINX Ingress Controller (only if not already installed)
if ! su - bo -c "kubectl get namespace ingress-nginx &> /dev/null"; then
  echo "Installing NGINX Ingress Controller..."
  su - bo -c "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml"
  
  # Wait for NGINX Ingress Controller to be ready
  echo "Waiting for NGINX Ingress Controller to be ready..."
  su - bo -c "kubectl wait --for=condition=available --timeout=300s deployment/ingress-nginx-controller -n ingress-nginx"
else
  echo "NGINX Ingress Controller already installed"
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


# Configure ArgoCD for insecure mode (required for ingress) - EARLY
echo "Configuring ArgoCD for insecure mode (early configuration)..."
su - bo -c "kubectl create configmap argocd-cmd-params-cm -n argocd --from-literal=server.insecure=true --dry-run=client -o yaml | kubectl apply -f -"

# Configure NGINX Ingress Controller for NodePort access with correct ports FIRST
echo "Configuring NGINX Ingress Controller for NodePort access..."
su - bo -c "kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{\"spec\":{\"type\":\"NodePort\",\"ports\":[{\"name\":\"http\",\"port\":80,\"targetPort\":80,\"nodePort\":30080},{\"name\":\"https\",\"port\":443,\"targetPort\":443,\"nodePort\":30443}]}}'"
echo "NGINX Ingress Controller configured for host port access"

# Wait for NGINX service to be updated
echo "Waiting for NGINX service to be updated..."
sleep 10

# Function to wait for deployment to be ready
wait_for_deployment() {
  local namespace=$1
  local deployment=$2
  local timeout=${3:-300}
  
  su - bo -c "kubectl wait --for=condition=available --timeout=${timeout}s deployment/$deployment -n $namespace" || {
    return 1
  }
  return 0
}

# Function to retry command with backoff
retry_command() {
  local max_attempts=$1
  shift
  local cmd="$@"
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    if eval "$cmd"; then
      return 0
    else
      if [ $attempt -lt $max_attempts ]; then
        local wait_time=$((attempt * 10))
        sleep $wait_time
      fi
      attempt=$((attempt + 1))
    fi
  done
  
  return 1
}

# Get the external IP address dynamically
EXTERNAL_IP=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H "Metadata-Flavor: Google")

# Ensure we have the external IP
if [ -z "\${EXTERNAL_IP}" ]; then
  exit 1
fi

# Wait extra time for ArgoCD to be fully ready
wait_for_deployment argocd argocd-server 300

# Ensure ArgoCD server is configured for insecure mode BEFORE creating ingress
retry_command 3 'su - bo -c "kubectl create configmap argocd-cmd-params-cm -n argocd --from-literal=server.insecure=true --dry-run=client -o yaml | kubectl apply -f -"'

# Restart ArgoCD server to apply insecure mode FIRST
su - bo -c "kubectl rollout restart deployment argocd-server -n argocd"
wait_for_deployment argocd argocd-server 300

# Wait additional time for server to fully initialize with new config
sleep 30

# Delete existing ingress if it exists
su - bo -c "kubectl delete ingress argocd-ingress -n argocd --ignore-not-found=true"

# Wait a moment for cleanup
sleep 5

# Create ingress configuration with retry logic
retry_command 3 'su - bo -c "kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: \"HTTP\"
    nginx.ingress.kubernetes.io/ssl-redirect: \"false\"
    nginx.ingress.kubernetes.io/force-ssl-redirect: \"false\"
    nginx.ingress.kubernetes.io/server-snippet: |
      grpc_read_timeout 300;
      grpc_send_timeout 300;
      client_body_timeout 60;
      client_header_timeout 60;
      client_max_body_size 1m;
spec:
  ingressClassName: nginx
  rules:
  - host: argocd.'\${EXTERNAL_IP}'.nip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
EOF"'

# Verify ingress was created with retry
retry_command 5 'su - bo -c "kubectl get ingress argocd-ingress -n argocd &> /dev/null"'

# Patch ArgoCD server service to ensure correct port mapping
retry_command 3 'su - bo -c "kubectl patch svc argocd-server -n argocd -p '\''{\"spec\":{\"type\":\"ClusterIP\",\"ports\":[{\"name\":\"server\",\"port\":80,\"protocol\":\"TCP\",\"targetPort\":8080}]}}'\'"'

# ArgoCD server was already restarted above, so just wait for it to stabilize
sleep 15

# Wait for ingress to be ready
sleep 30

# Test connectivity with more robust checking
ARGOCD_URL="http://argocd.\${EXTERNAL_IP}.nip.io"
CONNECTIVITY_SUCCESS=false

for i in {1..10}; do
  # Test HTTP response code
  HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" "\$ARGOCD_URL" 2>/dev/null || echo "000")
  
  if [ "\$HTTP_CODE" = "200" ]; then
    # Also verify we get ArgoCD content
    if curl -s "\$ARGOCD_URL" | grep -q "Argo CD"; then
      CONNECTIVITY_SUCCESS=true
      break
    fi
  elif [ "\$HTTP_CODE" = "307" ] || [ "\$HTTP_CODE" = "301" ] || [ "\$HTTP_CODE" = "302" ]; then
    # If we get a redirect, try to fix it by restarting argocd server once more
    if [ \$i -eq 3 ]; then
      su - bo -c "kubectl rollout restart deployment argocd-server -n argocd"
      wait_for_deployment argocd argocd-server 180
      sleep 20
    fi
  fi
  
  if [ \$i -lt 10 ]; then
    sleep 15
  fi
done

# Get ArgoCD admin password
ARGOCD_PASSWORD=\$(su - bo -c "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d" 2>/dev/null || echo "Password not available yet")

# Deploy root ArgoCD application (only if not already deployed)
if ! su - bo -c "kubectl get application argo-apps -n argocd &> /dev/null"; then
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
fi