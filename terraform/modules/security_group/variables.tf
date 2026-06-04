variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "allowed_ingress_cidrs" {
  description = "Company CIDR ranges"
  type        = list(string)
}