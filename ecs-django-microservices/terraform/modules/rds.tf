# create database subnet group
resource "aws_db_subnet_group" "database_subnet_group" {
  name        = "${var.project_name}-${var.environment}-database-subnets"
  subnet_ids  = [aws_subnet.private_data_subnet_az1.id, aws_subnet.private_data_subnet_az2.id]
  description = "subnets for database instance"

  tags = {
    Name = "${var.project_name}-${var.environment}-database-subnets"
  }
}

# create the rds instance
resource "aws_db_instance" "database_instance" {
  engine                 = "postgres"
  engine_version         = "14"
  multi_az               = var.multi_az_deployment
  identifier             = var.database_instance_identifier
  username               = var.db_user
  password               = var.db_password
  db_name                = var.db_name
  instance_class         = var.database_instance_class
  allocated_storage      = 200
  db_subnet_group_name   = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids = [aws_security_group.database_security_group.id]
  availability_zone      = data.aws_availability_zones.available_zones.names[0]
  skip_final_snapshot    = true
  publicly_accessible    = var.publicly_accessible
}
