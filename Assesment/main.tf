variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = "rd-sre-assessment-center"
}

variable "region" {
  description = "Google Cloud Region"
  type        = string
  default     = "europe-central2 "
}

variable "zone" {
  description = "Google Cloud Zone"
  type        = string
  default     = "europe-central2-a"
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
  machine_type = "e2-medium" # weils schneller ist
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP / can be accessed through the internet
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Update system
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
    
    # install Google Cloud Operations Agent
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    bash add-google-cloud-ops-agent-repo.sh --also-install

    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    
    # Install KIND
    [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    mv ./kind /usr/local/bin/kind
    
    # Wait for Docker to be ready and create KIND cluster as ubuntu user
    sleep 30
    su - ubuntu -c "kind create cluster --name test-cluster"
    su - ubuntu -c "kubectl cluster-info --context kind-test-cluster"
  EOT

  service_account {
    email  = google_service_account.kind_test_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["kind", "kubernetes"]
}
