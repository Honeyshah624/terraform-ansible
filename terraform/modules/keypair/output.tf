output "key_name" {
  description = "Created/imported key pair name"
  value       = aws_key_pair.this.key_name
}