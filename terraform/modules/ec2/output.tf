output "master_instance_id" {
  description = "Master EC2 instance ID"
  value       = aws_instance.master.id
}

output "worker_instance_id" {
  description = "Worker EC2 instance ID"
  value       = aws_instance.worker.id
}

output "master_public_ip" {
  description = "Master public IP"
  value       = aws_instance.master.public_ip
}

output "master_private_ip" {
  description = "Master private IP"
  value       = aws_instance.master.private_ip
}

output "worker_public_ip" {
  description = "Worker public IP"
  value       = aws_instance.worker.public_ip
}

output "worker_private_ip" {
  description = "Worker private IP"
  value       = aws_instance.worker.private_ip
}