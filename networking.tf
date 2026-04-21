# =============================================================================
# NETWORKING - VPC, Subnets, IGW, NAT, Route Tables
# =============================================================================

# ── VPC ───────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-vpc" }
}

# ── Internet Gateway (for public subnets / NAT EIP) ───────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

# ── Public Subnets (NAT GW lives here; LBs span both) ─────────────────────────

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false # No auto-assign; NAT EIP is explicit

  tags = { Name = "${var.project_name}-public-${count.index + 1}" }
}

# ── Private App Subnets (Nginx / Oracle Linux servers) ────────────────────────

resource "aws_subnet" "private_app" {
  count             = length(var.private_app_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { Name = "${var.project_name}-private-app-${count.index + 1}" }
}

# ── Private Misc Subnets (Debian backend servers) ────────────────────────────

resource "aws_subnet" "private_misc" {
  count             = length(var.private_misc_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_misc_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { Name = "${var.project_name}-private-misc-${count.index + 1}" }
}

# ── Private DB Subnets (RDS) ──────────────────────────────────────────────────

resource "aws_subnet" "private_db" {
  count             = length(var.private_db_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { Name = "${var.project_name}-private-db-${count.index + 1}" }
}

# =============================================================================
# NAT GATEWAY  (single NAT for POC - use one per AZ for production HA)
# =============================================================================

resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
  tags       = { Name = "${var.project_name}-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Place NAT GW in first public subnet
  depends_on    = [aws_internet_gateway.main]

  tags = { Name = "${var.project_name}-nat-gw" }
}

# =============================================================================
# ROUTE TABLES
# =============================================================================

# ── Public Route Table (0.0.0.0/0 → IGW) ────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.project_name}-rt-public" }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ── Private Route Table (0.0.0.0/0 → NAT GW) ────────────────────────────────

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = { Name = "${var.project_name}-rt-private" }
}

resource "aws_route_table_association" "private_app" {
  count          = length(aws_subnet.private_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_misc" {
  count          = length(aws_subnet.private_misc)
  subnet_id      = aws_subnet.private_misc[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_db" {
  count          = length(aws_subnet.private_db)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private.id
}
