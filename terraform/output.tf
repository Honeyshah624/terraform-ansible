output "ubuntu_ami_id" {
  description = "Latest Ubuntu 22.04 AMI selected by Terraform"
  value       = data.aws_ami.ubuntu_2204.id
}

output "vpc_id" {
  description = "Default VPC ID used"
  value       = data.aws_vpc.default.id
}

output "subnet_id" {
  description = "Subnet ID used for instances"
  value       = var.subnet_id
}

output "security_group_id" {
  description = "Kubernetes security group ID"
  value       = module.security_group.security_group_id
}

output "key_pair_name" {
  description = "AWS key pair name"
  value       = module.keypair.key_name
}

output "master_public_ip" {
  description = "Master node public IP"
  value       = module.ec2.master_public_ip
}

output "master_private_ip" {
  description = "Master node private IP"
  value       = module.ec2.master_private_ip
}

output "worker_public_ip" {
  description = "Worker node public IP"
  value       = module.ec2.worker_public_ip
}

output "worker_private_ip" {
  description = "Worker node private IP"
  value       = module.ec2.worker_private_ip
}

output "inventory_path" {
  description = "Generated Ansible inventory path"
  value       = module.ansible_trigger.inventory_path
}

output "ssh_master_command" {
  description = "SSH command for master node"
  value       = "ssh -i ${var.private_key_path} ubuntu@${module.ec2.master_public_ip}"
}

output "ssh_worker_via_master_command" {
  description = "SSH command for worker node through master"
  value       = "ssh -i ${var.private_key_path} -o ProxyCommand=\"ssh -W %h:%p -i ${var.private_key_path} ubuntu@${module.ec2.master_public_ip}\" ubuntu@${module.ec2.worker_private_ip}"
}