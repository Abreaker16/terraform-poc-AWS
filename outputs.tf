# =============================================================================
# OUTPUTS
# =============================================================================

# ── VPC ───────────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway (shared egress for all private servers)"
  value       = aws_eip.nat.public_ip
}

# ── Load Balancers ────────────────────────────────────────────────────────────

output "lb_primary_dns" {
  description = "DNS name of the primary load balancer (nginx-1 to nginx-3)"
  value       = aws_lb.primary.dns_name
}

output "lb_secondary_dns" {
  description = "DNS name of the secondary load balancer (nginx-4 to nginx-6)"
  value       = aws_lb.secondary.dns_name
}

# ── Nginx Servers ─────────────────────────────────────────────────────────────

output "nginx_server_private_ips" {
  description = "Private IP addresses of all Nginx (Oracle Linux) servers"
  value = {
    for idx, inst in aws_instance.nginx :
    "nginx-${idx + 1}" => inst.private_ip
  }
}

output "nginx_server_ids" {
  description = "EC2 instance IDs of all Nginx servers"
  value       = aws_instance.nginx[*].id
}

# ── Misc / Backend Servers ────────────────────────────────────────────────────

output "misc_server_private_ips" {
  description = "Private IP addresses of all misc/backend (Debian) servers"
  value = {
    for idx, inst in aws_instance.misc :
    "misc-${idx + 1}" => inst.private_ip
  }
}

output "misc_server_ids" {
  description = "EC2 instance IDs of all misc/backend servers"
  value       = aws_instance.misc[*].id
}

# ── Database ──────────────────────────────────────────────────────────────────

output "db_endpoint" {
  description = "RDS database endpoint (host:port)"
  value       = aws_db_instance.main.endpoint
}

output "db_port" {
  description = "RDS database port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Name of the initial database"
  value       = aws_db_instance.main.db_name
}

# ── Summary ───────────────────────────────────────────────────────────────────

output "infrastructure_summary" {
  description = "High-level summary of the deployed infrastructure"
  value = {
    total_servers          = var.nginx_server_count + var.misc_server_count
    nginx_servers          = var.nginx_server_count
    misc_servers           = var.misc_server_count
    db_paas_nodes          = 1
    load_balancers         = 2
    nat_gateways           = 1
    private_subnets        = length(aws_subnet.private_app) + length(aws_subnet.private_misc) + length(aws_subnet.private_db)
    public_subnets         = length(aws_subnet.public)
    nginx_os               = "Oracle Linux 9"
    misc_os                = "Debian 12 (Bookworm)"
    db_engine              = "${var.db_engine} ${var.db_engine_version}"
    public_ip_on_servers   = false
  }
}
