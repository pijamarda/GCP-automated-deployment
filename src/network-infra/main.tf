

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.19.0"
    }
  }
}

provider "google" {
  # Configuration options
}

resource "google_compute_network" "vpc_network" {
  project                 = "vindrogames-backend-develop"
  name                    = "vpc-zeneke"
  auto_create_subnetworks = true
}