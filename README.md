# Terraform Infrastructure as Code Repository

This repository contains a collection of Terraform modules for deploying various AWS infrastructure configurations. Each folder represents a different use case or architecture pattern, ranging from basic AWS resources to complex 3-tier applications.

---

## 📁 Project Structure

### **1. `3tier_architecture/`** - Production-Grade 3-Tier Web Application
A complete, production-ready infrastructure for a scalable web application with separation of concerns across three tiers.

#### **What it does:**
- Deploys a **3-tier architecture** (Web → Application → Database) across AWS
- Uses **VPC** with public and private subnets across two availability zones for high availability
- Implements **Application Load Balancer (ALB)** in the public tier for traffic distribution
- Runs **Flask Python application** on EC2 instances managed by Auto Scaling Group in the private app tier
- Deploys **RDS MySQL database** in the private database tier
- Implements security groups and network ACLs for isolation between tiers

#### **Key Resources:**
- **`network.tf`** - VPC setup with 6 subnets (2 public, 2 private app, 2 private DB across 2 AZs)
- **`compute.tf`** - Application Load Balancer, Launch Template, Auto Scaling Group, EC2 instances
- **`database.tf`** - RDS MySQL database with Multi-AZ support
- **`security.tf`** - Security groups for ALB, EC2, and RDS with appropriate ingress/egress rules
- **`variables.tf`** - Input variables (AWS region, DB credentials, etc.)
- **`output.tf`** - Output values (ALB DNS, RDS endpoint, etc.)
- **`providers.tf`** - AWS provider configuration (ap-south-1 region)

#### **Architecture Overview:**
```
Internet → ALB (Public) → EC2 ASG (Private App) → RDS (Private DB)
           Port 80              Port 5000          Port 3306
```

#### **Deploy:**
```bash
cd 3tier_architecture
terraform init
terraform plan -var="db_password=YourSecurePassword"
terraform apply -var="db_password=YourSecurePassword"
```

---

### **2. `basics/`** - Foundational AWS Services (Learning Module)

Subdirectory with beginner-level Terraform examples for learning AWS basics.

#### **`basics/IAM/`** - Identity and Access Management
Demonstrates IAM user creation with role-based permissions.

**What it does:**
- Creates an IAM user with programmatic access
- Attaches managed policies for S3 full access and EC2 read-only access
- Generates a login profile for console access

**Files:**
- **`iam.tf`** - IAM user, login profile, and policy attachments
- **`provider.tf`** - AWS provider configuration

**Use Case:** Grant team members specific AWS permissions without root access

**Deploy:**
```bash
cd basics/IAM
terraform init
terraform apply
# Outputs include user password (sensitive)
```

#### **`basics/s3/`** - Simple Storage Service
Demonstrates S3 bucket creation and object uploads.

**What it does:**
- Creates an S3 bucket
- Uploads a text file as an object in the bucket

**Files:**
- **`bucket&object.tf`** - S3 bucket and object resources
- **`provide.tf`** - AWS provider configuration
- **`cloud.txt`** - Sample file to upload to S3

**Use Case:** Object storage, backups, static website hosting

**Deploy:**
```bash
cd basics/s3
terraform init
terraform apply
```

---

### **3. `app/`** - Flask Application (Application Tier)

Python Flask application that serves as the web backend for the 3-tier architecture.

#### **What it does:**
- Provides REST API endpoints for message management
- Connects to RDS MySQL database
- Renders HTML templates for web UI
- Expects database credentials via environment variables

#### **Key Files:**
- **`app.py`** - Main Flask application
  - `GET /` - Renders HTML template
  - `POST /messages` - Creates new message in database
  - `GET /messages` - Retrieves all messages
  - Connects to RDS using environment variables: `DB_HOST`, `DB_USER`, `DB_PASSWORD`

- **`requirements.txt`** - Python dependencies (Flask, pymysql, etc.)

- **`templates/index.html`** - Web UI for the application

#### **How it integrates:**
When deployed via the 3-tier architecture, EC2 instances in the Auto Scaling Group run this app and connect to the RDS database automatically.

---

### **4. `ECS_EC2/`** - Container Orchestration on EC2

Deploys a containerized application using Amazon ECS (Elastic Container Service) on EC2 instances.

