output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.address
}

output "vault_private_ip" {
  description = "Vault server private IP"
  value       = aws_instance.vault.private_ip
}

output "vault_public_ip" {
  description = "Vault server public IP"
  value       = aws_instance.vault.public_ip
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.database_writer.function_name
}

output "vault_address" {
  description = "Vault server address"
  value       = "http://${aws_instance.vault.public_ip}:8200"
}

output "vault_init_info" {
  description = "Vault initialization info location"
  value       = "/tmp/vault-init.json on the Vault instance"
  sensitive   = true
}