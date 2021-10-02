variable "pm_api_url" {
  type        = string
  description = "Adresse for the Proxmox server"
  default     = "https://192.168.1.2:8006/api2/json"
}

variable "pm_user" {
  type        = string
  description = "Proxmox user"
  sensitive   = true
}

variable "pm_password" {
  type        = string
  description = "The password for the Proxmox user"
  sensitive   = true
}

variable "ssh_key" {
  type        = string
  description = "Public ssh key"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9LTfT5vVTICTLhGjRJGlldMi6c0D3zp73KJAvWXQQtSDODtYeZlU1LE2n4/0/jxaA8Q1Inp4V5reT2PM3yjVdjHajRF7mPS8aj9n2xvYZvsy8P4PyX+9NjX7qp/CzNJWxJSjtTKIs9OK6/HYJkFxFLGQoQTL3lVLYPCkuFU6Wl6ocWZADxvO5G19+6mAlEXOCScwvQDagfrMOonMYYUs024H3c60oqh3BvL8FGuphldPCgIfjkMfOo16yPssq63Gcj+LO7JOl4EAeDpbc6F2WTxoZGK0UuW6+mv5Btxzp/nMOn8ZZFjDzOrNY/6k6bYKLuVrzopIsMIk/UQbXXWnP Kingofhkb@Christians-MBP"
}

