terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}



provider "aws" {
  region = var.aws_region
  profile = var.aws_profile

}

provider "vault" {
  # Use public IP since we're connecting from outside the VPC
  address = "http://${aws_instance.vault.public_ip}:8200"
  # Read the root token from SSM after the instance initialization script stores it
  token   = length(data.external.vault_root.result.value) > 0 ? data.external.vault_root.result.value : var.vault_token
  
  # Skip TLS verification for demo purposes
  skip_tls_verify = true
  
  # Add timeout settings
  max_lease_ttl_seconds = 1200
  max_retries = 3
}

// IAM policy to allow the Vault EC2 instance to put SSM parameters and CloudWatch logs
resource "aws_iam_policy" "vault_ssm_put" {
  name        = "vault-ssm-put-parameter"
  description = "Allow Vault EC2 instance to store root token in SSM Parameter Store and write logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:PutParameter",
          "ssm:GetParameter"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:GetRole",
          "iam:GetUser",
          "sts:GetCallerIdentity"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vault_ssm_put_attach" {
  role       = aws_iam_role.vault.name
  policy_arn = aws_iam_policy.vault_ssm_put.arn
}

# Wait for Vault to be fully ready
resource "null_resource" "wait_for_vault" {
  depends_on = [aws_instance.vault]
  
  provisioner "local-exec" {
    command = "${path.module}/scripts/wait_for_vault_ready.sh ${aws_instance.vault.public_ip} ${var.aws_region}"
  }
  
  triggers = {
    instance_id = aws_instance.vault.id
  }
}

# External data source that safely reads the SSM parameter
data "external" "vault_root" {
  program = ["/bin/bash", "${path.module}/scripts/get_ssm_param.sh", "/vault/root_token", var.aws_region]
  depends_on = [null_resource.wait_for_vault]
}

# Vault configuration - separate from Lambda
resource "null_resource" "configure_vault" {
  depends_on = [data.external.vault_root, aws_lambda_function.database_writer]
  
  provisioner "local-exec" {
    command = "echo 'Vault configuration would go here'"
  }
}

# Data sources for default VPC and subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Random password for RDS
resource "random_password" "rds_master_password" {
  length  = 16
  special = false
}

# RDS MySQL Database
resource "aws_db_instance" "main" {
  identifier              = "vault-demo-db"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp2"
  db_name                 = var.database_name
  username                = var.database_master_username
  password                = random_password.rds_master_password.result
  parameter_group_name    = "default.mysql8.0"
  skip_final_snapshot     = true
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.main.name
  
  tags = {
    Name        = "vault-demo-rds"
    Environment = "demo"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "vault-demo-subnet-group"
  subnet_ids = data.aws_subnets.private.ids
  
  tags = {
    Name = "vault-demo-subnet-group"
  }
}

# Vault EC2 Instance
resource "aws_instance" "vault" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.private.ids[0]
  vpc_security_group_ids      = [aws_security_group.vault.id]
  iam_instance_profile        = aws_iam_instance_profile.vault.name
  key_name                    = aws_key_pair.vault.key_name
  associate_public_ip_address = true
  
  user_data = base64encode(templatefile("${path.module}/scripts/vault_init.sh", {
    vault_version = var.vault_version
    aws_region    = var.aws_region
    vault_log_group = var.vault_log_group_name
  }))

  tags = {
    Name = "vault-server"
  }

  depends_on = [aws_db_instance.main]
}

# The Lambda package is built by the repository-level script at ../lambda/build.sh
# build.sh produces the zip file at ../lambda/lambda_function.zip which we reference
# directly from the Lambda resource below. No archive_file data source is required.

# Null resource to build Lambda package
resource "null_resource" "build_lambda" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/../lambda && chmod +x build.sh && ./build.sh"
  }
}

# Updated Lambda Function Resource
resource "aws_lambda_function" "database_writer" {
  # Use the zip produced by the build script (located at ../lambda/lambda_function.zip)
  filename         = "${path.module}/../lambda/lambda_function.zip"
  function_name    = "vault-database-writer"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30
  memory_size     = 128
  
  environment {
    variables = {
      VAULT_ADDR      = "http://${aws_instance.vault.public_ip}:8200"
      RDS_ENDPOINT    = aws_db_instance.main.address
      DATABASE_NAME   = var.database_name
    }
  }

  vpc_config {
    subnet_ids         = data.aws_subnets.private.ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_instance.vault,
    aws_db_instance.main,
    null_resource.build_lambda
  ]
}

# Lambda Permission for API Gateway (if you want to trigger via HTTP)
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.database_writer.function_name
  principal     = "apigateway.amazonaws.com"
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.database_writer.function_name}"
  retention_in_days = 7
}

# IAM Roles and Policies
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-vault-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_vault_auth" {
  name = "LambdaVaultAuthPolicy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "vault" {
  name = "vault-instance-profile"
  role = aws_iam_role.vault.name
}

resource "aws_iam_role" "vault" {
  name = "vault-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Security Groups
resource "aws_security_group" "vault" {
  name        = "vault-sg"
  description = "Security group for Vault server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from anywhere for demo
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vault-sg"
  }
}

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for RDS database"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.vault.id, aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

resource "aws_security_group" "lambda" {
  name        = "lambda-sg"
  description = "Security group for Lambda function"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lambda-sg"
  }
}

# SSH Key for Vault instance
resource "aws_key_pair" "vault" {
  key_name   = "vault-key-${random_id.suffix.hex}"
  # If a public key path is provided (and exists in the config), use it;
  # otherwise use the generated TLS key's public key.
  public_key = var.public_key_path != "" ? file(var.public_key_path) : tls_private_key.vault_key.public_key_openssh
}

resource "random_id" "suffix" {
  byte_length = 4
}

# Generate an SSH key pair when a public key file isn't supplied
resource "tls_private_key" "vault_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Attach the AWS managed basic execution policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}