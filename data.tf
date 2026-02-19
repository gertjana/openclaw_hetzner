data "hcloud_server_type" "selected" {
  name = var.server_type
}

data "hcloud_location" "selected" {
  name = var.location
}
