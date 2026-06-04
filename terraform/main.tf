data "aws_ami" "ubuntu_2204" {
  most_recent = true

  owners = ["099720109477"]

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

  project_name     = var.project_name
  vpc_id           = data.aws_vpc.default.id
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

module "ec2" {
  source = "./modules/ec2"

  project_name      = var.project_name
  ami_id            = data.aws_ami.ubuntu_2204.id
  instance_type     = var.instance_type
  subnet_id         = var.subnet_id
  security_group_id = module.security_group.security_group_id
  key_name          = module.keypair.key_name
}

module "ansible_trigger" {
  source = "./modules/ansible_trigger"

  region                  = var.region
  master_instance_id      = module.ec2.master_instance_id
  worker_instance_id      = module.ec2.worker_instance_id
  master_public_ip        = module.ec2.master_public_ip
  worker_private_ip       = module.ec2.worker_private_ip
  private_key_path        = var.private_key_path
  ansible_dir             = "${path.module}/../ansible"
  inventory_template_path = "${path.module}/../ansible/inventory.tpl"
  inventory_output_path   = "${path.module}/../ansible/inventory.ini"
}