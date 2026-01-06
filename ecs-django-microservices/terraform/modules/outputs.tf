# ALB DNS name
output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.application_load_balancer.dns_name
}

# RDS endpoint
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.database_instance.endpoint
  sensitive   = true
}

# ECS cluster name
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.ecs_cluster.name
}