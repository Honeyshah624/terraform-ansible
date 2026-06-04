output "master_instance_id" {
  value = module.ec2.master_instance_id
}

output "worker_instance_id" {
  value = module.ec2.worker_instance_id
}

output "master_public_ip" {
  value = module.ec2.master_public_ip
}

output "worker_public_ip" {
  value = module.ec2.worker_public_ip
}

output "master_private_ip" {
  value = module.ec2.master_private_ip
}

output "worker_private_ip" {
  value = module.ec2.worker_private_ip
}

output "security_group_id" {
  value = module.security_group.security_group_id
}

output "key_pair_name" {
  value = module.keypair.key_name
}