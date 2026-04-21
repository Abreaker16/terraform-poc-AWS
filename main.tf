# =============================================================================
# TERRAFORM POC - 10 Server Infrastructure
# Architecture:
#   - 6 Nginx App Servers (Oracle Linux) - private, NAT egress
#   - 3 Misc/Backend Servers (Debian) - private, NAT egress
#   - 1 DB PaaS (Managed Database Service)
#   - 2 Load Balancers (for app servers)
#   - NAT Gateway (outbound internet for private servers)
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

# Oracle Linux 9 AMI (latest)
data "aws_ami" "oracle_linux" {
  most_recent = true
  owners      = ["131827586825"] # Oracle's official AWS account

  filter {
    name   = "name"
    values = ["OL9*x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Debian 12 (Bookworm) AMI (latest)
data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"] # Debian's official AWS account

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
