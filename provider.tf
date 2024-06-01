terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.29.1"
    }
  }
}

provider "google" {
  # Configuration options
  project = var.project
  region = var.region
  credentials = var.credentials
  zone = var.zone
}