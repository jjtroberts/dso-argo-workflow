# module "chart_flux" {
#   source = "./charts/flux"
# }

# module "chart_stackrox" {
#   source = "./charts/stackrox"
# }

module "chart_argo_workflows" {
  source = "./charts/argo_workflows"
  depends_on = [
    google_container_cluster.dso_workflow_poc
  ]
}