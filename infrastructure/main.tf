variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = "rd-sre-assessment-center"
}

variable "region" {
  description = "Google Cloud Region"
  type        = string
  default     = "europe-west4"
}

variable "zone" {
  description = "Google Cloud Zone"
  type        = string
  default     = "europe-west4-a"
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_service_account" "kind_test_sa" {
  account_id   = "kind-test-sa"
  display_name = "KIND Test Service Account"
  description  = "Service account for KIND VM testing"
}

resource "google_compute_instance" "kind_vm" {
  name         = "kind-vm"
  machine_type = "e2-medium"
  zone         = var.zone
  
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.kind_vpc.id
    subnetwork = google_compute_subnetwork.kind_subnet.id

    access_config {
    }
  }

  metadata_startup_script = <<-EOT
   # installing essential packages
    apt-get update

    # install git
    apt-get install -y git curl wget

    # install helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # install argoCD CLI
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64

    # Install Docker
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker

    # Fix Docker permission issues
    chmod 666 /var/run/docker.sock

    # install ansible
    apt-get install -y software-properties-common
    add-apt-repository --yes --update ppa:ansible/ansible
    apt-get install -y ansible

    # install salt-ssh
    apt-get install -y salt-ssh

      # Create shared directories
    mkdir -p /opt/kind
    mkdir -p /shared/kubeconfig
    mkdir -p /shared/kind-data
    chmod 755 /opt/kind /shared /shared/kubeconfig /shared/kind-data
    
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    
    # Install KIND
    [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    mv ./kind /usr/local/bin/kind

    # Wait for Docker to be ready
    sleep 30
    
     # Reset KIND cluster (delete if exists, then create fresh)
    su - bo -c "kind delete cluster --name test-cluster || true"
    su - bo -c "kind create cluster --name test-cluster"

    # Install ArgoCD
    su - bo -c "kubectl create namespace argocd"
    su - bo -c "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
    
  EOT

  service_account {
    email  = google_service_account.kind_test_sa.email
    scopes = ["cloud-platform"]
  }

  # Make VM preemptible for cost saving
  scheduling {
    preemptible = true
    automatic_restart = false
  }

  tags = ["kind", "kubernetes", "kind-ssh-access"]
}
