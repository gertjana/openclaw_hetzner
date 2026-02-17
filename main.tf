# SSH Key
resource "hcloud_ssh_key" "default" {
  name       = "${var.server_name}-ssh-key"
  public_key = var.ssh_public_key
}

# Cloud-init script
locals {
  user_data = templatefile("${path.module}/scripts/cloud-init.sh", {
    tailscale_auth_key = var.tailscale_auth_key
    username           = var.username
    ssh_public_key     = var.ssh_public_key
  })
}

# Server
resource "hcloud_server" "vps" {
  name        = var.server_name
  image       = var.image
  server_type = data.hcloud_server_type.selected.name
  location    = data.hcloud_location.selected.name
  ssh_keys    = concat([hcloud_ssh_key.default.id], var.ssh_keys)
  user_data   = local.user_data

  labels = {
    managed-by  = "terraform"
    environment = var.environment
    purpose     = "clawdbot"
  }
}

# Firewall – locked down by default
resource "hcloud_firewall" "vps" {
  name = "${var.server_name}-firewall"

  # SSH: Tailscale CGNAT range + explicit allowed IPs
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = var.tailscale_auth_key != "" ? concat(["100.64.0.0/10"], var.allowed_ssh_ips) : var.allowed_ssh_ips
    description = "SSH access"
  }

  # ICMP for diagnostics
  rule {
    direction   = "in"
    protocol    = "icmp"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "ICMP (ping)"
  }

  # Egress – allow all (Hetzner default, but explicit is better)
  rule {
    direction       = "out"
    protocol        = "tcp"
    port            = "1-65535"
    destination_ips = ["0.0.0.0/0", "::/0"]
    description     = "All TCP outbound"
  }

  rule {
    direction       = "out"
    protocol        = "udp"
    port            = "1-65535"
    destination_ips = ["0.0.0.0/0", "::/0"]
    description     = "All UDP outbound"
  }

  rule {
    direction       = "out"
    protocol        = "icmp"
    destination_ips = ["0.0.0.0/0", "::/0"]
    description     = "ICMP outbound"
  }
}

resource "hcloud_firewall_attachment" "vps" {
  firewall_id = hcloud_firewall.vps.id
  server_ids  = [hcloud_server.vps.id]
}
