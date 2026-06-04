
# Terraform + Ansible Kubernetes Automation using GitHub Actions

## Task Definition

This project automates Kubernetes cluster provisioning and application deployment on AWS using Terraform, Ansible, Helm, and GitHub Actions.

The workflow uses a GitHub-hosted `ubuntu-latest` runner. Terraform provisions AWS EC2 infrastructure, Ansible configures the Kubernetes cluster over SSH, Helm deploys the ModernChair application, and the workflow removes temporary SSH access after execution.

---

## Architecture

```text
GitHub Actions ubuntu-latest Runner
        |
        | Terraform
        v
AWS EC2 Infrastructure
1 Master Node + 1 Worker Node
        |
        | Temporary SSH access from GitHub runner IP
        v
Ansible Kubernetes Setup
        |
        | Helm
        v
ModernChair Application Deployment
```

---

## Tools Used

```text
Terraform
Ansible
GitHub Actions
AWS EC2
Kubernetes
Helm
Docker
```

---

## Project Structure

```text
terraform-ansible/
├── .github/
│   └── workflows/
│       └── terraform-k8s.yml
├── terraform/
│   ├── provider.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── output.tf
│   └── modules/
│       ├── keypair/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── output.tf
│       ├── security_group/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── output.tf
│       └── ec2/
│           ├── main.tf
│           ├── variables.tf
│           └── output.tf
├── ansible/
│   ├── ansible.cfg
│   ├── site.yml
│   └── roles/
│       ├── common/
│       ├── master/
│       ├── worker/
│       └── helm_app/
├── helm/
│   └── modernchair/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           └── service.yaml
└── README.md
```

---

# 1. GitHub Secrets

Go to:

```text
GitHub Repository → Settings → Secrets and variables → Actions → Secrets
```

Add the following secrets:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
EC2_PRIVATE_KEY
```

`EC2_PRIVATE_KEY` should contain the full private key:

```text
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

---

# 2. GitHub Variables

Go to:

```text
GitHub Repository → Settings → Secrets and variables → Actions → Variables
```

Add the following variables:

```text
AWS_REGION = ap-south-1
PROJECT_NAME = terraform-ansible-k8s
INSTANCE_TYPE = t3.medium
KEY_NAME = k8s-key
TF_SUBNET_ID = subnet-e3e72aae
ALLOWED_INGRESS_CIDRS = ["182.76.141.104/29","115.112.142.32/29","14.97.73.248/29"]
```

---

# 3. Terraform Files

## `terraform/provider.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region = var.region
}
```

---

## `terraform/variables.tf`

```hcl
variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
}

variable "public_key_path" {
  description = "Public key path generated in GitHub Actions runner"
  type        = string
}

variable "private_key_path" {
  description = "Private key path generated in GitHub Actions runner"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "allowed_ingress_cidrs" {
  description = "Company CIDR ranges allowed permanently"
  type        = list(string)
}
```

---

## `terraform/main.tf`

```hcl
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

module "keypair" {
  source = "./modules/keypair"

  key_name        = var.key_name
  public_key_path = var.public_key_path
  project_name    = var.project_name
}

module "security_group" {
  source = "./modules/security_group"

  project_name          = var.project_name
  vpc_id                = data.aws_vpc.default.id
  allowed_ingress_cidrs = var.allowed_ingress_cidrs
}

module "ec2" {
  source = "./modules/ec2"

  ami_id            = data.aws_ami.ubuntu_2204.id
  instance_type     = var.instance_type
  subnet_id         = var.subnet_id
  security_group_id = module.security_group.security_group_id
  key_name          = module.keypair.key_name
  project_name      = var.project_name
}
```

---

## `terraform/output.tf`

```hcl
output "master_instance_id" {
  value = module.ec2.master_instance_id
}

output "worker_instance_id" {
  value = module.ec2.worker_instance_id
}

output "master_public_ip" {
  value = module.ec2.master_public_ip
}

output "worker_public_ip" {
  value = module.ec2.worker_public_ip
}

output "master_private_ip" {
  value = module.ec2.master_private_ip
}

output "worker_private_ip" {
  value = module.ec2.worker_private_ip
}

output "security_group_id" {
  value = module.security_group.security_group_id
}

output "key_pair_name" {
  value = module.keypair.key_name
}
```

---

# 4. Terraform Modules

## `terraform/modules/keypair/variables.tf`

```hcl
variable "key_name" {
  description = "AWS key pair name"
  type        = string
}

variable "public_key_path" {
  description = "Path to public key"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}
```

---

## `terraform/modules/keypair/main.tf`

```hcl
resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)

  tags = {
    Name    = var.key_name
    Project = var.project_name
  }
}
```

---

## `terraform/modules/keypair/output.tf`

```hcl
output "key_name" {
  value = aws_key_pair.this.key_name
}
```

---

## `terraform/modules/security_group/variables.tf`

```hcl
variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "allowed_ingress_cidrs" {
  description = "Company CIDR ranges"
  type        = list(string)
}
```

---

## `terraform/modules/security_group/main.tf`

```hcl
resource "aws_security_group" "this" {
  name        = "${var.project_name}-sg"
  description = "Security group for Kubernetes cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from company CIDR ranges only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ingress_cidrs
  }

  ingress {
    description = "Kubernetes API from company CIDR ranges only"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ingress_cidrs
  }

  ingress {
    description = "NodePort range from company CIDR ranges only"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = var.allowed_ingress_cidrs
  }

  ingress {
    description = "Allow all internal cluster communication inside this SG"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "Allow outbound internet access for package installation"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}
