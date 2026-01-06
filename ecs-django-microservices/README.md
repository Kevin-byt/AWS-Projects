# ECS Django Microservices

A cloud-native microservices architecture built with Django REST Framework, deployed on AWS ECS Fargate with Terraform infrastructure as code.

## Architecture Overview

This project implements a library management system using microservices architecture:

- **Reader Service**: Handles read operations (GET books)
- **Writer Service**: Handles write operations (CREATE, UPDATE, DELETE books)
- **PostgreSQL Database**: Shared data store via AWS RDS
- **Application Load Balancer**: Routes traffic to services
- **ECS Fargate**: Container orchestration platform

## Project Structure

```
ecs-django-microservices/
├── app/
│   ├── reader-service/          # Read-only microservice
│   ├── writer-service/          # Write operations microservice
│   ├── requirements.txt         # Python dependencies
│   └── .env                     # Environment variables
├── terraform/
│   ├── env/                     # Environment-specific configs
│   └── modules/                 # Reusable Terraform modules
├── docker-compose.yml           # Local development setup
└── README.md
```

## Services

### Reader Service (Port 8000)
- **GET** `/books/` - List all books
- **GET** `/books/{id}/` - Get specific book
- **GET** `/health/` - Health check

### Writer Service (Port 8001)
- **POST** `/` - Create book
- **POST** `/books/create/` - Create book
- **PUT** `/books/{id}/update/` - Update book
- **DELETE** `/books/{id}/delete/` - Delete book
- **GET** `/health/` - Health check

## Technology Stack

- **Backend**: Django 4.2.16, Django REST Framework 3.15.2
- **Database**: PostgreSQL 15
- **Infrastructure**: AWS ECS Fargate, RDS, ALB, VPC
- **IaC**: Terraform
- **Containerization**: Docker
- **Local Development**: Docker Compose

## Prerequisites

- Python 3.8+
- Docker & Docker Compose
- AWS CLI configured
- Terraform >= 1.0
- PostgreSQL client (optional)

## Local Development

### 1. Clone Repository
```bash
git clone <repository-url>
cd ecs-django-microservices
```

### 2. Environment Setup
```bash
cp app/.env.example app/.env
# Edit app/.env with your database credentials
```

### 3. Start Services
```bash
docker-compose up -d
```

### 4. Verify Services
```bash
# Reader service
curl http://localhost:8000/health/

# Writer service  
curl http://localhost:8001/health/
```

### 5. API Testing
```bash
# Create a book
curl -X POST http://localhost:8001/ \
  -H "Content-Type: application/json" \
  -d '{"title":"Django Guide","author":"John Doe","description":"Learn Django"}'

# Get all books
curl http://localhost:8000/books/
```

## AWS Deployment

### 1. Configure Terraform Variables
```bash
cd terraform/env
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your AWS settings
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Plan Deployment
```bash
terraform plan
```

### 4. Deploy Infrastructure
```bash
terraform apply
```

### 5. Build and Push Docker Images
```bash
# Build images
docker build -t reader-service app/reader-service/reader/
docker build -t writer-service app/writer-service/writer/

# Tag and push to ECR
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.eu-west-1.amazonaws.com

docker tag reader-service:latest <account-id>.dkr.ecr.eu-west-1.amazonaws.com/reader-service:latest
docker tag writer-service:latest <account-id>.dkr.ecr.eu-west-1.amazonaws.com/writer-service:latest

docker push <account-id>.dkr.ecr.eu-west-1.amazonaws.com/reader-service:latest
docker push <account-id>.dkr.ecr.eu-west-1.amazonaws.com/writer-service:latest
```

## Infrastructure Components

### AWS Resources Created
- **VPC**: Multi-AZ setup with public/private subnets
- **ECS Cluster**: Fargate-based container orchestration
- **RDS**: PostgreSQL database with Multi-AZ option
- **ALB**: Application Load Balancer with health checks
- **ECR**: Container registry for Docker images
- **CloudWatch**: Logging and monitoring
- **CloudTrail**: API audit logging
- **Security Groups**: Network access control

### Key Terraform Modules
- `vpc.tf` - Network infrastructure
- `ecs.tf` - Container orchestration
- `rds.tf` - Database setup
- `alb.tf` - Load balancer configuration
- `ecr.tf` - Container registry
- `security-group.tf` - Network security

## Environment Variables

### Required Variables
```bash
DB_HOST=<rds-endpoint>
DB_USER=postgres
DB_PASSWORD=<secure-password>
DB_NAME=postgres
DB_PORT=5432
```

## Monitoring & Logging

- **CloudWatch Logs**: Application logs from ECS containers
- **Health Checks**: Built-in health endpoints for each service
- **ALB Health Checks**: Load balancer monitors service health
- **CloudTrail**: AWS API call auditing

## Security Features

- Private subnets for application containers
- Security groups with minimal required access
- RDS in private subnets
- IAM roles with least privilege
- Environment variable injection for secrets

## Scaling Configuration

- **ECS Services**: Auto-scaling based on CPU/memory
- **RDS**: Multi-AZ deployment for high availability
- **ALB**: Distributes traffic across healthy containers
- **Fargate**: Serverless container scaling

## Development Workflow

1. **Local Development**: Use Docker Compose for rapid iteration
2. **Testing**: Test APIs using curl or Postman
3. **Build Images**: Create Docker images for services
4. **Deploy**: Push images to ECR and update ECS services
5. **Monitor**: Check CloudWatch logs and metrics

## Troubleshooting

### Common Issues
- **Database Connection**: Verify RDS security groups and credentials
- **Service Discovery**: Check ECS service health in AWS Console
- **Load Balancer**: Verify target group health checks
- **Container Logs**: Check CloudWatch logs for application errors

### Useful Commands
```bash
# Check ECS service status
aws ecs describe-services --cluster <cluster-name> --services <service-name>

# View container logs
aws logs tail /ecs/<project-name>-<env>-td --follow

# Test database connectivity
psql -h <rds-endpoint> -U postgres -d postgres
```

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/new-feature`)
3. Commit changes (`git commit -am 'Add new feature'`)
4. Push to branch (`git push origin feature/new-feature`)
5. Create Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.