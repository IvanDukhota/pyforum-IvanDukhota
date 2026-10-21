locals {
  gateway = cidrhost(var.network_cidr, 1)
  prefix  = split("/", var.network_cidr)[1]

  apps = {
    for i in range(1, var.app_count + 1) :
    "app${i}" => { ip = cidrhost(var.network_cidr, 20 + i), memory = 1024, vcpu = 1, disk_gib = 10 }
  }

  vms = merge(
    {
      lb = { ip = cidrhost(var.network_cidr, 10), memory = 512, vcpu = 1, disk_gib = 10 }
      db = { ip = cidrhost(var.network_cidr, 30), memory = 1024, vcpu = 1, disk_gib = 10 }
    },
    local.apps,
  )
}

resource "libvirt_network" "main" {
  name      = var.project
  autostart = true

  forward = {
    mode = "nat"
  }

  bridge = {
    name = "virbr-${var.project}"
  }

  ips = [
    {
      address = local.gateway
      prefix  = local.prefix
    }
  ]
}

resource "libvirt_pool" "main" {
  name = var.project
  type = "dir"

  target = {
    path = "/var/lib/libvirt/images/${var.project}"
  }

  create = {
    build     = true
    start     = true
    autostart = true
  }
}

resource "libvirt_volume" "base" {
  name = "${var.project}-base.qcow2"
  pool = libvirt_pool.main.name

  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = var.image_url
    }
  }
}

resource "libvirt_volume" "disk" {
  for_each = local.vms

  name          = "${var.project}-${each.key}.qcow2"
  pool          = libvirt_pool.main.name
  capacity      = each.value.disk_gib
  capacity_unit = "GiB"

  target = {
    format = {
      type = "qcow2"
    }
  }

  backing_store = {
    path = libvirt_volume.base.path
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_cloudinit_disk" "seed" {
  for_each = local.vms

  name = "${var.project}-${each.key}-seed"

  meta_data = yamlencode({
    instance-id    = "${var.project}-${each.key}"
    local-hostname = each.key
  })

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    hostname       = each.key
    ssh_user       = var.ssh_user
    ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
  })

  network_config = yamlencode({
    version = 2
    ethernets = {
      primary = {
        match     = { name = "en*" }
        addresses = ["${each.value.ip}/${local.prefix}"]
        routes    = [{ to = "default", via = local.gateway }]
        nameservers = {
          addresses = [local.gateway]
        }
      }
    }
  })
}

resource "libvirt_volume" "seed" {
  for_each = local.vms

  name = "${var.project}-${each.key}-seed.iso"
  pool = libvirt_pool.main.name

  target = {
    format = {
      type = "iso"
    }
  }

  create = {
    content = {
      url = libvirt_cloudinit_disk.seed[each.key].path
    }
  }
}

resource "libvirt_domain" "vm" {
  for_each = local.vms

  name        = "${var.project}-${each.key}"
  type        = "kvm"
  memory      = each.value.memory
  memory_unit = "MiB"
  vcpu        = each.value.vcpu
  running     = true

  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    boot_devices = [{ dev = "hd" }]
  }

  features = {
    acpi = true
  }

  devices = {
    disks = [
      {
        source = {
          file = {
            file = libvirt_volume.disk[each.key].path
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
        driver = {
          name = "qemu"
          type = "qcow2"
        }
      },
      {
        device = "cdrom"
        source = {
          file = {
            file = libvirt_volume.seed[each.key].path
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
        driver = {
          name = "qemu"
          type = "raw"
        }
      },
    ]

    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = libvirt_network.main.name
          }
        }
      }
    ]

    serials = [
      {
        target = {
          port = 0
        }
      }
    ]

    consoles = [
      {
        target = {
          type = "serial"
          port = 0
        }
      }
    ]

    channels = [
      {
        source = {
          unix = {}
        }
        target = {
          virt_io = {
            name = "org.qemu.guest_agent.0"
          }
        }
      }
    ]

    graphics = [
      {
        vnc = {
          auto_port = true
          listen    = "127.0.0.1"
        }
      }
    ]
  }
}
