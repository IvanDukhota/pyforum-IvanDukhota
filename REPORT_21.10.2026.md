# DevOps Report:

## General Information:

- Period: 16.10.2026 - 21.10.2026;
- Report date: 21.10.2026;
- Author: Ivan Dukhota;
- Project: PyForum;
- Goal: Migrate the entire application architecture to local VMs using Terraform in order to correctly complete Ansible and Load Balancing tasks.

## Summary:

This week a closed the CI/CD task (PR feature/ci-jenkins merged into main) and prepared the environment for the next two tasks.

Before starting with Ansible I had to decide where to run the app. Ansible works over SSH and sets up servers, so running everything on one server (my host machine) did not make much sense. The same problem goes with LB (Load Balancing) - with one server there is nothing to balance.

So I decided to split whole project into separate VMs: load balancer, two app servers, database and jenkins. First of all I thought about Vagrant and VirtualBox, but VirtualBox conflicts with KVM ob my host, so i chose libvirt. To create VMs i chose Terraform, because it is much more convenient to work with: i can describe all of them in code, see changes before applying, and the main reason - later use it as IaC solution in cloud. For the first setup of each VM i used cloud-init (user, SSH key, static IP).

After all those actions 5 VMs are up and reachable by SSH. The app itself is not deployed on them yet, this will be done with Ansible in the next task.

## Goals:

- Main goal: prepare a local environment with separate VMs for the load balancer, app servers, database and Jenkins;
- Other goals: create tne VMs from code so they can be recreated at any time, SSH access by the key only, fixed IP for every VM.

## Architecture:

All VMs run on Ubuntu 24.04 in a private libvirt NAT network 10.10.10.0/24. They can reach the internet, but from outside they reachable only from my host. Login by SSH key as user devops.

| VM      | IP          | RAM / CPU / Disk   | Planned role |
| ------- | ----------- | ------------------ | ------------ |
| lb      | 10.10.10.10 | 512 MB / 1 / 10 GB | nginx, load balancer |
| app1    | 10.10.10.21 | 1 GB / 1 / 10 GB   | Django + gunicorn |
| app2    | 10.10.10.22 | 1 GB / 1 / 10 GB   | Django + gunicorn |
| db      | 10.10.10.30 | 1 GB / 1 / 10 GB   | PostgreSQL |
| jenkins | 10.10.10.40 | 4 GB / 2 / 30 GB   | Jenkins |

How it works:

- Terraform downloads the Ubuntu cloud image once and creates a small disk for every VM on top of it, so new VMs are created fast and do not take much space;
- For every VM Terraform builds a cloud-init ISO with the hostname, user, SSH key and static IP, and attaches it to the VM;
- On the first boot cloud-init reads the ISO and sets up the system;
- The code is in the branch feature/terraform-vms, folder infra/terraform. To add a new VM I only need to add one line with its name, IP and size.

## Task Completed:

| #   | Task | Status | Owner | Finished | Notes |
| --- | ---- | ------ | ----- | -------- | ----- |
| 1   | Merged PR #3 feature/ci-jenkins into main | Done | Ivan | 20.10.2026 | Implement a CI/CD is closed |
| 2   | Planned the order of the remaining tasks and the architecture | Done | Ivan | 20.10.2026 | Local VMs first, then k8s, then cloud |
| 3   | Installed libvirt, KVM tools and Ansible on the host | Done | Ivan | 20.10.2026 | - |
| 4   | Wrote Terraform code for the network, disks, cloud-init and VMs | Done | Ivan | 21.10.2026 | infra/terraform |
| 5   | Created 5 VMs and checked SSH, hostname, IP and sudo on each of them | Done | Ivan | 21.10.2026 | terraform plan shows no changes | 

## Results:

- What I did: Terraform code that creates 5 ready to use VMs with one command (terraform apply);
- What I achieved: a local environment that I can delete and recreate at any time, ready for Ansible.

## Problems and Solutions:

| #   | Problem | Solution | Status |
| --- | ------- | -------- | ------ |
| 1   | libvirt provider 0.9 has a new syntax, most examples on the internet are for 0.7/0.8 and do not work | Wrote the code using the provider schema for 0.9 | Done |
| 2   | VM could not start: Permission denied on the base image (AppArmor on Ubuntu) | Attached disks by file path (source.file) instead of pool volume | Done |
| 3   | Terraform 1.16.1 crashed during apply, two resources were created but not saved in state | Removed them with virsh and ran apply with -parallelism=1 | Done |
| 4   | Terraform tried to change cloud-init volumes on every run | Set the volume format to iso, as libvirt detects it | Done |
| 5   | VirtualBox conflicts with KVM | Used libvirt/KVM only | Done |

## Next Steps:

- Open PR feature/terraform-vms into main;
- Implement Automatisation Setup a Webapp (Ansible);
- Setup Load Balancing for Webapp.

## Tools and Technologies Used:

- Ubuntu 26.04: host OS;
- KVM, QEMU, libvirt: virtualization;
- Terraform 1.16 with dmacvicar/libvirt 0.9.9: infrastructure as code;
- cloud-init: first setup of the VMs;
- Ubuntu 24.04 cloud image: OS on the VMs.

## Comments and Conclusions:

Terraform here is used only for local VMs. I will come back to it in the task Implement Infrastructure as Code, when the project moves to the cloud.

## Appendix and Resources:

- libvirt provider for Terraform (0.9.9): https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.9/docs
- libvirt: https://libvirt.org/

