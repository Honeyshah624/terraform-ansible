variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security group"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Allowed company/VPN public IP CIDR"
  type        = string
}