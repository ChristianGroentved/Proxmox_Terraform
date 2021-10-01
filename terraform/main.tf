resource "proxmox_vm_qemu" "k3s_server" {
  count       = 1
  name        = "kubernetes-master-${count.index}"
  target_node = "proxmox"

  clone = "ubuntu-2004-cloudinit-template"

  os_type  = "cloud-init"
  cores    = 2
  sockets  = "1"
  cpu      = "host"
  memory   = 2048
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    size         = 20
    type         = "scsi"
    storage      = "local-lvm"
    storage_type = "lvm"
    iothread     = 1
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  # Cloud Init Settings
  ipconfig0 = "ip=192.168.1.${count.index + 3}/24,gw=192.168.1.1"

  sshkeys = <<EOF
  ${var.ssh_key}
  EOF
}

resource "proxmox_vm_qemu" "k3s_agent" {
  count       = 2
  name        = "kubernetes-node-${count.index}"
  target_node = "proxmox"

  clone = "ubuntu-2004-cloudinit-template"

  os_type  = "cloud-init"
  cores    = 2
  sockets  = "1"
  cpu      = "host"
  memory   = 2048
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    size         = 20
    type         = "scsi"
    storage      = "local-lvm"
    storage_type = "lvm"
    iothread     = 1
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  # Cloud Init Settings
  ipconfig0 = "ip=192.168.1.${count.index + 4}/24,gw=192.168.1.1"

  sshkeys = <<EOF
  ${var.ssh_key}
  EOF
}

resource "proxmox_vm_qemu" "storage" {
  count       = 1
  name        = "storage-node-${count.index}"
  target_node = "proxmox"

  clone = "ubuntu-2004-cloudinit-template"

  os_type  = "cloud-init"
  cores    = 2
  sockets  = "1"
  cpu      = "host"
  memory   = 2048
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    size         = 20
    type         = "scsi"
    storage      = "local-lvm"
    storage_type = "lvm"
    iothread     = 1
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  # Cloud Init Settings
  ipconfig0 = "ip=192.168.1.${count.index + 6}/24,gw=192.168.1.1"

  sshkeys = <<EOF
  ${var.ssh_key}
  EOF
}

