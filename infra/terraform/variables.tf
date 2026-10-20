variable "project" {
  description = "Prefix for all libvirt resources"
  type        = string
  default     = "pyforum"
}

variable "network_cidr" {
  description = "Private network for all VMs"
  type        = string
  default     = "10.10.10.0/24"
}

variable "app_count" {
  description = "Number of application VMs"
  type        = number
  default     = 2
}

variable "image_url" {
  description = "Ubuntu cloud image used as base disk"
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "ssh_user" {
  description = "Admin user created by cloud-init"
  type        = string
  default     = "devops"
}

variable "ssh_public_key_path" {
  description = "Public key allowed to log in as ssh_user"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}
