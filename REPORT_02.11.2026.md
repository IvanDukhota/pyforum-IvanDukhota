# DevOps Report:

## General Information:

- Period: 29.10.2026 - 02.11.2026;
- Report date: 02.11.2026;
- Author: Ivan Dukhota;
- Project: PyForum;
- Goal: Jenkins on a separate VM and artifact management;

## Summary:

I moved Jenkins from a Docker container on my host to a separate VM. Jenkins is installed by Ansible and configured as code (JCasC): admin user, credentials and the pipeline job are created automatically.

The app servers do not build the app from source anymore. Jenkins pushes a Docker image to Docker Hub with the short commit SHA as a tag, and Ansible runs this image on app1 and app2. The tag to deploy is set in one variable.

The pipeline has a new Cleanup stage. It keeps the last 10 SHA tags on Docker Hub and deletes older ones.

## Goals:

- Main goal: images in a registry with clear versions, app servers run a fixed image version;
- Other goals: Jenkins on its own VM, Jenkins setup without manual steps, old tags are deleted.

## Architecture:

Jenkins on the jenkins VM builds and tests the app, then pushes the image lubernen/pyforum:<sha> to Docker Hub. Ansible runs this image as a container on app1 and app2. nginx on lb balances requests between them, the database is PostgreSQL on db.

| VM      | IP          | What runs there | Open ports |
| ------- | ----------- | --------------- | ---------- |
| lb      | 10.10.10.10 | nginx | 22 from host, 80 |
| app1    | 10.10.10.21 | Docker container lubernen/pyforum:<sha> | 22 from host, 8000 from lb only |
| app2    | 10.10.10.22 | Docker container lubernen/pyforum:<sha> | 22 from host, 8000 from lb only |
| db      | 10.10.10.30 | PostgreSQL 16, backup timer | 22 from host, 5432 from app1 and app2 only |
| jenkins | 10.10.10.40 | Jenkins 2.580.2, Docker | 22 from host, 8080 from host only |

## Task Completed:

| #   | Task | Status | Owner | Finished | Notes |
| --- | ---- | ------ | ----- | -------- | ----- |
| 1   | Jenkins on VM | Done | Ivan | 29.10.2026 | Ansible roles docker and jenkins |
| 2   | Jenkins configuration as code | Done | Ivan | 29.10.2026 | JCasC + Job DSL, secrets in Ansible Vault |
| 3   | App servers run image from Docker Hub | Done | Ivan | 01.11.2026 | Tag by commit SHA, variable app_image_tag |
| 4   | Tag retention | Done | Ivan | 02.11.2026 | Cleanup stage, parameter KEEP_TAGS (default 10) |
| 5   | PR feature/jenkins-vm | Done | Ivan | 02.11.2026 | Artifact Management |

## Results:

- What I did: Jenkins on a VM with Ansible and JCasC, deploy of the app from a Docker image by commit SHA, tag retention on Docker Hub;
- What I achieved: every build has an image with a known version, app servers run a fixed version, and it is easy to go back to an older one by changing the tag.

How I tested retention: there were 4 SHA tags on Docker Hub. I ran the pipeline with KEEP_TAGS=3. Only the oldest tag was deleted, the deployed tag stayed.

## Problems and Solutions:

| #   | Problem | Solution | Status |
| --- | ------- | -------- | ------ |
| 1   | With -p 8000:8000 Docker adds its own iptables rules, and port 8000 was open to everyone, not only to lb | The container uses network_mode host, so ufw rules work again | Done |
| 2   | First run of the Cleanup stage failed: "set: Illegal option -o pipefail" | Jenkins sh uses /bin/sh. The script now starts with #!/bin/bash | Done |
| 3   | The env file for CI did not have all variables that settings.py requires | Added the missing variables before the first build | Done |
| 4   | Jenkins did not start a build after the merge to main (pollSCM) | Job DSL creates the job again on each Jenkins restart, without the trigger from the Jenkinsfile. The trigger will be added to the JCasC config | Open |

## Next Steps:

- Add the pollSCM trigger to the JCasC config;
- Implement CCI (Continuous Code Inspection);
- Scanning images and dependencies in CI/CD.

## Tools and Technologies Used:

- Jenkins 2.580.2: JCasC, Job DSL, declarative pipeline;
- Ansible: roles docker, jenkins, app, Ansible Vault, community.docker;
- Docker Hub: registry, Hub API for tag cleanup;
- curl and jq: Docker Hub API in the Cleanup stage;
- Terraform + libvirt: VMs.

## Comments and Conclusions:

The Artifact Management task is done. Jenkins now runs on its own VM and is fully configured by Ansible.