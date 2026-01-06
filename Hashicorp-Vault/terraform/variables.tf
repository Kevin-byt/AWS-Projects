variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "aws_profile" {
  type    = string
  default = "serverless-admin"
}

variable "vault_version" {
  description = "Vault version to install"
  type        = string
  default     = "1.15.0"
}

variable "vault_token" {
  description = "Vault root token (for initial setup)"
  type        = string
  default     = "root"
  sensitive   = true
}

variable "database_name" {
  description = "RDS database name"
  type        = string
  default     = "vaultdemo"
}

variable "database_master_username" {
  description = "RDS master username"
  type        = string
  default     = "vaultadmin"
}

variable "public_key_path" {
  description = "Optional path to an existing public key file to use for EC2 key pair (relative to this config). If empty, a key will be generated."
  type    = string
  default = ""
}

variable "vault_log_group_name" {
  description = "CloudWatch Log Group name for Vault logs"
  type        = string
  default     = "/dynamic-credentials/vault"
}

variable "vpc_flow_log_group_name" {
  description = "CloudWatch Log Group name for VPC Flow Logs"
  type        = string
  default     = "/dynamic-credentials/vpc-flow-logs"
}

variable "vault_use_public" {
  description = "When true, use the Vault instance public IP for the Vault provider address (useful for two-phase apply/testing)."
  type        = bool
  default     = false
}

variable "my_ip_cidr" {
  description = "Your workstation IP in CIDR form to temporarily allow access to Vault (e.g. 1.2.3.4/32)."
  type        = string
  default     = ""
}