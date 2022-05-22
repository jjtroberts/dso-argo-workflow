resource "google_storage_bucket" "rackner_argo" {
  name          = "rackner-argo"
  location      = "US"
  force_destroy = true
  storage_class = "STANDARD"

  lifecycle_rule {
    condition {
      age = 3
    }
    action {
      type = "Delete"
    }
  }
}

resource "kubernetes_namespace" "argo" {
  metadata {
    annotations = {
      name = "argo"
    }

    labels = {
      managed-by-terraform = "True"
    }

    name = "argo"
  }
}

resource "helm_release" "argo_workflows" {
  name       = "argo-workflows"
  namespace  = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-workflows"
  version    = "0.15.3"

  values = [
    file("${path.module}/values.yaml")
  ]
}