terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

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

variable "bucket_name" {
  description = "Name of the GCS bucket for Terraform state"
  type        = string
  default     = "rd-sre-assessment-terraform-state"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Create the GCS bucket for Terraform state
resource "google_storage_bucket" "terraform_state" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = false
  
  # Uniform bucket-level access
  uniform_bucket_level_access = true
  
  # Versioning for state history
  versioning {
    enabled = true
  }
  
  # Lifecycle management
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
  
  # Encryption
  encryption {
    default_kms_key_name = null
  }
  
  # Labels for organization
  labels = {
    purpose     = "terraform-state"
    environment = "assessment"
    managed_by  = "terraform"
  }
}

# IAM binding for the bucket (optional - for team access)
resource "google_storage_bucket_iam_member" "terraform_state_admin" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "user:bo.yang@rewe-group.at"
}

# Output bucket name for reference
output "bucket_name" {
  description = "Name of the created GCS bucket"
  value       = google_storage_bucket.terraform_state.name
}

output "bucket_url" {
  description = "URL of the created GCS bucket"
  value       = google_storage_bucket.terraform_state.url
} 