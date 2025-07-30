# Custom VPC for better security and isolation
resource "google_compute_network" "kind_vpc" {
  name                    = "kind-vpc"
  auto_create_subnetworks = false
  description             = "Custom VPC for KIND testing environment"
}

# Subnet for our VMs
resource "google_compute_subnetwork" "kind_subnet" {
  name          = "kind-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.kind_vpc.id
  region        = var.region
  description   = "Subnet for KIND VMs"

  # Enable private Google access for security
  private_ip_google_access = true
}

#Iam templates
/*
resource "google_project_iam_custom_role" "my-custom-role" {
  role_id     = "myCustomRole"
  title       = "My Custom Role"
  description = "A description"
  permissions = ["iam.roles.list", "iam.roles.create", "iam.roles.delete"]
} */


# Essential: Allow SSH access
resource "google_compute_firewall" "allow_ssh" {
  name    = "kind-allow-ssh"
  network = google_compute_network.kind_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # no need for restrictions
  target_tags   = ["kind-ssh-access"]
  description   = "Allow SSH access to KIND VMs"
}

# Essential: Allow Kubernetes API and applications 
resource "google_compute_firewall" "allow_kubernetes" {
  name    = "kind-allow-kubernetes"
  network = google_compute_network.kind_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["6443", "8080", "80", "443", "30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"] # allow all traffic
  target_tags   = ["kind", "kubernetes"]
  description   = "Allow Kubernetes cluster communication"
}


#Output

output "security_info" {
  description = "Security configuration summary"
  value = {
    vpc_name    = google_compute_network.kind_vpc.name
    subnet_cidr = google_compute_subnetwork.kind_subnet.ip_cidr_range
    firewall_rules = [
      google_compute_firewall.allow_ssh.name,
      google_compute_firewall.allow_kubernetes.name
    ]
    note = "Simplified for KIND cluster. ArgoCD accessible via port forwarding. IAM templates available - uncomment when having proper permissions"
  }
} 