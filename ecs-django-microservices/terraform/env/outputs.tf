output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.django_infrastructure.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.django_infrastructure.rds_endpoint
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.django_infrastructure.ecs_cluster_name
}