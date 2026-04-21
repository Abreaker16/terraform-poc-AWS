# =============================================================================
# COMPUTE - EC2 Instances
# =============================================================================

# ── User Data: Nginx install on Oracle Linux ──────────────────────────────────

locals {
  nginx_userdata = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    # Oracle Linux uses dnf/yum
    dnf update -y
    dnf install -y nginx

    # Enable and start nginx
    systemctl enable nginx
    systemctl start nginx

    # Write a simple status page
    cat > /usr/share/nginx/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head><title>POC Nginx Server</title></head>
    <body>
      <h1>Nginx OK</h1>
      <p>Host: $(hostname -f)</p>
      <p>OS: Oracle Linux</p>
    </body>
    </html>
    HTML

    # Signal readiness
    echo "nginx-setup-complete" > /tmp/bootstrap_done
  EOF

  misc_userdata = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    # Debian uses apt
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y curl wget htop net-tools

    # Placeholder app listener on port 8080
    apt-get install -y python3
    nohup python3 -m http.server 8080 &

    echo "misc-setup-complete" > /tmp/bootstrap_done
  EOF
}

# ── Nginx Servers (Oracle Linux) — 6 servers ─────────────────────────────────

resource "aws_instance" "nginx" {
  count = var.nginx_server_count

  ami                    = data.aws_ami.oracle_linux.id
  instance_type          = var.nginx_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.private_app[count.index % length(aws_subnet.private_app)].id
  vpc_security_group_ids = [aws_security_group.nginx.id]

  # No public IP — outbound via NAT only
  associate_public_ip_address = false

  user_data                   = base64encode(local.nginx_userdata)
  user_data_replace_on_change = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-nginx-${count.index + 1}"
    Role = "nginx-app-server"
    OS   = "oracle-linux"
  }
}

# ── Misc / Backend Servers (Debian) — 3 servers ──────────────────────────────

resource "aws_instance" "misc" {
  count = var.misc_server_count

  ami                    = data.aws_ami.debian.id
  instance_type          = var.misc_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.private_misc[count.index % length(aws_subnet.private_misc)].id
  vpc_security_group_ids = [aws_security_group.misc.id]

  # No public IP — outbound via NAT only
  associate_public_ip_address = false

  user_data                   = base64encode(local.misc_userdata)
  user_data_replace_on_change = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-misc-${count.index + 1}"
    Role = "backend-server"
    OS   = "debian"
  }
}
