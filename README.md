
# Fully Automated Kubernetes Cluster Provisioning with Terraform, Ansible and Helm

## Project Overview

This project provisions a Kubernetes cluster on AWS EC2 and deploys the ModernChair application automatically.

Running:

```bash
terraform apply
```

will:

```text
1. Create AWS infrastructure
2. Create 1 Kubernetes master node
3. Create 1 Kubernetes worker node
4. Generate Ansible inventory automatically
5. Trigger Ansible automatically
6. Install Kubernetes using kubeadm
7. Join worker node to the cluster
8. Install Helm
9. Deploy ModernChair application using Helm
10. Access the website locally using kubectl port-forward
```

---

## Architecture

```text
Local Machine
   |
   | terraform apply
   v
Terraform
   |
   | creates AWS resources
   v
AWS EC2
   |
   | master + worker
   v
Ansible
   |
   | installs Kubernetes
   v
Kubernetes Cluster
   |
   | Helm deploys app
   v
ModernChair Application
   |
   | kubectl port-forward
   v
Local Browser
```

---

## Final Workflow

```text
terraform apply
      |
      v
Terraform creates:
- AWS key pair
- Security group
- Master EC2
- Worker EC2
- Ansible inventory.ini

      |
      v
Terraform local-exec triggers Ansible

      |
      v
Ansible roles run:
- common
- master
- worker
- helm_app

      |
      v
Kubernetes cluster becomes ready

      |
      v
Helm deploys ModernChair app

      |
      v
Access app using localhost port-forward
```

---

## Project Structure

```text
terraform-ansible/
├── README.md
├── terraform/
│   ├── provider.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── outputs.tf
│   └── modules/
│       ├── keypair/
│       ├── security_group/
│       ├── ec2/
│       └── ansible_trigger/
├── ansible/
│   ├── ansible.cfg
│   ├── inventory.ini
│   ├── inventory.tpl
│   ├── site.yml
│   ├── group_vars/
│   │   └── all.yml
│   └── roles/
│       ├── common/
│       ├── master/
│       ├── worker/
│       └── helm_app/
└── helm/
    └── modernchair/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            └── service.yaml
```

---

## Tools Used

```text
Terraform  - Infrastructure provisioning
Ansible    - Kubernetes installation and configuration
kubeadm    - Kubernetes cluster initialization
containerd - Container runtime
Calico     - Kubernetes pod networking
Helm       - Application deployment
kubectl    - Kubernetes verification and port-forward
AWS EC2    - Master and worker nodes
```

---

## Prerequisites

Install these tools on local Ubuntu machine:

```bash
terraform -version
ansible --version
aws --version
kubectl version --client
ssh -V
```

Configure AWS CLI:

```bash
aws configure
```

Verify AWS access:

```bash
aws sts get-caller-identity
```

---

## SSH Key Setup

Check SSH key:

```bash
ls -l /home/einfochips/.ssh/k8s-key
ls -l /home/einfochips/.ssh/k8s-key.pub
```

Set correct permission:

```bash
chmod 400 /home/einfochips/.ssh/k8s-key
```

---

## Check Current Public IP

Before running Terraform, check your current public IP:

```bash
curl ifconfig.me
```

Update `terraform/terraform.tfvars` if IP changes:

```hcl
allowed_ssh_cidr = "YOUR_PUBLIC_IP/32"
```

Example:

```hcl
allowed_ssh_cidr = "182.76.141.106/32"
```

Do not use:

```hcl
0.0.0.0/0
```

---

## Terraform Variables

Example `terraform.tfvars`:

```hcl
region = "ap-south-1"

project_name = "terraform-ansible-k8s"

instance_type = "t3.medium"

key_name = "k8s-key"

private_key_path = "/home/einfochips/.ssh/k8s-key"

public_key_path = "/home/einfochips/.ssh/k8s-key.pub"

allowed_ssh_cidr = "182.76.141.106/32"

subnet_id = "subnet-e3e72aae"
```

---

## Terraform Modules

### keypair module

Creates/imports AWS key pair using local public key.

```text
modules/keypair
```

### security_group module

Creates security group rules for:

```text
SSH                 22
Kubernetes API      6443
NodePort range      30000-32767
Internal traffic    self security group
Outbound traffic    internet access
```

### ec2 module

Creates:

```text
1 master EC2
1 worker EC2
```

### ansible_trigger module

Creates Ansible inventory and runs Ansible automatically using `local-exec`.

---

## Ansible Roles

### common role

Runs on both master and worker.

Installs and configures:

```text
containerd
kubeadm
kubelet
kubectl
kernel modules
sysctl networking
swap disable
```

### master role

Runs only on master.

Performs:

```text
kubeadm init
kubeconfig setup
Calico CNI installation
join command generation
```

### worker role

Runs only on worker.

Performs:

```text
kubeadm join
```

### helm_app role

Runs only on master.

Performs:

```text
Helm installation
Helm chart copy
Namespace creation
ModernChair app deployment
```

---

## Application Image

ModernChair app image used:

```text
honeyshah062/modernchair:latest
```

Helm values:

```yaml
image:
  repository: honeyshah062/modernchair
  tag: "latest"
  pullPolicy: Always

service:
  type: ClusterIP
  port: 80
  targetPort: 80
```

