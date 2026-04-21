# =============================================================================
# LOAD BALANCERS
# Two ALBs:
#   lb-primary   → targets nginx-1..3  (first half of nginx fleet)
#   lb-secondary → targets nginx-4..6  (second half of nginx fleet)
# Both are internet-facing and live in the public subnets.
# =============================================================================

# ── Primary Load Balancer ─────────────────────────────────────────────────────

resource "aws_lb" "primary" {
  name               = "${var.project_name}-lb-primary"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false # Set true in production

  access_logs {
    bucket  = "" # Provide an S3 bucket name to enable access logs
    enabled = false
  }

  tags = { Name = "${var.project_name}-lb-primary" }
}

resource "aws_lb_target_group" "primary" {
  name        = "${var.project_name}-tg-primary"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = { Name = "${var.project_name}-tg-primary" }
}

# Attach nginx servers 1-3 to primary target group
resource "aws_lb_target_group_attachment" "primary" {
  count            = 3
  target_group_arn = aws_lb_target_group.primary.arn
  target_id        = aws_instance.nginx[count.index].id
  port             = 80
}

resource "aws_lb_listener" "primary_http" {
  load_balancer_arn = aws_lb.primary.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.primary.arn
  }

  tags = { Name = "${var.project_name}-listener-primary-http" }
}

# ── Secondary Load Balancer ───────────────────────────────────────────────────

resource "aws_lb" "secondary" {
  name               = "${var.project_name}-lb-secondary"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = { Name = "${var.project_name}-lb-secondary" }
}

resource "aws_lb_target_group" "secondary" {
  name        = "${var.project_name}-tg-secondary"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = { Name = "${var.project_name}-tg-secondary" }
}

# Attach nginx servers 4-6 to secondary target group
resource "aws_lb_target_group_attachment" "secondary" {
  count            = 3
  target_group_arn = aws_lb_target_group.secondary.arn
  target_id        = aws_instance.nginx[count.index + 3].id
  port             = 80
}

resource "aws_lb_listener" "secondary_http" {
  load_balancer_arn = aws_lb.secondary.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.secondary.arn
  }

  tags = { Name = "${var.project_name}-listener-secondary-http" }
}
