# Proxmox_Terraform
This setup is taken directly from [Austin Pirvarnik](https://austinsnerdythings.com/2021/08/30/how-to-create-a-proxmox-ubuntu-cloud-init-image/) blog post. The reason I am doing this is to learn how to use Terraform and play with my homelab. The plan is to evantually provision k3s but for now I will settle with learning how to apply Terraform to my setup.

## Create a Proxmox Ubuntu cloud-init image
___
The background for creating this image is to enable Terraform to use it when creating VMs.

A quick summary:

1. Download a base Ubuntu cloud image
2. Install packages into the image
3. Create a Proxmox VM using the image
4. Convert it to a template
5. Clone the template into a full VM and set some parameters
6. Automate it so it runs on a regular basis

## 1. Download the base Ubuntu image
Ubunut provides base images which are updated on a regular basis [https://cloud-images.ubuntu.com/](https://cloud-images.ubuntu.com/). What I am after is the newest release of Ubuntu 20.04 Focal, which as of writing is the current Long Term Support version. And because Promox uses KVM, I am going to pull that image.


```shell
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
```

## 2. Define virtual machine
Here I define the virtual machine which i'll be using as a template. The following command creates a new VM with the id 9000 (these has to be unique in Proxmox), 2 gigabyte of ram and a bridge network using the virtio controller

```shell
qm create 9000 --name "ubuntu-2004-cloudinit-template" --memory 2048 --net0 virtio,bridge=vmbr0
```

## 3. Import disk image to local Proxmox storage

The commandline utility uploads the image in the local Proxmox storage and assigns a unique name (for the virtual machine with the id 9000) to it. In this case we're getting the name "vm-9000-disk-0"


```shell
qm importdisk 9000 focal-server-cloudimg-amd64.img local-lvm
```

## 4. Configure VM to use uploaded image

```shell
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
```

## 5. Add Cloud-init image as CD-Rom to VM

```shell
qm set 9000 --ide2 local-lvm:cloudinit
```
This is important, because it allows you to change the settings. However these should not be changed as of yet. Because this is only a template and we will change the later.

## 6. Restrict VM to boot from Cloud-init image only


```shell
qm set 9000 --boot c --bootdisk scsi0
```
## 7. Add serial console to VM, this is needed for some Cloud-init distributions, such as Ubuntu)


```shell
qm set 9000 --serial0 socket --vga serial0
```

## 8. Create template


```shell
qm template 9000
```
The following is just for testing, they should not be run, since we are trying to get, Terraform to do all the heavy lifting.

## 9. Create a VM from template
With this template you can clone as many VM as you like and change the Cloud-init parameters for your needs. 

```shell
qm clone 9000 100 --name my-virtual-machine
```

We created a new VM with the unique id 100 and the name "my-virtual-machine". Now we can change the Cloud-init settings either in the UI or with the qm command


```shell
qm set 100 --sshkey ~/.ssh/id_rsa.pub
qm set 100 --ipconfig0 ip=192.168.1.5/24,gw=192.168.1.1
```

# Setup Terraform 
In this homebrew is being used as a means for installing terraform

## 1. install Terraform

```shell
brew install terraform
```

You can check the version with following 

```shell
terraform version
```
## 2. install Terraform provider
The terraform provider is not a default one, but a 3rd party provider. This can be installed in the following manner

create a directory terrraform-blog and three files main.tf, vars.rf and providers.tf
```shell
mkdir terraform-blog && cd terraform-blog
touch main.tf vars.tf providers.tf
```
The main logic of Terraform, will go imto main.tf. Info and parameters will go into providers.tf. Finally variables will go in vars.tf. First we will add the bare minimum. We need to tell Terraform to use a provider, which is the term they use for the connector to the entity Terraform will be interacting with. Since we are using Proxmox we need to use the Proxmox provider. We just need to specify the name and version, then Terraform grabs it from github and installs it. I have used the[Telmate Proxmox provider](https://github.com/Telmate/terraform-provider-proxmox)

```shell
vim provider.tf
```

```shell
terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = ">= 2.8.0"
    }
  }
}
```

Save the file, an optinal step is to use the fmt command from Terraform, which reformats the file to fit with Terraform syntax, however this is not required.

```shell
terraform fmt main.tf
```
Now we can perform a Terraform init to initialize our plan. Which will force it to go out and grab the provider. If everthing is in ordre we will be informed that the provider installed and that Terraform has been initialized.

```shell
terraform init
```
## 3. Configure Proxmox provider
First we comfigure the connection settings for Proxmox. To improve readability we keep the variables in the vars.tf file and info on provider in provider.tf. First we start with the vars.tf 

```shell
variable "pm_api_url" {
  default = "https://"ip of your proxmox server":8006/api2/json"
}

variable "pm_user" {
default = "root@pam"
}

variable "pm_password" {
default = "my_password"
}
```

Add the following to the provider.tf file

```shell
provider "proxmox" {
  pm_parallel       = 1
  pm_tls_insecure   = true
  pm_api_url        = var.pm_api_url
  pm_password       = var.pm_password
  pm_user           = var.pm_user
}
```

## Configure the virtuel machines
Next we are going to configure our k3s-cluster server In this part you will have to adept the following parameters to your configuration.

* target_node (name of your proxmox instance)
* name (name of virtual server)
* clone (name of template in Proxmox)
* cores
* memory
* storage (the right storage pool in Proxmox)
* ipconfig0 (Use the right IP range for your servers - the count.index is necesarry if you have more than one server configured - like the k3s_agents in the example below)

The "ignore changes" lifecycle block is necessary, because Terraform likes to change the mac address on the second run

```shell
resource "proxmox_vm_qemu" "k3s_server" {
  count             = 1
  name              = "kubernetes-master-${count.index}"
  target_node       = "proxmox"

  clone             = "ubuntu-2004-cloudinit-template"

  os_type           = "cloud-init"
  cores             = 2
  sockets           = "1"
  cpu               = "host"
  memory            = 2048
  scsihw            = "virtio-scsi-pci"
  bootdisk          = "scsi0"

  disk {
    id              = 0
    size            = 20
    type            = "scsi"
    storage         = "local-lvm"
    storage_type    = "lvm"
    iothread        = true
  }

  network {
    id              = 0
    model           = "virtio"
    bridge          = "vmbr0"
  }

  lifecycle {
    ignore_changes  = [
      network,
    ]
  }

  # Cloud Init Settings
  ipconfig0         = "ip=192.168.2.11${count.index + 1}/24,gw=192.168.2.1"

  sshkeys = <<EOF
  ${var.ssh_key}
  EOF
}

resource "proxmox_vm_qemu" "k3s_agent" {
  count             = 2
  name              = "kubernetes-node-${count.index}"
  target_node       = "proxmox"

  clone             = "ubuntu-2004-cloudinit-template"

  os_type           = "cloud-init"
  cores             = 2
  sockets           = "1"
  cpu               = "host"
  memory            = 2048
  scsihw            = "virtio-scsi-pci"
  bootdisk          = "scsi0"

  disk {
    id              = 0
    size            = 20
    type            = "scsi"
    storage         = "local-lvm"
    storage_type    = "lvm"
    iothread        = true
  }

  network {
    id              = 0
    model           = "virtio"
    bridge          = "vmbr0"
  }

  lifecycle {
    ignore_changes  = [
      network,
    ]
  }

  # Cloud Init Settings
  ipconfig0         = "ip=192.168.2.12${count.index + 1}/24,gw=192.168.2.1"

  sshkeys = <<EOF
  ${var.ssh_key}
  EOF
}

resource "proxmox_vm_qemu" "storage" {
  count             = 1
  name              = "storage-node-${count.index}"
  target_node       = "proxmox"

  clone             = "ubuntu-2004-cloudinit-template"

  os_type           = "cloud-init"
  cores             = 2
  sockets           = "1"
  cpu               = "host"
  memory            = 2048
  scsihw            = "virtio-scsi-pci"
  bootdisk          = "scsi0"

  disk {
    id              = 0
    size            = 20
    type            = "scsi"
    storage         = "local-lvm"
    storage_type    = "lvm"
    iothread        = true
  }

  network {
    id              = 0
    model           = "virtio"
    bridge          = "vmbr0"
  }

  lifecycle {
    ignore_changes  = [
      network,
    ]
  }

  # Cloud Init Settings
  ipconfig0         = "ip=192.168.2.13${count.index + 1}/24,gw=192.168.2.1"

  sshkeys = <<EOF
  ${var.ssh_key}
  EOF
}
```

## Add ssh-pubkey for Cloud-Init
To get passwordless login (useful for tools like Ansible), create a variable with your ssh_key in the vars.tf file.

```shell
variable "ssh_key" {
  default = "ssh-rsa ..."
}
```

## Deployment time
Terraform has a simple but powerful deployment cycle, which consists of the following steps:

* Init - Initializes the Terraform project and install needed plugins, dependencies...
* Validate - Validates the syntax of the created Terraform .tf files
* Plan - Calculates the steps and changes to install/upgrade your infrastructure
* Apply - Applies the changes on the configured systems

If you try to skip a step for example start with terraform plan, Terraform inform you to initialize the project first:

