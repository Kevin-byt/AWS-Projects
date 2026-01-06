module "django_infrastructure" {
  source = "../modules"

  # Environment
  region                = var.region
  project_name          = var.project_name
  account_id            = var.account_id
  aws_profile           = var.aws_profile
  environment           = var.environment


  # VPC
  vpc_cidr                     = var.vpc_cidr
  public_subnet_az1_cidr       = var.public_subnet_az1_cidr
  public_subnet_az2_cidr       = var.public_subnet_az2_cidr
  private_app_subnet_az1_cidr  = var.private_app_subnet_az1_cidr
  private_app_subnet_az2_cidr  = var.private_app_subnet_az2_cidr
  private_data_subnet_az1_cidr = var.private_data_subnet_az1_cidr
  private_data_subnet_az2_cidr = var.private_data_subnet_az2_cidr

  # RDS
  db_user                       = var.db_user
  db_password                   = var.db_password
  db_name                       = var.db_name
  db_port                       = var.db_port
  multi_az_deployment           = var.multi_az_deployment
  database_instance_identifier = var.database_instance_identifier
  database_instance_class       = var.database_instance_class
  publicly_accessible           = var.publicly_accessible



  # ECR
  ecr_registry = var.ecr_registry

  # ECS
  architecture = var.architecture
  image_name1  = var.image_name1
  image_name2  = var.image_name2
  image_tag    = var.image_tag
  image_tag1   = var.image_tag1
  image_tag2   = var.image_tag2





  # CloudWatch
  enable_cloudwatch = var.enable_cloudwatch

  # CloudTrail
  enable_cloudtrail = var.enable_cloudtrail


}