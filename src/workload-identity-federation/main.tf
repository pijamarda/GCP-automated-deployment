terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.19.0"
    }
  }

  backend "gcs" {
    bucket  = "vindrogames-tfstate"
    prefix  = "terraform/identity-federation"
  }

}

provider "google" {
  # Configuration options
  project = "vindrogames-backend-develop"
}

resource "google_iam_workload_identity_pool" "github_federation" {
  workload_identity_pool_id = "github-federation-pool"
  display_name = "Github Federation Pool"
}

resource "google_iam_workload_identity_pool_provider" "example" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_federation.workload_identity_pool_id
  workload_identity_pool_provider_id = "actions-provider"
  display_name                       = "GCP Actions Provider"
  description                        = "GitHub Actions identity pool provider for automated test"
  disabled                           = false
  attribute_condition = <<EOT
    assertion.repository_owner_id == "2150460" &&
    attribute.repository_id == "1158054706" &&
    assertion.ref == "refs/heads/main" &&
    assertion.ref_type == "branch" 
EOT
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "github_actions"{
  account_id   = "service-account-github-actions"
  display_name = "Github Actions"
}

data "google_project" "project" {}

resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_federation.workload_identity_pool_id}/*"
  # More specific alternative: filter by repository
  # member           = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_federation.workload_identity_pool_id}/attribute.repository/pijamarda/GCP-automated-deployment"
}

resource "google_project_iam_member" "github_actions_editor" {
  project = data.google_project.project.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}
