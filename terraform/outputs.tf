output "kubernetes_cluster_name" {
  value       = google_container_cluster.dso_workflow_poc.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.dso_workflow_poc.endpoint
  description = "GKE Cluster Host"
}