```

---

## `terraform/modules/security_group/output.tf`

```hcl
output "security_group_id" {
  value = aws_security_group.this.id
}
```

---

## `terraform/modules/ec2/variables.tf`

```hcl
variable "ami_id" {
  description = "Ubuntu AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID"
  type        = string
}

variable "key_name" {
  description = "Key pair name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}
```

---

## `terraform/modules/ec2/main.tf`

```hcl
resource "aws_instance" "master" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name    = "k8s-master"
    Role    = "master"
    Project = var.project_name
  }
}

resource "aws_instance" "worker" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name    = "k8s-worker"
    Role    = "worker"
    Project = var.project_name
  }
}
```

---

## `terraform/modules/ec2/output.tf`

```hcl
output "master_instance_id" {
  value = aws_instance.master.id
}

output "worker_instance_id" {
  value = aws_instance.worker.id
}

output "master_public_ip" {
  value = aws_instance.master.public_ip
}

output "worker_public_ip" {
  value = aws_instance.worker.public_ip
}

output "master_private_ip" {
  value = aws_instance.master.private_ip
}

output "worker_private_ip" {
  value = aws_instance.worker.private_ip
}
```

---

# 5. Ansible Files

## `ansible/ansible.cfg`

```ini
[defaults]
inventory = inventory.ini
host_key_checking = False
retry_files_enabled = False
remote_user = ubuntu
timeout = 60
interpreter_python = auto_silent

[privilege_escalation]
become = True
become_method = sudo
become_user = root
```

---

## `ansible/site.yml`

```yaml
- name: Configure common Kubernetes components on all nodes
  hosts: k8s_cluster
  become: true
  roles:
    - common

- name: Initialize Kubernetes master node
  hosts: master
  become: true
  roles:
    - master

- name: Join worker node to Kubernetes cluster
  hosts: workers
  become: true
  roles:
    - worker

- name: Install Helm and deploy ModernChair application
  hosts: master
  become: true
  roles:
    - helm_app
```

---

# 6. GitHub Actions Workflow

## `.github/workflows/terraform-k8s.yml`

```yaml
name: Terraform Ansible Kubernetes Automation

on:
  workflow_dispatch:
    inputs:
      action:
        description: "Select Terraform action"
        required: true
        default: "plan"
        type: choice
        options:
          - plan
          - apply
          - destroy

concurrency:
  group: terraform-k8s
  cancel-in-progress: false

env:
  TF_DIR: terraform
  AWS_REGION: ${{ vars.AWS_REGION }}
  AWS_DEFAULT_REGION: ${{ vars.AWS_REGION }}

