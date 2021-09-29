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


```
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
```

## 2. Define virtual machine
Here I define the virtual machine which i'll be using as a template. The following command creates a new VM with the id 9000 (these has to be unique in Proxmox), 2 gigabyte of ram and a bridge network using the virtio controller

```
qm create 9000 --name "ubuntu-2004-cloudinit-template" --memory 2048 --net0 virtio,bridge=vmbr0
```

## 3. Import disk image to local Proxmox storage

The commandline utility uploads the image in the local Proxmox storage and assigns a unique name (for the virtual machine with the id 9000) to it. In this case we're getting the name "vm-9000-disk-0"


```
qm importdisk 9000 focal-server-cloudimg-amd64.img local-lvm
```

## 4. Configure VM to use uploaded image

```
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
```

## 5. Add Cloud-init image as CD-Rom to VM

```
qm set 9000 --ide2 local-lvm:cloudinit
```
This is important, because it allows you to change the settings. However these should not be changed as of yet. Because this is only a template and we will change the later.

## 6. Restrict VM to boot from Cloud-init image only


```
qm set 9000 --boot c --bootdisk scsi0
```
## 7. Add serial console to VM, this is needed for some Cloud-init distributions, such as Ubuntu)


```
qm set 9000 --serial0 socket --vga serial0
```

## 8. Create template


```
qm template 9000
```
The following is just for testing, they should not be run, since we are trying to get, Terraform to do all the heavy lifting.

## 9. Create a VM from template
With this template you can clone as many VM as you like and change the Cloud-init parameters for your needs. 

```
qm clone 9000 100 --name my-virtual-machine
```

We created a new VM with the unique id 100 and the name "my-virtual-machine". Now we can change the Cloud-init settings either in the UI or with the qm command


```
qm set 100 --sshkey ~/.ssh/id_rsa.pub
qm set 100 --ipconfig0 ip=192.168.1.5/24,gw=192.168.1.1
```

# Setup Terraform 
In this homebrew is being used as a means for installing terraform

## 1. install Terraform
```
brew install terraform
```

You can check the version with following 

```
terraform version
```
## 2. install Terraform provider
The terraform provider is not a default one, but a 3rd party provider. This can be installed in the following manner

create a directory terrraform-blog and tow files main.tf and vars.rf
```shell
mkdir terraform-blog && cd terraform-blog
touch main.tf vars.tf
```
Main content goes in main.tf and variables will go in vars.tf. First we will add the bare minimum. We need to tell Terraform to use a provider, which is the term they use for the connector to the entity Terraform will be interacting with. Since we are using Proxmox we need to use the Proxmox provider. We just need to specify the name and version, then Terraform grabs it from github and installs it. I have used the[Telmate Proxmox provider](https://github.com/Telmate/terraform-provider-proxmox)
```shell
vim main.tf
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
