# create an auto scaling group for ecs service 1
resource "aws_appautoscaling_target" "ecs_asg_service1" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${var.project_name}-${var.environment}-cluster/${var.project_name}-${var.environment}-service1"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.ecs_service1]
}

# create an auto scaling group for ecs service 2
resource "aws_appautoscaling_target" "ecs_asg_service2" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${var.project_name}-${var.environment}-cluster/${var.project_name}-${var.environment}-service2"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.ecs_service2]
}

# create scaling policy for service 1
resource "aws_appautoscaling_policy" "ecs_policy_service1" {
  name               = "${var.project_name}-${var.environment}-service1-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "service/${var.project_name}-${var.environment}-cluster/${var.project_name}-${var.environment}-service1"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70
    scale_out_cooldown = 300
    scale_in_cooldown  = 300
    disable_scale_in   = false
  }

  depends_on = [aws_appautoscaling_target.ecs_asg_service1]
}

# create scaling policy for service 2
resource "aws_appautoscaling_policy" "ecs_policy_service2" {
  name               = "${var.project_name}-${var.environment}-service2-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "service/${var.project_name}-${var.environment}-cluster/${var.project_name}-${var.environment}-service2"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70
    scale_out_cooldown = 300
    scale_in_cooldown  = 300
    disable_scale_in   = false
  }

  depends_on = [aws_appautoscaling_target.ecs_asg_service2]
}