jobs:
  terraform-k8s:
    name: Terraform Ansible Kubernetes Setup
    runs-on: ubuntu-latest

    defaults:
      run:
        shell: bash

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Configure AWS credentials from GitHub Secrets
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ vars.AWS_REGION }}

      - name: Install required tools
        run: |
          sudo apt-get update
          sudo apt-get install -y ansible jq curl netcat-openbsd

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_wrapper: false

      - name: Prepare SSH key
        run: |
          mkdir -p "$RUNNER_TEMP/ssh"
          echo "${{ secrets.EC2_PRIVATE_KEY }}" > "$RUNNER_TEMP/ssh/k8s-key"
          chmod 400 "$RUNNER_TEMP/ssh/k8s-key"
          ssh-keygen -y -f "$RUNNER_TEMP/ssh/k8s-key" > "$RUNNER_TEMP/ssh/k8s-key.pub"
          chmod 644 "$RUNNER_TEMP/ssh/k8s-key.pub"

      - name: Generate Terraform variable file
        working-directory: ${{ env.TF_DIR }}
        run: |
          cat > github.auto.tfvars <<EOF
          region = "${{ vars.AWS_REGION }}"
          project_name = "${{ vars.PROJECT_NAME }}"
          instance_type = "${{ vars.INSTANCE_TYPE }}"
          key_name = "${{ vars.KEY_NAME }}"
          public_key_path = "$RUNNER_TEMP/ssh/k8s-key.pub"
          private_key_path = "$RUNNER_TEMP/ssh/k8s-key"
          subnet_id = "${{ vars.TF_SUBNET_ID }}"
          allowed_ingress_cidrs = ${{ vars.ALLOWED_INGRESS_CIDRS }}
          EOF

      - name: Terraform init
        working-directory: ${{ env.TF_DIR }}
        run: terraform init

      - name: Terraform format
        working-directory: ${{ env.TF_DIR }}
        run: terraform fmt -recursive

      - name: Terraform validate
        working-directory: ${{ env.TF_DIR }}
        run: terraform validate

      - name: Terraform plan
        working-directory: ${{ env.TF_DIR }}
        run: terraform plan

      - name: Terraform apply
        if: ${{ github.event.inputs.action == 'apply' }}
        working-directory: ${{ env.TF_DIR }}
        run: terraform apply -auto-approve

      - name: Terraform destroy
        if: ${{ github.event.inputs.action == 'destroy' }}
        working-directory: ${{ env.TF_DIR }}
        run: terraform destroy -auto-approve

      - name: Get Terraform outputs
        if: ${{ github.event.inputs.action == 'apply' }}
        working-directory: ${{ env.TF_DIR }}
        run: |
          echo "MASTER_PUBLIC_IP=$(terraform output -raw master_public_ip)" >> $GITHUB_ENV
          echo "WORKER_PUBLIC_IP=$(terraform output -raw worker_public_ip)" >> $GITHUB_ENV
          echo "SECURITY_GROUP_ID=$(terraform output -raw security_group_id)" >> $GITHUB_ENV

      - name: Get GitHub runner public IP
        if: ${{ github.event.inputs.action == 'apply' }}
        run: |
          RUNNER_PUBLIC_IP=$(curl -s https://checkip.amazonaws.com | tr -d '\n')
          echo "RUNNER_PUBLIC_IP=$RUNNER_PUBLIC_IP" >> $GITHUB_ENV
          echo "GitHub runner public IP is $RUNNER_PUBLIC_IP"

      - name: Temporarily allow SSH from GitHub runner
        if: ${{ github.event.inputs.action == 'apply' }}
        run: |
          aws ec2 authorize-security-group-ingress \
            --region "${{ vars.AWS_REGION }}" \
            --group-id "$SECURITY_GROUP_ID" \
            --protocol tcp \
            --port 22 \
            --cidr "$RUNNER_PUBLIC_IP/32" || true

      - name: Wait for SSH to master and worker
        if: ${{ github.event.inputs.action == 'apply' }}
        run: |
          echo "Waiting for SSH to master: $MASTER_PUBLIC_IP"
          for i in {1..40}; do
            if nc -vz -w 5 "$MASTER_PUBLIC_IP" 22; then
              echo "Master SSH is ready"
              break
            fi

            echo "Master SSH not ready yet... attempt $i/40"
            sleep 15
          done

          echo "Waiting for SSH to worker: $WORKER_PUBLIC_IP"
          for i in {1..40}; do
            if nc -vz -w 5 "$WORKER_PUBLIC_IP" 22; then
              echo "Worker SSH is ready"
              break
            fi

            echo "Worker SSH not ready yet... attempt $i/40"
            sleep 15
          done

      - name: Generate Ansible inventory
        if: ${{ github.event.inputs.action == 'apply' }}
        run: |
          cat > ansible/inventory.ini <<EOF
          [master]
          $MASTER_PUBLIC_IP ansible_user=ubuntu ansible_ssh_private_key_file=$RUNNER_TEMP/ssh/k8s-key ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=30'

          [workers]
          $WORKER_PUBLIC_IP ansible_user=ubuntu ansible_ssh_private_key_file=$RUNNER_TEMP/ssh/k8s-key ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=30'

          [k8s_cluster:children]
          master
          workers
          EOF

          cat ansible/inventory.ini

      - name: Test Ansible connectivity
        if: ${{ github.event.inputs.action == 'apply' }}
        working-directory: ansible
        run: |
          ANSIBLE_HOST_KEY_CHECKING=False ansible all -i inventory.ini -m ping

      - name: Run Ansible Kubernetes playbook
        if: ${{ github.event.inputs.action == 'apply' }}
        working-directory: ansible
        run: |
          ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini site.yml

      - name: Revoke temporary GitHub runner SSH rule
        if: ${{ always() && github.event.inputs.action == 'apply' }}
        run: |
          if [ -n "${SECURITY_GROUP_ID:-}" ] && [ -n "${RUNNER_PUBLIC_IP:-}" ]; then
            aws ec2 revoke-security-group-ingress \
              --region "${{ vars.AWS_REGION }}" \
              --group-id "$SECURITY_GROUP_ID" \
              --protocol tcp \
              --port 22 \
              --cidr "$RUNNER_PUBLIC_IP/32" || true
          fi
```

---

# 7. Run Workflow

Go to:

```text
GitHub Repository → Actions → Terraform Ansible Kubernetes Automation → Run workflow
```

First run:

```text
plan
```

Then run:

```text
apply
```

To delete resources, run:

```text
destroy
```

---

# 8. Verification Commands

## Check EC2 instances

```bash
aws ec2 describe-instances \
  --region ap-south-1 \
  --filters "Name=tag:Project,Values=terraform-ansible-k8s" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name']|[0].Value,PublicIpAddress,PrivateIpAddress]" \
  --output table
```

---

## Get master public IP

```bash
aws ec2 describe-instances \
  --region ap-south-1 \
  --filters "Name=tag:Name,Values=k8s-master" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text
```

---

## SSH into master

```bash
ssh -i /home/einfochips/.ssh/k8s-key ubuntu@<MASTER_PUBLIC_IP>
```

---

## Verify Kubernetes

Run on master node:

```bash
kubectl get nodes
```

```bash
kubectl get pods -A
```

---

## Verify ModernChair app

Run on master node:

```bash
kubectl get all -n modernchair
```

```bash
helm list -n modernchair
```

---

# 9. Access ModernChair Website

## Option 1: Port Forward

SSH into master:

```bash
ssh -i /home/einfochips/.ssh/k8s-key ubuntu@<MASTER_PUBLIC_IP>
```

Run:

```bash
kubectl port-forward -n modernchair svc/modernchair 8080:80 --address 0.0.0.0
```

Open in browser:

```text
http://<MASTER_PUBLIC_IP>:8080
```

---

## Option 2: NodePort

Run on master:

```bash
kubectl patch svc modernchair -n modernchair \
  -p '{"spec":{"type":"NodePort"}}'
```

Get NodePort:

```bash
kubectl get svc modernchair -n modernchair
```

Open in browser:

```text
http://<MASTER_PUBLIC_IP>:<NODE_PORT>
```

---

# 10. Cleanup Commands

## Destroy using GitHub Actions

Run workflow with:

```text
destroy
```

---

## Manual cleanup if required

List old EC2 instances:

```bash
aws ec2 describe-instances \
  --region ap-south-1 \
  --filters "Name=tag:Project,Values=terraform-ansible-k8s" "Name=instance-state-name,Values=running,pending,stopped" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text
```

Terminate instances:

```bash
aws ec2 terminate-instances \
  --region ap-south-1 \
  --instance-ids <INSTANCE_ID_1> <INSTANCE_ID_2>
```

Delete key pair:

```bash
aws ec2 delete-key-pair \
  --region ap-south-1 \
  --key-name k8s-key
```

Find security group:

```bash
aws ec2 describe-security-groups \
  --region ap-south-1 \
  --filters "Name=group-name,Values=terraform-ansible-k8s-sg" "Name=vpc-id,Values=vpc-3973fe50" \
  --query "SecurityGroups[*].GroupId" \
  --output text
```

Delete security group:

```bash
aws ec2 delete-security-group \
  --region ap-south-1 \
  --group-id <SECURITY_GROUP_ID>
```

---

# 11. Security Notes

Permanent ingress is allowed only from company-approved CIDR ranges:

```text
182.76.141.104/29
115.112.142.32/29
14.97.73.248/29
```

During deployment, the workflow temporarily allows SSH from the current GitHub runner public IP using `/32`.

After Ansible execution, the temporary GitHub runner SSH rule is revoked automatically.

SSH is not opened to:

```text
0.0.0.0/0
```

---

# 12. Task Completion Status

```text
Terraform infrastructure provisioning: Completed
GitHub Actions workflow automation: Completed
Temporary SSH rule handling: Completed
Ansible Kubernetes setup: Completed
Worker node join: Completed
Helm installation: Completed
ModernChair deployment: Completed
Website access verification: Completed
```
