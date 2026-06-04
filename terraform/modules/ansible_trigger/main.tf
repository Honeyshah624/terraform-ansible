resource "local_file" "inventory" {
  filename = var.inventory_output_path

  content = templatefile(var.inventory_template_path, {
    master_public_ip  = var.master_public_ip
    worker_private_ip = var.worker_private_ip
    private_key_path  = var.private_key_path
  })
}

resource "null_resource" "run_ansible" {
  depends_on = [
    local_file.inventory
  ]

  triggers = {
    master_instance_id = var.master_instance_id
    worker_instance_id = var.worker_instance_id
    inventory_sha1     = local_file.inventory.id
  }

  provisioner "local-exec" {
    command = <<EOT
echo "Waiting for master EC2 status checks..."

aws ec2 wait instance-status-ok \
  --region ${var.region} \
  --instance-ids ${var.master_instance_id}

echo "Master EC2 status checks passed."
echo "Master public IP: ${var.master_public_ip}"
echo "Waiting for master SSH to become ready..."

MASTER_READY=false

for i in $(seq 1 40); do
  if ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=10 \
    -i ${var.private_key_path} \
    ubuntu@${var.master_public_ip} "echo master-ssh-ready"; then
      MASTER_READY=true
      break
  fi

  echo "Master SSH not ready yet... attempt $i/40"
  sleep 15
done

if [ "$MASTER_READY" != "true" ]; then
  echo "ERROR: Master SSH is not reachable after waiting."
  echo "Check security group, public IP, subnet route table, NACL, and company network."
  exit 1
fi

cd ${var.ansible_dir}

echo "Testing Ansible connectivity..."
ANSIBLE_HOST_KEY_CHECKING=False ansible all -i inventory.ini -m ping

echo "Running Kubernetes installation playbook..."
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini site.yml
EOT
  }
}