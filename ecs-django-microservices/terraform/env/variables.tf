# environment variables
variable "region" {
  description = "region to create resources"
  type        = string
}

variable "project_name" {
  description = "project name"
  type        = string
}

variable "account_id" {
  description = "region to create resources"
  type        = string
}

variable "aws_profile" {
  description = "region to create resources"
  type        = string
}

variable "environment" {
  description = "environment"
  type        = string
}

# vpc variables
variable "vpc_cidr" {
  description = "vpc cidr block"
  type        = string
}

variable "public_subnet_az1_cidr" {
  description = "public subnet az1 cidr block"
  type        = string
}

variable "public_subnet_az2_cidr" {
  description = "public subnet az2 cidr block"
  type        = string
}

variable "private_app_subnet_az1_cidr" {
  description = "private app subnet az1 cidr block"
  type        = string
}

variable "private_app_subnet_az2_cidr" {
  description = "private app subnet az2 cidr block"
  type        = string
}

variable "private_data_subnet_az1_cidr" {
  description = "private data subnet az1 cidr block"
  type        = string
}

variable "private_data_subnet_az2_cidr" {
  description = "private data subnet az2 cidr block"
  type        = string
}

# rds variables
variable "db_user" {
  description = "db username"
  type        = string
}

variable "db_password" {
  description = "db password"
  type        = string
}

variable "db_name" {
  description = "rds db name"
  type        = string
}

variable "db_port" {
  description = "rds db port"
  type        = number
}

variable "multi_az_deployment" {
  description = "create a standby db instance"
  type        = bool
}

variable "database_instance_identifier" {
  description = "database instance identifier"
  type        = string
}

variable "database_instance_class" {
  description = "database instance type"
  type        = string
}

variable "publicly_accessible" {
  description = "controls if instance is publicly accessible"
  type        = bool
}

# ecr variables
variable "ecr_registry" {
  description = "ecr registry"
  type        = string
}

# ecs variables
variable "architecture" {
  description = "ecs cpu architecture"
  type        = string
}

variable "image_name1" {
  description = "the web docker image name"
  type        = string
}

variable "image_name2" {
  description = "the second web docker image name"
  type        = string
}

variable "image_tag" {
  description = "the docker image tag"
  type        = string
}

variable "image_tag1" {
  description = "tag for first microservice"
  type        = string
  default     = ""
}

variable "image_tag2" {
  description = "tag for second microservice"
  type        = string
  default     = ""
}

# cloudwatch variables
variable "enable_cloudwatch" {
  description = "enable cloudwatch monitoring"
  type        = bool
  default     = true
}

# cloudtrail variables
variable "enable_cloudtrail" {
  description = "enable cloudtrail logging"
  type        = bool
  default     = true
}