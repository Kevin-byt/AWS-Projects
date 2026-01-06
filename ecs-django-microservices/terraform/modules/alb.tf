# create application load balancer
resource "aws_lb" "application_load_balancer" {
  name                       = "${var.project_name}-${var.environment}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_security_group.id]
  subnets                    = [aws_subnet.public_subnet_az1.id, aws_subnet.public_subnet_az2.id]
  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# create target group for reader service
resource "aws_lb_target_group" "reader_target_group" {
  name        = "${var.project_name}-${var.environment}-reader-tg"
  target_type = "ip"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200,301,302"
    path                = "/health/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

# create target group for writer service
resource "aws_lb_target_group" "writer_target_group" {
  name        = "${var.project_name}-${var.environment}-writer-tg"
  target_type = "ip"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200,301,302"
    path                = "/health/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

# create a listener on port 80 with forward action
resource "aws_lb_listener" "alb_http_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.reader_target_group.arn
  }
}

# Route write operations to writer service
resource "aws_lb_listener_rule" "writer_rule" {
  listener_arn = aws_lb_listener.alb_http_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.writer_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/books/create/*", "/books/*/update/*", "/books/*/delete/*"]
    }
  }
}

# Route read operations to reader service (default action handles this)
resource "aws_lb_listener_rule" "reader_rule" {
  listener_arn = aws_lb_listener.alb_http_listener.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.reader_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/books/*", "/books"]
    }
  }

  condition {
    http_request_method {
      values = ["GET"]
    }
  }
}
