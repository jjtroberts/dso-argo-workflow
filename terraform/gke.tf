# GKE

## Node IAM service account
resource "google_service_account" "gke_node_sa" {
  account_id   = "kubernetes-engine-node-sa"
  display_name = "GKE Node Service Account"
  description  = "GKE node service account granted all scopes, then restricted by IAM policy"
}

resource "google_service_account" "gcs_service_account" {
  account_id   = "gcs-sa"
  display_name = "Google Cloud Storage Service Account"
  description  = "Grants gsutil pods access to cloud storage by bucket policy"
}

resource "google_storage_bucket_iam_member" "argo" {
  bucket = "rackner-argo"
  role = "roles/storage.admin"
  member = "serviceAccount:gcs-sa@platform-one-lab.iam.gserviceaccount.com"
}

resource "google_service_account_key" "gcs_service_account_key" {
  service_account_id = google_service_account.gcs_service_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "kubernetes_secret" "gcs_service_account_key_secret" {
  metadata {
    name = "gcs-service-account"
    namespace = "argo"
  }

  data = {
    "service-account.json" = base64decode(google_service_account_key.gcs_service_account_key.private_key)
  }

  type = "opaque"

  depends_on = [
    google_container_cluster.dso_workflow_poc
  ]

}

resource "google_project_iam_member" "gke_node_sa_logs_writer" {
  project = var.project_name
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

resource "google_project_iam_member" "gke_node_sa_metrics_writer" {
  project = var.project_name
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

resource "google_project_iam_member" "gke_node_sa_metadata_writer" {
  project = var.project_name
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

resource "google_container_cluster" "dso_workflow_poc" {
  name                     = var.project_name
  location                 = "us-central1-a"
  project                  = var.project_name
  initial_node_count       = 1
  remove_default_node_pool = true
  enable_shielded_nodes    = false

  workload_identity_config {
    workload_pool = "${var.project_name}.svc.id.goog"
  }

  release_channel {
    channel = "STABLE"
  }

  vertical_pod_autoscaling {
    enabled = true
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.clus_authorized_networks

      content {
        cidr_block   = cidr_blocks.value.network
        display_name = cidr_blocks.value.name
      }
    }
  }
}

##### Node Pools #####
resource "google_container_node_pool" "pool_01_ssd" {
  name       = "pool-01-ssd"
  location   = "us-central1-a"
  cluster    = google_container_cluster.dso_workflow_poc.name
  node_count = 3
  node_config {
    machine_type = "e2-medium"
    disk_type    = "pd-ssd"
    disk_size_gb = 128
    image_type   = "cos"
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke_node_sa.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      "machine_type" = "e2-medium"
      "pool"  = "pool-01-ssd"
      "image" = "cos"
      "disk_type"    = "pd-ssd"
      "disk_size_gb" = "128"
    }
  }
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
  autoscaling {
    min_node_count = 3
    max_node_count = 10
  }
  management {
    auto_repair = true
    auto_upgrade = true
  }
  upgrade_settings {
    max_surge = 1
    max_unavailable = 0
  }
}