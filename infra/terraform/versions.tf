terraform {
  required_version = ">= 1.13.0"

  backend "gcs" {
    bucket = "gitops-project-tf-state"
    prefix = "gitops-demo/terraform-state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}
