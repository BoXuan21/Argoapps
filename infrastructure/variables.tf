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

variable "vm_machine_type" {
  description = "Machine type for the KIND VM"
  type        = string
  default     = "e2-medium"
}

variable "vm_disk_size" {
  description = "Boot disk size for the KIND VM in GB"
  type        = number
  default     = 20
}

variable "vm_image" {
  description = "Boot disk image for the KIND VM"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "subnet_cidr" {
  description = "CIDR range for the KIND subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vm_preemptible" {
  description = "Whether to make the VM preemptible for cost saving"
  type        = bool
  default     = true
}
