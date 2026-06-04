variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource tagging"
  type        = string
  default     = "terraform-ansible-k8s"
}

variable "instance_type" {
  description = "EC2 instance type for Kubernetes nodes"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
}

variable "public_key_path" {
  description = "Local public key path to import into AWS"
  type        = string
}

variable "private_key_path" {
  description = "Local private key path for Ansible SSH"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Company/VPN public IP CIDR allowed for SSH, API, NodePort"
  type        = string
}

variable "subnet_id" {
  description = "Existing public subnet ID where EC2 instances will be launched"
  type        = string
}