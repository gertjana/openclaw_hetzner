output "server_ip" {
  description = "Public IPv4 address"
  value       = hcloud_server.vps.ipv4_address
}

output "server_ipv6" {
  description = "Public IPv6 address"
  value       = hcloud_server.vps.ipv6_address
}

output "ssh_command" {
  description = "SSH connection string"
  value       = "ssh ${var.username}@${hcloud_server.vps.ipv4_address}"
}
