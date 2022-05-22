provider "google" {
  project     = var.project_name
  region      = var.region
  zone        = var.zone
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = "gke_platform-one-lab_us-central1-a_platform-one-lab"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    config_context = "gke_platform-one-lab_us-central1-a_platform-one-lab"
  }
}