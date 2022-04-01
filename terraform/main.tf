terraform {
  required_version = ">= 0.13.0"

  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.9.6"
    }

    sops = {
      source = "carlpett/sops"
      version = "0.6.3"
    }
  }
}

provider "proxmox" {
    pm_tls_insecure = true
    pm_api_url = "https://192.168.1.2:8006/api2/json"
    pm_user = "root@pam"
    pm_password = data.sops_file.secrets.data["k8s.user_password"]
    pm_parallel = 4
}

provider "sops" {}
