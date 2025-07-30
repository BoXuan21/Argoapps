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

  metadata_startup_script = file("${path.module}/startup-script.sh")

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
