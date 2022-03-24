provider "libvirt" {
  uri = "qemu:///system"
}

locals {
  mac_dc1       = "50:73:0F:31:81:E1"
  mac_desktop12 = "50:73:0F:31:81:E2"
  mac_graylog   = "50:73:0F:31:81:F1"
}

resource "libvirt_network" "honeypot" {
  name      = "honeypot"
  mode      = "nat"
  bridge    = "honeybr0"
  addresses = ["192.168.3.0/24"]
  dhcp {
    enabled = true
  }
  dns {
    enabled = true
    forwarders {
      address = "192.168.3.100"
      domain = "local"
    }
  }

  xml {
    xslt = file("network-dhcp-lease.xsl")
  }

  provisioner "local-exec" {
    command = "/usr/bin/sudo /usr/sbin/iptables -I FORWARD -j DROP -i honeybr0 -d 192.168.0.0/16; /usr/bin/sudo /usr/sbin/iptables -I FORWARD -j ACCEPT -i honeybr0 -o honeybr0"
  }
  provisioner "local-exec" {
    command = "/usr/bin/sudo /usr/sbin/iptables -D FORWARD -j DROP -i honeybr0 -d 192.168.0.0/16; /usr/bin/sudo /usr/sbin/iptables -D FORWARD -j ACCEPT -i honeybr0 -o honeybr0"
    when    = destroy
  }
}

resource "libvirt_pool" "honeypot" {
  name = "honeypot-pool"
  type = "dir"
  path = "/mnt/archive01/vm/honeypot-pool"
}

resource "libvirt_volume" "dc1-vol" {
  pool   = libvirt_pool.honeypot.name
  name   = "dc1-vol"
  source = "../packer/output_win2016/win2016"
}

resource "libvirt_volume" "desktop12-vol" {
  pool   = libvirt_pool.honeypot.name
  name   = "desktop12-vol"
  source = "../packer/output_win10/win10"
}

resource "libvirt_volume" "graylog-vol" {
  pool   = libvirt_pool.honeypot.name
  name   = "graylog-vol"
  source = "../packer/output_graylog/graylog"
}

resource "libvirt_domain" "dc1-dom" {
  provider = libvirt
  name     = "h-dc1"
  memory   = "4096"
  vcpu     = 4

  disk {
    volume_id = libvirt_volume.dc1-vol.id
  }

  network_interface {
    network_id     = libvirt_network.honeypot.id
    hostname       = "dc1"
    mac            = local.mac_dc1
  }

  xml {
    xslt = file("timer-patch.xsl")
  }
}

resource "libvirt_domain" "desktop12-dom" {
  provider = libvirt
  name     = "h-desktop12"
  memory   = "4096"
  vcpu     = 4

  disk {
    volume_id = libvirt_volume.desktop12-vol.id
  }

  network_interface {
    network_id     = libvirt_network.honeypot.id
    hostname       = "desktop12"
    mac            = local.mac_desktop12
  }

  xml {
    xslt = file("timer-patch.xsl")
  }
}

resource "libvirt_domain" "graylog-dom" {
  provider = libvirt
  name     = "h-graylog"
  memory   = "4096"
  vcpu     = 4

  disk {
    volume_id = libvirt_volume.graylog-vol.id
  }

  network_interface {
    network_id     = libvirt_network.honeypot.id
    hostname       = "graylog"
    mac            = local.mac_graylog
  }

  xml {
    xslt = file("timer-patch.xsl")
  }
}

terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.14"
    }
  }
}
