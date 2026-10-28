# DevOps Report:

## General Information:

- Period: 22.10.2026 - 28.10.2026;
- Report date: 28.10.2026;
- Author: Ivan Dukhota;
- Project: PyForum;
- Goal: Deploy application on local VMs with Ansible;

## Summary:
Last week I created VMs with Terraform. The reason was simple: Ansible configures servers over SSH, and with everything running on my host there was nothing to configure. Also, for the Load Balancing task I need more than one app server. Terraform lets me describe all VMs in code and recreate them with one command, and later I will use it in the cloud. This week PR feature/terraform-vms was merged into main.

After that I started with Ansible. I wrote 4 roles: common (base packages and firewall), postgres (database, dump restore and daily backups), app (Django with gunicorn) and loadbalancer (nginx). Passwords and the Django secret key are stored in Ansible Vault.

Now one command (ansible-playbook site.yml) sets up lb, app1 and db, and the site opens in the browser at http://10.10.10.10. The second run changes nothing. PR feature/ansible was merged into main.

## Goals:

- Main goal: deploy the app on separate VMs with Ansible;
- Other goals: keep secrets out of the repo in plain text, allow access between VMs only where it is needed, set up database backups.

## Architecture:

User opens http://10.10.10.10, nginx on lb sends the request to gunicorn on app1, and app1 works with PostgreSQL on db. Static files are served by the app (whitenoise), media files by nginx on lb.

| VM   | IP          | What runs there | Open ports |
| ---- | ----------- | --------------- | ---------- |
| lb   | 10.10.10.10 | nginx | 22 from host, 80 |
| app1 | 10.10.10.21 | Django + gunicorn (systemd) | 22 from host, 8000 from lb only |
| db   | 10.10.10.30 | PostgreSQL 16, backup timer | 22 from host, 5432 from app1 only |

app2 and jenkins VMs exist but are not used yet: app2 is for the Load Balancing task, Jenkins will move to its VM later, in one of the CI tasks.

## Tasks Completed:

| #   | Task | Status | Owner | Finished | Notes |
| --- | ---- | ------ | ----- | -------- | ----- |
| 1   | Merged PR #4 feature/terraform-vms into main | Done | Ivan | 22.10.2026 | - |
| 2   | Ansible config and inventory | Done | Ivan | 22.10.2026 | infra/ansible |
| 3   | Role common | Done | Ivan | 22.10.2026 | Packages, ufw |
| 4   | Role postgres with Vault and backups | Done | Ivan | 27.10.2026 | Backup every day at 12:00, kept 7 days |
| 5   | Role app | Done | Ivan | 27.10.2026 | Python 3.11 venv, gunicorn as systemd service |
| 6   | Role loadbalancer | Done | Ivan | 28.10.2026 | nginx reverse proxy |
| 7   | Merged PR #5 feature/ansible into main | Done | Ivan | 28.10.2026 | Implement Automatisation Setup a Webapp is closed |

## Results:

- What I did: Ansible playbook with 4 roles that deploys the whole app on VMs;
- What I achieved: the app works on separate VMs, login works, the setup can be repeated at any time with one command.

## Problems and Solutions:

| #   | Problem | Solution | Status |
| --- | ------- | -------- | ------ |
| 1   | Pillow 10.0.0 has no build for Python 3.12 (Ubuntu 24.04 default) | Installed Python 3.11 with uv and created venv with it | Done |
| 2   | Database dump has ALTER ... OWNER TO postgres, so tables belonged to the wrong user | Removed these lines during copy and restored the dump as app user | Done |
| 3   | Tasks with become_user failed without permissions on temp files | Installed acl package | Done |
| 4   | Migration files are in .gitignore, so migrate does nothing | Schema comes from the dump for now | Open |
| 5   | collectstatic always showed changed | Used changed_when based on its output | Done |
| 6   | New media files uploaded by users are saved on app1, but nginx serves media from lb | Accepted for now, will move media to S3 in the cloud | Open |
| 7   | Only direct dependencies are pinned in requirements.txt | Noted, will fix later | Open |

## Next Steps:

- Setup Load Balancing for Webapp (add app2, test failover and sessions);
- Artifact Management.

## Tools and Technologies Used:

- Ansible core 2.21 with community.general and community.postgresql;
- Ansible Vault: secrets;
- nginx 1.24: reverse proxy, media files;
- gunicorn + systemd: running the app;
- PostgreSQL 16: database, pg_dump with systemd timer for backups;
- uv: Python 3.11 and venv;
- ufw: firewall on VMs;
- Terraform + libvirt: VMs (from last week).

## Comments and Conclusions:

The Ansible task is closed. Right now nginx sends traffic to one app server only, real balancing will be done in the next task.

## Appendix and Resources:

- Ansible documentation: https://docs.ansible.com/
- Ansible Vault: https://docs.ansible.com/ansible/latest/vault_guide/index.html