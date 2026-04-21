# =============================================================================
# VARIABLES
# =============================================================================

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "infra-poc"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "poc"
}

# ── VPC / Networking ──────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (for NAT GW & LBs)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private app-tier subnets (nginx servers)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_misc_subnet_cidrs" {
  description = "CIDR blocks for private misc/backend subnets (debian servers)"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private DB subnets (RDS subnet group needs ≥2 AZs)"
  type        = list(string)
  default     = ["10.0.31.0/24", "10.0.32.0/24"]
}

# ── Compute ───────────────────────────────────────────────────────────────────

variable "nginx_instance_type" {
  description = "EC2 instance type for Nginx servers"
  type        = string
  default     = "t3.small"
}

variable "misc_instance_type" {
  description = "EC2 instance type for misc/backend (Debian) servers"
  type        = string
  default     = "t3.small"
}

variable "nginx_server_count" {
  description = "Number of Nginx (Oracle Linux) servers to create"
  type        = number
  default     = 6
}

variable "misc_server_count" {
  description = "Number of misc backend (Debian) servers to create"
  type        = number
  default     = 3
}

variable "key_pair_name" {
  description = "Name of the EC2 Key Pair for SSH access (must exist in the region)"
  type        = string
  default     = "poc-keypair"
}

# ── Database (RDS PaaS) ───────────────────────────────────────────────────────

variable "db_engine" {
  description = "RDS database engine"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "RDS database engine version"
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB for the RDS instance"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "Master password for RDS (use secrets manager in production)"
  type        = string
  default     = "Ch@ngeMe123!"
  sensitive   = true
}
