# Consumed by the Ansible inventory (see inventory.tftpl). Nothing here is secret.

output "haproxy_public_ip" {
  description = "Public IP of HAProxy / jump host; SSH entry point and DB endpoint."
  value       = aws_instance.haproxy.public_ip
}

output "haproxy_public_dns" {
  description = "Public DNS name of HAProxy / jump host."
  value       = aws_instance.haproxy.public_dns
}

output "galera_private_ips" {
  description = "Galera node private IPs, keyed by AZ. Reached via the jump host; used to build wsrep_cluster_address."
  value       = { for az, node in aws_instance.galera : az => node.private_ip }
}
