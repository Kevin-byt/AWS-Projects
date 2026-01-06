# Dynamic Database Credentials with HashiCorp Vault

> **The New Era of Secrets Management**: Just-in-time credential generation for serverless applications

## Overview

This project demonstrates **dynamic database credential management** using HashiCorp Vault in AWS serverless architecture. Instead of storing static database passwords, credentials are generated on-demand with automatic expiration and cleanup.

## Architecture

```
Lambda Function → Vault (EC2) → RDS MySQL
      ↓              ↓           ↓
  IAM Auth    Dynamic Creds  Temp User
```

### Components:
- **EC2 Instance**: Hosts HashiCorp Vault server
- **Lambda Function**: Demonstrates dynamic credential usage
- **RDS MySQL**: Target database with temporary users
- **SSM Parameter Store**: Stores Vault root token for Terraform

## Key Features

- ✅ **Zero hardcoded credentials** in application code
- ✅ **1-hour credential lifespan** with automatic cleanup
- ✅ **IAM-based authentication** (no API keys to manage)
- ✅ **Automatic database user creation/deletion**
- ✅ **Full audit trail** of credential usage
- ✅ **Infrastructure as Code** with Terraform

## How It Works

1. **Lambda authenticates** with Vault using AWS IAM role
2. **Vault generates** temporary MySQL credentials (username/password)
3. **Lambda connects** to RDS using dynamic credentials
4. **Credentials expire** automatically after 1 hour
5. **Database user is deleted** when credentials expire

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- jq (for JSON parsing)

## Quick Start

### 1. Clone and Navigate
```bash
git clone <repository>
cd Dynamic-Credentials-Hashicorp-Vault/terraform
```

### 2. Configure Variables
```bash
# Edit variables.tf or create terraform.tfvars
aws_region = "eu-west-1"
aws_profile = "your-profile"
```

### 3. Deploy Infrastructure
```bash
terraform init
terraform apply
```

### 4. Test Dynamic Credentials
```bash
# Test Vault credential generation
curl -s -H "X-Vault-Token: $(aws ssm get-parameter --name /vault/root_token --with-decryption --query Parameter.Value --output text)" \
  "http://$(terraform output -raw vault_public_ip):8200/v1/database/creds/lambda-role" | jq .

# Invoke Lambda function
aws lambda invoke --function-name vault-database-writer response.json
cat response.json | jq .
```

## Project Structure

```
├── terraform/
│   ├── main.tf              # Core AWS infrastructure
│   ├── vault.tf             # Vault configuration
│   ├── variables.tf         # Configuration variables
│   ├── outputs.tf           # Output values
│   └── scripts/
│       ├── vault_init.sh    # Vault initialization
│       ├── get_ssm_param.sh # SSM parameter retrieval
│       └── wait_for_vault_ready.sh # Vault readiness check
├── lambda/
│   ├── lambda_function.py   # Lambda demonstration code
│   ├── requirements.txt     # Python dependencies
│   └── build.sh            # Lambda package builder
└── README.md
```

## Configuration

### Vault Settings
- **Credential TTL**: 1 hour (configurable)
- **Max TTL**: 24 hours
- **Database Engine**: MySQL 8.0
- **Authentication**: AWS IAM

### Security Features
- Vault runs on private subnet with public IP for demo
- Database accessible only from Vault and Lambda security groups
- IAM roles with least-privilege permissions
- Encrypted SSM parameters for sensitive data

## Monitoring

### CloudWatch Logs
- Lambda execution logs: `/aws/lambda/vault-database-writer`
- Vault initialization logs: Check EC2 console output

### Vault Audit
```bash
# View Vault status
curl -s http://$(terraform output -raw vault_public_ip):8200/v1/sys/health | jq .

# List active database connections
curl -s -H "X-Vault-Token: <token>" \
  http://$(terraform output -raw vault_public_ip):8200/v1/database/config/mysql
```

## vs. Traditional Approaches

| Aspect | Static Credentials | Dynamic Credentials |
|--------|-------------------|--------------------|
| **Storage** | Environment variables, config files | Generated on-demand |
| **Lifespan** | Permanent until manually rotated | Automatic expiration (1 hour) |
| **Sharing** | Shared across services | Unique per request |
| **Rotation** | Manual process | Automatic |
| **Audit** | Limited visibility | Full credential lifecycle tracking |
| **Compromise Risk** | High (long-lived) | Low (short-lived) |

## Cleanup

```bash
terraform destroy
```

## Security Considerations

- **Demo Environment**: Uses public IPs for simplicity
- **Production**: Deploy Vault in private subnets with load balancer
- **High Availability**: Use Vault clustering for production
- **Backup**: Implement Vault data backup strategy
- **Monitoring**: Add comprehensive logging and alerting

## Troubleshooting

### Vault Not Responding
```bash
# Check EC2 instance status
aws ec2 describe-instances --instance-ids $(terraform output -raw vault_instance_id)

# Check Vault health
curl http://$(terraform output -raw vault_public_ip):8200/v1/sys/health
```

### Lambda Authentication Issues
```bash
# Verify IAM role permissions
aws iam get-role --role-name lambda-vault-execution-role

# Check Lambda logs
aws logs tail /aws/lambda/vault-database-writer --follow
```

## Learn More

- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [Vault Database Secrets Engine](https://www.vaultproject.io/docs/secrets/databases)
- [AWS IAM Authentication](https://www.vaultproject.io/docs/auth/aws)

## Contributing

Contributions welcome! Please read our contributing guidelines and submit pull requests.

## License

MIT License - see LICENSE file for details.

---

**This project showcases the future of secrets management - where credentials are ephemeral resources, not permanent assets to protect.**