# Renders terraform/inventory.tftpl into ansible/inventory.ini after apply.
# galera_private_ips is a map, so it renders in sorted AZ order; the galera role can
# treat groups['galera'][0] as the deterministic bootstrap node.
resource "local_file" "inventory" {
  filename = "${path.module}/../ansible/inventory.ini"

  content = templatefile("${path.module}/inventory.tftpl", {
    haproxy_ip         = aws_instance.haproxy.public_ip
    galera_private_ips = { for az, node in aws_instance.galera : az => node.private_ip }
    ssh_user           = "ubuntu" # Ubuntu AMI default login user
  })
}
