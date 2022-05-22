terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.21.0"
    }
  }

  backend "gcs" {
    bucket = "rackner-terraform-state"
    prefix = "terraform/state"
  }
}