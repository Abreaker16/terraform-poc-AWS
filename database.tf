# =============================================================================
# DATABASE - RDS PaaS (1 managed DB node)
# Fully managed: patching, backups, failover handled by AWS
# =============================================================================

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Subnet group for POC RDS instance"
  subnet_ids  = aws_subnet.private_db[*].id

  tags = { Name = "${var.project_name}-db-subnet-group" }
}

resource "aws_db_parameter_group" "main" {
  name        = "${var.project_name}-db-params"
  family      = "mysql8.0"
  description = "Custom parameter group for POC MySQL"

  parameter {
    name  = "max_connections"
    value = "200"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = { Name = "${var.project_name}-db-params" }
}

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"

  # Engine
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  # Storage
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = 100 # Enable autoscaling up to 100 GB
  storage_type          = "gp3"
  storage_encrypted     = true

  # Credentials
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false # Private only — no public endpoint

  # Parameters
  parameter_group_name = aws_db_parameter_group.main.name

  # Backup & Maintenance
  backup_retention_period   = 7
  backup_window             = "03:00-04:00"
  maintenance_window        = "Mon:04:00-Mon:05:00"
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot     = true

  # Behaviour
  multi_az              = false # Set true for HA in production
  deletion_protection   = false # Set true in production
  skip_final_snapshot   = true  # Set false in production

  performance_insights_enabled = true

  tags = {
    Name = "${var.project_name}-db"
    Role = "paas-database"
  }
}
