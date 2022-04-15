
variable "common" {
  type = map(string)
  default = {
    os_type       = "ubuntu"
    clone         = "ubuntu-20.04-cloudimg"
  }
}

variable "masters" {
  type = map(map(string))
  default = {
    k8s-master01 = {
      id          = 4010
      cidr        = "192.168.1.4/24"
      cores       = 2
      gw          = "192.168.1.1"
      macaddr     = "02:DE:4D:48:28:01"
      memory      = 4096
      disk        = "30G"
      target_node = "hkb-01"
    },
     k8s-master02 = {
      id          = 4011
      cidr        = "192.168.1.5/24"
      cores       = 2
      gw          = "192.168.1.1"
      macaddr     = "02:DE:4D:48:28:02"
      memory      = 4096
      disk        = "30G"
      target_node = "hkb-01"
    },
     k8s-master03 = {
      id          = 4012
      cidr        = "192.168.1.6/24"
      cores       = 2
      gw          = "192.168.1.1"
      macaddr     = "02:DE:4D:48:28:03"
      memory      = 4096
      disk        = "30G"
      target_node = "hkb-01"
    },
  }
}

variable "workers" {
  type = map(map(string))
  default = {
    k8s-worker01 = {
      id          = 4020
      cidr        = "192.168.1.7/24"
      cores       = 2
      gw          = "192.168.1.1"
      macaddr     = "02:DE:4D:48:28:0A"
      memory      = 4096
      disk        = "30G"
      target_node = "hkb-02"
    },
    k8s-worker02 = {
      id          = 4021
      cidr        = "192.168.1.8/24"
      cores       = 2
      gw          = "192.168.1.1"
      macaddr     = "02:DE:4D:48:28:0B"
      memory      = 4096
      disk        = "30G"
      target_node = "hkb-02"
    },
  }
}
