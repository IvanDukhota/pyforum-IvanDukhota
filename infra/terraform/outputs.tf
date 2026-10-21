output "vm_ips" {
  description = "Static IP of each VM"
  value       = { for name, vm in local.vms : name => vm.ip }
}

output "ssh_commands" {
  description = "SSH commands"
  value       = { for name, vm in local.vms : name => "ssh ${var.ssh_user}@${vm.ip}" }
}
