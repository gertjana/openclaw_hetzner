terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

data "hcloud_server_type" "selected" {
  name = var.server_type
}

data "hcloud_location" "selected" {
  name = var.location
}
