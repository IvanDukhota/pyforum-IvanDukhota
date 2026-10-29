# DevOps Report:

## General Information:

- Period: 28.10.2026 - 29.10.2026;
- Report date: 29.10.2026;
- Author: Ivan Dukhota;
- Project: PyForum;
- Goal: Load balancing between two app servers;

## Summary:

I added the second app server (app2) and set up load balancing in nginx on lb. Both app servers are deployed by the same Ansible playbook.

nginx uses least_conn. If one app server is down, nginx sends requests to the other one. Login sessions are stored in the database, so a user stays logged in when requests go to a different app server.

The playbook now updates app servers one by one and checks each one before going to the next, so the site keeps working during an update.

## Goals:

- Main goal: two app servers behind nginx with load balancing;
- Other goals: failover when one app server is down, sessions work on both servers, update without downtime.

## Architecture:

User opens http://10.10.10.10, nginx on lb sends the request to gunicorn on app1 or app2, and both work with PostgreSQL on db. Static files are served by the app (whitenoise), media files by nginx on lb.

| VM   | IP          | What runs there | Open ports |
| ---- | ----------- | --------------- | ---------- |
| lb   | 10.10.10.10 | nginx | 22 from host, 80 |
| app1 | 10.10.10.21 | Django + gunicorn (systemd) | 22 from host, 8000 from lb only |
| app2 | 10.10.10.22 | Django + gunicorn (systemd) | 22 from host, 8000 from lb only |
| db   | 10.10.10.30 | PostgreSQL 16, backup timer | 22 from host, 5432 from app1 and app2 only |

## Task Completed:

| #   | Task | Status | Owner | Finished | Notes |
| --- | ---- | ------ | ----- | -------- | ----- |
| 1   | Added app2 to inventory | Done | Ivan | 28.10.2026 | Deployed with site.yml, no role changes |
| 2   | Balancing method | Done | Ivan | 28.10.2026 | least_conn by default, variable lb_method |
| 3   | Failover | Done | Ivan | 28.10.2026 | max_fails 3, fail_timeout 10s, connect timeout 2s |
| 4   | Sessions between app servers | Done | Ivan | 28.10.2026 | Sessions in DB, checked in browser |
| 5   | Rolling update | Done | Ivan | 28.10.2026 | serial 1 + health check |
| 6   | PR feature/load-balancing | Done | Ivan | 29.10.2026 | Setup Load Balancing for Webapp |

## Results:

- What I did: second app server, load balancing, failover and rolling update with Ansible;
- What I achieved: the site works when one app server is down and during updates.

How I tested failover: suspended app1 with virsh and sent requests with curl. All answers were 200. The X-Upstream header showed that after 3 failed attempts to app1 nginx sent all requests to app2.

## Problems and Solutions:

| #   | Problem | Solution | Status |
| --- | ------- | -------- | ------ |
| 1   | In one test app1 was excluded after only one timeout, not after 3 | nginx resets the fail counter only after a successful response. The counter was left from the previous test. After nginx reload there were exactly 3 failed attempts | Done |
| 2   | Message "upstream server temporarily disabled" is not in error.log | It has warn level, and error_log uses the default error level. Not changed | Done |
| 3   | 404 on /media/logo/test.jpeg in nginx log | Bug in the app: profiles/views.py always uses the logo/ folder for partner images, but some images are in image/. | Open |

## Next Steps:

- Artifact Management;
- Move Jenkins to its VM.

## Tools and Technologies Used:

- Ansible: inventory, serial, max_fail_percentage, uri module;
- nginx 1.24: upstream, least_conn, max_fails, proxy_next_upstream;
- virsh and curl: failover tests;
- Terraform + libvirt: VMs.

## Comments and Conclusions:

The Load Balancing task is done. No new roles were needed. I changed the inventory, nginx settings, and added rolling update to the playbook.