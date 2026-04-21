# =============================================================================
# SECURITY GROUPS
# =============================================================================

# ── Load Balancer SG (public-facing) ─────────────────────────────────────────

resource "aws_security_group" "lb" {
  name        = "${var.project_name}-sg-lb"
  description = "Allow HTTP/HTTPS inbound from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-lb" }
}

# ── Nginx App Server SG ───────────────────────────────────────────────────────

resource "aws_security_group" "nginx" {
  name        = "${var.project_name}-sg-nginx"
  description = "Allow HTTP from LBs and SSH within VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from Load Balancers"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  ingress {
    description = "SSH from within VPC (bastion/ops)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound (via NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-nginx" }
}

# ── Misc / Backend Debian Server SG ──────────────────────────────────────────

resource "aws_security_group" "misc" {
  name        = "${var.project_name}-sg-misc"
  description = "Allow traffic from app tier and SSH within VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App traffic from Nginx servers"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx.id]
  }

  ingress {
    description = "SSH from within VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound (via NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-misc" }
}

# ── RDS / Database SG ─────────────────────────────────────────────────────────

resource "aws_security_group" "db" {
  name        = "${var.project_name}-sg-db"
  description = "Allow DB port only from app and misc tiers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from Nginx servers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx.id]
  }

  ingress {
    description     = "MySQL from Misc/backend servers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.misc.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-db" }
}
