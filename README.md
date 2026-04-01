# TechCorp Month 1 Assessment - Terraform Infrastructure

![Terraform](https://img.shields.io/badge/Terraform-0.15%2B-7B42BC)
![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900)

**Complete high-availability web application infrastructure** deployed using Terraform on AWS.

## Architecture Overview

- **VPC**: `10.0.0.0/16` with DNS support
- **Public Subnets** (2 AZs): Internet-facing with ALB and Bastion
- **Private Subnets** (2 AZs): Web servers + Database (NAT-protected)
- **Internet Gateway** + **2 NAT Gateways** (one per AZ for high availability)
- **Application Load Balancer** (public) routing to 2 Web servers
- **Bastion Host** in public subnet for secure SSH access
- **2 Web Servers** (Apache + stylish dynamic page) in private subnets
- **1 PostgreSQL Database** in private subnet

All resources are tagged with `techcorp-*` prefix as per requirements.

## Prerequisites

- AWS account with admin permissions
- Terraform ≥ 1.5 installed
- AWS CLI configured (`aws configure`)
- Your current public IP address (for Bastion SSH access)
- SSH key pair (optional - password auth is enabled)

## Variables

Create a file named `terraform.tfvars` (copy from `terraform.tfvars.example`):

```hcl
region     = "us-east-1"
my_ip      = "YOUR_PUBLIC_IP/32"     # ← CHANGE THIS (run: curl ifconfig.me)
key_pair_name = "YOUR_KEY_PAIR_NAME"                 # optional
```

## Deployment Steps

1. Clone the repository

   ```bash
   git clone https://github.com/Tbraima44/month-one-assessment.git
   cd month-one-assessment
   ```

2. Initialize Terraform

   ```bash
   terraform init
   ```

3. Review the plan

   ```bash
   terraform plan
   ```

4. Deploy the infrastructure

   ```bash
   terraform apply -auto-approve
   ```

## Expected Outputs

```
alb_dns_name     = "techcorp-alb-....us-east-1.elb.amazonaws.com"
bastion_public_ip = "x.x.x.x"
web_instance_ips = {
  "web1" = "10.0.x.x"
  "web2" = "10.0.x.x"
}
db_instance_ip   = "10.0.x.x"
vpc_id           = "vpc-..."
```

## How to Access

### 1. Web Application (via ALB)

Open in browser:

```
http://<alb_dns_name>
```

You will see a stylish Bootstrap page showing:
- Instance ID
- Private IP Address
- Instance Type
- Availability Zone
- "HEALTHY" badge (rotates between both web servers)

### 2. Bastion Host (SSH)

```bash
ssh -i altschool.pem ec2-user@<bastion_public_ip>
```

### 3. Web Servers (via Bastion)

```bash
ssh ec2-user@<web1_private_ip>     # or web2
# Password: TechCorpPass2026!
```

### 4. Database Server (via Bastion)

```bash
ssh ec2-user@<db_private_ip>
# Password: TechCorpPass2026!

# Connect to PostgreSQL
sudo -u postgres psql -U postgres -d techcorp_db -c "\l"
```

## Cleanup

```bash
terraform destroy -auto-approve
```

**Warning:** This will permanently delete the VPC, EC2 instances, ALB, and all data.

## Evidence Folder (`evidence/`)

Contains screenshots of:
- terraform plan output
- terraform apply completion
- AWS Console (VPC, Subnets, EC2 instances, ALB, Target Group showing Healthy)
- Browser showing ALB serving both web instances with metadata
- SSH via Bastion → Web servers
- SSH via Bastion → DB server
- PostgreSQL connection (`\l` command)

## Notes

- All security groups follow least-privilege principle
- Password authentication enabled for assessment requirements
- Health checks use `/health` endpoint (returns OK)
- Web pages dynamically display real instance metadata
- Infrastructure is multi-AZ and highly available
- Project completed as per TechCorp Month 1 Assessment requirements.

Made with ❤️ for the assessment  
Toheeb - Junior Cloud Engineer
---
