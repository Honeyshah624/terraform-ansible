output "inventory_path" {
  description = "Generated Ansible inventory path"
  value       = local_file.inventory.filename
}