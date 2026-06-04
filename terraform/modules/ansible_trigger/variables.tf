variable "region" {
  description = "AWS region"
  type        = string
}

variable "master_instance_id" {
  description = "Master instance ID"
  type        = string
}

variable "worker_instance_id" {
  description = "Worker instance ID"
  type        = string
}

variable "master_public_ip" {
  description = "Master public IP"
  type        = string
}

variable "worker_private_ip" {
  description = "Worker private IP"
  type        = string
}

variable "private_key_path" {
  description = "Local private key path"
  type        = string
}

variable "ansible_dir" {
  description = "Ansible directory path"
  type        = string
}

variable "inventory_template_path" {
  description = "Ansible inventory template path"
  type        = string
}

variable "inventory_output_path" {
  description = "Generated inventory output path"
  type        = string
}