resource "proxmox_vm_qemu" "kube-worker" {
  for_each = var.workers

  name        = each.key
  target_node = each.value.target_node
  agent       = 1
  clone       = var.common.clone
  vmid        = each.value.id
  memory      = each.value.memory
  cores       = each.value.cores
  vga {
    type = "qxl"
  }
  network {
    model    = "virtio"
    macaddr  = each.value.macaddr
    bridge   = "vmbr0"
    tag      = 40
    firewall = true
  }
  disk {
    type    = "scsi"
    storage = "local-lvm"
    size    = each.value.disk
    slot = 0
    iothread = 1
  }
  serial {
    id = 0
    type = "socket"
  }
  bootdisk     = "scsi0"
  scsihw       = "virtio-scsi-pci"
  os_type      = "cloud-init"
  ipconfig0    = "ip=${each.value.cidr},gw=${each.value.gw}"
  ciuser       = "ubuntu"
  cipassword   = data.sops_file.secrets.data["k8s.user_password"]
  sshkeys      = data.sops_file.secrets.data["k8s.ssh_key"]
}
