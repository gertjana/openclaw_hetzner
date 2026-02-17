variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "server_name" {
  description = "Server hostname"
  type        = string
  default     = "openclaw-vps"
}

variable "server_type" {
  description = "Hetzner server type (cx23 = 2 vCPU, 4GB RAM)"
  type        = string
  default     = "cx23"
}

variable "image" {
  description = "OS image"
  type        = string
  default     = "ubuntu-24.04"
}

variable "location" {
  description = "Hetzner datacenter"
  type        = string
  default     = "nbg1"  # Nuremberg, DE
}

variable "ssh_public_key" {
  description = "SSH public key for access"
  type        = string
}

variable "ssh_keys" {
  description = "Additional SSH key IDs"
  type        = list(string)
  default     = []
}

variable "username" {
  description = "Non-root user to create"
  type        = string
  default     = "openclaw"
}

variable "tailscale_auth_key" {
  description = "Tailscale auth key (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "allowed_ssh_ips" {
  description = "IPs allowed to SSH (use your static IP or VPN range)"
  type        = list(string)
  default     = []  # Empty = SSH only via Tailscale if enabled
}

variable "environment" {
  description = "Environment label"
  type        = string
  default     = "production"
}
