# Terraform Infrastructure POC

## Architecture Overview

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│                    AWS VPC (10.0.0.0/16)                │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │            PUBLIC SUBNETS (10.0.1-2.x)           │  │
│  │                                                  │  │
│  │   ┌──────────────┐    ┌──────────────┐          │  │
│  │   │  ALB Primary │    │ ALB Secondary│          │  │
│  │   │  (nginx 1-3) │    │  (nginx 4-6) │          │  │
│  │   └──────┬───────┘    └──────┬───────┘          │  │
│  │          │                   │                  │  │
│  │   ┌──────────────┐                              │  │
│  │   │  NAT Gateway │ ◄── EIP (shared egress)      │  │
│  │   └──────┬───────┘                              │  │
│  └──────────┼───────────────────┼──────────────────┘  │
│             │                   │                      │
│  ┌──────────▼───────────────────▼──────────────────┐  │
│  │       PRIVATE APP SUBNETS (10.0.11-12.x)        │  │
│  │                                                  │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐         │  │
│  │  │ nginx-1  │ │ nginx-2  │ │ nginx-3  │  ┌───┐  │  │
│  │  │Oracle Lin│ │Oracle Lin│ │Oracle Lin│  │ N │  │  │
│  │  └──────────┘ └──────────┘ └──────────┘  │ A │  │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐  │ T │  │  │
│  │  │ nginx-4  │ │ nginx-5  │ │ nginx-6  │  │   │  │  │
│  │  │Oracle Lin│ │Oracle Lin│ │Oracle Lin│  │ G │  │  │
│  │  └──────────┘ └──────────┘ └──────────┘  │ W │  │  │
│  └────────────────────────────────────────── │   │──┘  │
│                                              └───┘      │
│  ┌──────────────────────────────────────────────────┐  │
│  │       PRIVATE MISC SUBNETS (10.0.21-22.x)        │  │
│  │                                                  │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐         │  │
│  │  │  misc-1  │ │  misc-2  │ │  misc-3  │         │  │
│  │  │  Debian  │ │  Debian  │ │  Debian  │         │  │
│  │  └──────────┘ └──────────┘ └──────────┘         │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         PRIVATE DB SUBNETS (10.0.31-32.x)        │  │
│  │                                                  │  │
│  │         ┌────────────────────────────┐           │  │
│  │         │   RDS MySQL (PaaS) Node    │           │  │
│  │         │   Managed | Encrypted      │           │  │
│  │         └────────────────────────────┘           │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Resource Count

| Resource              | Count | OS / Engine      | Notes                        |
|-----------------------|-------|------------------|------------------------------|
| Nginx App Servers     | 6     | Oracle Linux 9   | Private, Nginx installed     |
| Backend Servers       | 3     | Debian 12        | Private, port 8080           |
| DB PaaS (RDS)         | 1     | MySQL 8.0        | Managed, private endpoint    |
| **Total Servers**     | **10**|                  |                              |
| Application LBs       | 2     | AWS ALB          | Internet-facing              |
| NAT Gateway           | 1     | AWS NAT GW       | Shared outbound egress       |

## Prerequisites

- Terraform ≥ 1.5.0
- AWS CLI configured (`aws configure`)
- An EC2 Key Pair created in your target region
- IAM permissions for EC2, VPC, RDS, ELB

## Quick Start

```bash
# 1. Clone / copy files to your working directory
cd terraform-poc/

# 2. Copy the example vars file
cp terraform.tfvars.example terraform.tfvars

# 3. Edit terraform.tfvars — at minimum update:
#    - key_pair_name  (must exist in your AWS region)
#    - db_password    (use a strong password)

# 4. Initialise Terraform
terraform init

# 5. Preview the plan
terraform plan

# 6. Apply
terraform apply

# 7. Tear down when done
terraform destroy
```

## File Structure

```
terraform-poc/
├── main.tf              # Provider config, AMI data sources
├── variables.tf         # All input variables with defaults
├── networking.tf        # VPC, subnets, IGW, NAT GW, route tables
├── security_groups.tf   # SGs for LB, Nginx, Misc, DB tiers
├── compute.tf           # EC2 instances (nginx + misc) with user-data
├── load_balancers.tf    # 2 ALBs, target groups, listeners
├── database.tf          # RDS MySQL PaaS instance + subnet group
├── outputs.tf           # Useful outputs after apply
└── terraform.tfvars.example  # Example variable overrides
```

## Security Notes

- All servers have **no public IP** — internet access via NAT only
- RDS endpoint is **private** (no public accessibility)
- IMDSv2 enforced on all EC2 instances
- Storage encrypted at rest (EC2 EBS + RDS)
- Security groups follow least-privilege per tier

## Production Hardening (out of scope for POC)

- [ ] Multi-AZ RDS (`multi_az = true`)
- [ ] One NAT GW per AZ for HA
- [ ] HTTPS listeners with ACM certificates
- [ ] Store `db_password` in AWS Secrets Manager
- [ ] Enable RDS deletion protection
- [ ] Enable ALB access logs to S3
- [ ] Add WAF to load balancers
- [ ] Enable VPC Flow Logs
