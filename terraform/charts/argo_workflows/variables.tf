variable "project_name" {
  type = string
  description = "Name of project to deploy cluster to"
  default = "platform-one-lab"
}

variable "region" {
  type = string
  description = "region to deploy cluster to"
  default = "us-central1"
}

variable "zone" {
  type = string
  description = "Zone to deploy cluster to"
  default = "us-central1-a"
}