[master]
${master_public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${private_key_path} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=30'

[workers]
${worker_public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${private_key_path} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=30'

[k8s_cluster:children]
master
workers