The application is deployed as `ClusterIP`, so it is not publicly exposed.

---

## Run Complete Automation

Go to Terraform folder:

```bash
cd ~/terraform-ansible/terraform
```

Initialize Terraform:

```bash
terraform init
```

Format files:

```bash
terraform fmt -recursive
```

Validate:

```bash
terraform validate
```

Check plan:

```bash
terraform plan
```

Apply:

```bash
terraform apply
```

Type:

```text
yes
```

---

## What Happens During terraform apply

```text
1. Terraform selects Ubuntu 22.04 AMI
2. Terraform creates/imports AWS key pair
3. Terraform creates security group
4. Terraform creates master EC2
5. Terraform creates worker EC2
6. Terraform generates ansible/inventory.ini
7. Terraform waits for master SSH
8. Terraform runs Ansible automatically
9. Ansible installs Kubernetes
10. Ansible joins worker node
11. Ansible installs Helm
12. Helm deploys ModernChair app
```

---

## Check Terraform Output

```bash
terraform output
```

Important outputs:

```text
master_public_ip
master_private_ip
worker_private_ip
security_group_id
ssh_master_command
ssh_worker_via_master_command
```

---

## Check Generated Inventory

```bash
cat ../ansible/inventory.ini
```

Expected:

```ini
[master]
MASTER_PUBLIC_IP ansible_user=ubuntu ...

[workers]
WORKER_PRIVATE_IP ansible_user=ubuntu ... ProxyCommand ...

[k8s_cluster:children]
master
workers
```

Worker is accessed through master using private IP.

---

## Test Ansible Connectivity

```bash
cd ~/terraform-ansible/ansible
ansible all -i inventory.ini -m ping
```

Expected:

```text
master SUCCESS ping pong
worker SUCCESS ping pong
```

---

## Verify Kubernetes Cluster

SSH into master:

```bash
cd ~/terraform-ansible/terraform
ssh -i /home/einfochips/.ssh/k8s-key ubuntu@$(terraform output -raw master_public_ip)
```

Check nodes:

```bash
kubectl get nodes
```

Expected:

```text
master   Ready   control-plane
worker   Ready   <none>
```

Check system pods:

```bash
kubectl get pods -A
```

Expected:

```text
All important pods Running
```

---

## Verify Helm Deployment

On master node:

```bash
helm list -A
```

Check app resources:

```bash
kubectl get all -n modernchair
```

Expected:

```text
deployment/modernchair   2/2
pods                     Running
service/modernchair      ClusterIP
```

Check image:

```bash
kubectl describe pod -n modernchair $(kubectl get pod -n modernchair -o jsonpath='{.items[0].metadata.name}') | grep -i image
```

Expected:

```text
honeyshah062/modernchair:latest
```

---

## Access Website Locally

Use SSH tunnel and port-forward.

From local terminal:

```bash
cd ~/terraform-ansible/terraform

ssh -i /home/einfochips/.ssh/k8s-key \
  -L 9090:127.0.0.1:9090 \
  ubuntu@$(terraform output -raw master_public_ip)
```

Inside master SSH session:

```bash
kubectl port-forward -n modernchair svc/modernchair 9090:80
```

Open browser on local machine:

```text
http://localhost:9090
```

---

## Useful Commands

Check cluster:

```bash
kubectl get nodes
kubectl get pods -A
```

Check app:

```bash
kubectl get all -n modernchair
kubectl get svc -n modernchair
kubectl get pods -n modernchair -o wide
```

Check Helm:

```bash
helm list -A
helm status modernchair -n modernchair
helm history modernchair -n modernchair
```

Upgrade Helm release:

```bash
helm upgrade modernchair /home/ubuntu/modernchair-chart -n modernchair
```

Rollback Helm release:

```bash
helm rollback modernchair 1 -n modernchair
```

Uninstall app:

```bash
helm uninstall modernchair -n modernchair
kubectl delete namespace modernchair
```

---

## Troubleshooting

### SSH timeout

Check current IP:

```bash
curl ifconfig.me
```

Check security group:

```bash
aws ec2 describe-security-groups \
  --region ap-south-1 \
  --group-ids $(terraform output -raw security_group_id) \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`22\`]" \
  --output json
```

### kubectl localhost:8080 error

Use kubeconfig explicitly:

```bash
kubectl --kubeconfig /home/ubuntu/.kube/config get nodes
```

### Helm chart path issue

Check local chart path:

```bash
ls -l ~/terraform-ansible/helm/modernchair
```

Check remote chart path on master:

```bash
ls -l /home/ubuntu/modernchair-chart
```

### Browser shows wrong page

Use port `9090` instead of `8080`:

```bash
kubectl port-forward -n modernchair svc/modernchair 9090:80
```

Open:

```text
http://localhost:9090
```

---

## Final Success Criteria

The task is complete when:

```bash
kubectl get nodes
```

shows:

```text
1 master Ready
1 worker Ready
```

and:

```bash
kubectl get all -n modernchair
```

shows:

```text
ModernChair pods Running
ModernChair service ClusterIP
```

and the website opens using:

```text
http://localhost:9090
```

---

## Final Summary

```text
Terraform provisions AWS infrastructure.
Ansible installs Kubernetes and Helm.
Helm deploys the ModernChair application.
kubectl port-forward provides secure local website access.
```
