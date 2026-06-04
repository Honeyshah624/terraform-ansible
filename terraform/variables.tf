variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
}

variable "public_key_path" {
  description = "Public key path generated in GitHub Actions runner"
  type        = string
}

variable "private_key_path" {
  description = "Private key path generated in GitHub Actions runner"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "allowed_ingress_cidrs" {
  description = "Company CIDR ranges allowed permanently"
  type        = list(string)
}