#### **What it does:**
- Creates an **ECS Cluster** for container orchestration
- Configures **EC2 launch template** with ECS-optimized AMI
- Sets up **Auto Scaling Group** to manage EC2 instances in the cluster
- Deploys containerized application with Load Balancer
- Implements **IAM roles** for EC2 instances to communicate with ECS

#### **Key Resources:**
- **`compute.tf`** - ECS cluster, launch template, ASG, EC2 instances
- **`network.tf`** - VPC, subnets, internet gateway, route tables
- **`loadBalancer.tf`** - Application Load Balancer and target groups
- **`firewalls.tf`** - Security groups for ALB, EC2, and RDS
- **`applicationsDefinitions.tf`** - ECS task definitions and services
- **`permmisions.tf`** - IAM roles and instance profiles
- **`outputs.tf`** - Export ALB DNS and other endpoints
- **`provider.tf`** - AWS provider configuration

#### **Key Files:**
- **`webpage/Dockerfile`** - Docker image definition for containerized app
- **`webpage/index.html`** - Static HTML served by container

#### **Use Case:** 
Containerized microservices, easy horizontal scaling, container management without managing Kubernetes complexity

#### **Deploy:**
```bash
cd ECS_EC2
terraform init
terraform plan
terraform apply
```

---

## 🚀 Getting Started

### Prerequisites
- Terraform installed (v1.0+)
- AWS CLI configured with credentials
- AWS account with appropriate permissions

### Regional Configuration
All modules are configured for **AWS Region: `ap-south-1`** (Mumbai)
To change region, modify the provider blocks or use `-var` flag.

### Quick Start

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

2. **Review the plan:**
   ```bash
   terraform plan
   ```

3. **Apply configuration:**
   ```bash
   terraform apply
   ```

4. **Destroy resources (when done):**
   ```bash
   terraform destroy
   ```

---

## 📊 Architecture Comparison

| Module | Tier | Complexity | Use Case |
|--------|------|-----------|----------|
| **3tier_architecture** | 3-tier | High | Production web apps |
| **ECS_EC2** | Containerized | Medium-High | Microservices, containers |
| **basics/IAM** | Identity | Low | User management |
| **basics/s3** | Storage | Low | Object storage, backups |

---

## 📝 Best Practices Implemented

1. **High Availability** - Multi-AZ deployments across 2 availability zones
2. **Security** - Separate subnets for each tier, restrictive security groups
3. **Scalability** - Auto Scaling Groups for automatic instance management
4. **Infrastructure as Code** - Version-controlled, reproducible deployments
5. **Variable Management** - Sensitive data (passwords) handled securely
6. **Health Checks** - Load balancers perform continuous health monitoring

---

## 🔑 Key Variables & Outputs

### 3-Tier Architecture Variables:
- `aws_region` - AWS deployment region (default: ap-south-1)
- `db_username` - RDS database username (default: admin)
- `db_password` - RDS database password (required, sensitive)
- `db_name` - Database name (default: appdata)

### Common Outputs:
- ALB DNS name for accessing the application
- RDS endpoint for database connections
- EC2 Auto Scaling Group details
- Security group IDs

---

## 🛠️ Troubleshooting

- **Module not initializing?** - Run `terraform init` from the module directory
- **Permission denied?** - Check AWS credentials: `aws sts get-caller-identity`
- **Region issues?** - Verify provider configuration matches your AWS region
- **State file errors?** - Remove `terraform.tfstate*` files and reinitialize (in dev/test only!)

---

## 📚 Module Dependencies

```
3tier_architecture (Independent)
├── network.tf (VPC & Subnets)
├── security.tf (Security Groups)
├── compute.tf (ALB, ASG, EC2)
└── database.tf (RDS MySQL)

ECS_EC2 (Independent)
├── network.tf
├── firewalls.tf
├── compute.tf
├── applicationsDefinitions.tf
└── permissions.tf

basics/IAM (Independent)
└── iam.tf

basics/s3 (Independent)
└── bucket&object.tf

app/ (Dependency: Used by 3tier_architecture)
└── Flask app deployed on EC2 instances
```

---


## 📌 Notes

- **State Files:** `.tfstate` and `.tfstate.backup` files are committed to track resource state. In production, use remote state (S3, Terraform Cloud)
- **Sensitive Data:** Database passwords are marked as sensitive and not displayed in console output
- **Cleanup:** Always run `terraform destroy` to avoid unexpected AWS charges
- **Region:** Ensure you have the necessary service limits in your AWS region

---
