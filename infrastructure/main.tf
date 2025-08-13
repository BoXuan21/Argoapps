# Static IP address for the KIND VM
resource "google_compute_address" "kind_static_ip" {
  name   = "kind-vm-static-ip"
  region = var.region
  description = "Static IP address for KIND VM"
}

resource "google_service_account" "kind_test_sa" {
  account_id   = "kind-test-sa"
  display_name = "KIND Test Service Account"
  description  = "Service account for KIND VM testing"
}

resource "google_compute_instance" "kind_vm" {
  name         = "kind-vm"
  machine_type = var.vm_machine_type
  zone         = var.zone
  
  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = var.vm_disk_size
    }
  }

  network_interface {
    network    = google_compute_network.kind_vpc.id
    subnetwork = google_compute_subnetwork.kind_subnet.id

    access_config {
      nat_ip = google_compute_address.kind_static_ip.address
    }
  }

  metadata_startup_script = file("${path.module}/startup-script.sh")

  service_account {
    email  = google_service_account.kind_test_sa.email
    scopes = ["cloud-platform"]
  }

  # Make VM preemptible for cost saving
  scheduling {
    preemptible = var.vm_preemptible
    automatic_restart = false
  }

  tags = ["kind", "kubernetes", "kind-ssh-access"]
}


