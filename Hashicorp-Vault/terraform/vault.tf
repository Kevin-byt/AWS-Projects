# Vault resources - simplified version
resource "vault_mount" "database" {
  path = "database"
  type = "database"
}

resource "vault_database_secret_backend_connection" "mysql" {
  backend       = vault_mount.database.path
  name          = "mysql"
  allowed_roles = ["lambda-role"]

  mysql {
    connection_url = "{{username}}:{{password}}@tcp(${aws_db_instance.main.address}:3306)/"
    username       = var.database_master_username
    password       = random_password.rds_master_password.result
    max_open_connections = 10
    max_idle_connections = 5
    max_connection_lifetime = 14400 # 4 hours
  }
}

resource "vault_database_secret_backend_role" "lambda" {
  backend             = vault_mount.database.path
  name                = "lambda-role"
  db_name             = vault_database_secret_backend_connection.mysql.name
  creation_statements = [
    "CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';",
    "GRANT SELECT, INSERT, UPDATE ON ${var.database_name}.* TO '{{name}}'@'%';"
  ]
  revocation_statements = [
    "DROP USER '{{name}}'@'%';"
  ]
  default_ttl = 3600  # 1 hour
  max_ttl     = 86400 # 24 hours
}

resource "vault_auth_backend" "aws" {
  type = "aws"
}

resource "vault_policy" "lambda" {
  name = "lambda-policy"

  policy = <<EOT
path "database/creds/lambda-role" {
  capabilities = ["read"]
}
EOT
}

resource "vault_aws_auth_backend_role" "lambda" {
  backend                   = vault_auth_backend.aws.path
  role                      = "lambda-role"
  auth_type                 = "iam"
  bound_iam_principal_arns  = [aws_iam_role.lambda_exec.arn]
  token_policies            = [vault_policy.lambda.name]
  token_ttl                 = 3600
  token_max_ttl             = 86400
}