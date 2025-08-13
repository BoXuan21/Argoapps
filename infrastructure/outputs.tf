# VM-related outputs
output "kind_vm_static_ip" {
  description = "Static IP address of the KIND VM"
  value       = google_compute_address.kind_static_ip.address
}

output "kind_vm_external_ip" {
  description = "External IP address of the KIND VM"
  value       = google_compute_instance.kind_vm.network_interface[0].access_config[0].nat_ip
}

# Network-related outputs
output "security_info" {
  description = "Security configuration summary"
  value = {
    vpc_name    = google_compute_network.kind_vpc.name
    subnet_cidr = google_compute_subnetwork.kind_subnet.ip_cidr_range
    firewall_rules = [
      google_compute_firewall.allow_ssh.name,
      google_compute_firewall.allow_kubernetes.name,
      google_compute_firewall.allow_http_https.name,
      google_compute_firewall.allow_nodeports.name
    ]
    note = "ArgoCD accessible via nip.io at https://argocd.[EXTERNAL_IP].nip.io. All necessary ports (80, 443, 30000-32767) are open"
  }
}

output "vpc_info" {
  description = "VPC network information"
  value = {
    vpc_name        = google_compute_network.kind_vpc.name
    vpc_id          = google_compute_network.kind_vpc.id
    subnet_name     = google_compute_subnetwork.kind_subnet.name
    subnet_id       = google_compute_subnetwork.kind_subnet.id
    subnet_cidr     = google_compute_subnetwork.kind_subnet.ip_cidr_range
  }
}
