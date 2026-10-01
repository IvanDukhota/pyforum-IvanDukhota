# DevOps Report

## General Information:

- Period: 28.09.2026 - 01.10.2026
- Report date: 01.10.2026
- Author: Ivan Dukhota
- Project: PyForum
- Goal: Deploy the PyForum Django application natively on a Linux host with gunicorn, nginx and PostgreSQL.

## Summary:

This report covers the first task, Setup Webapp. I picked this project, studied its structure, and deployed it natively. The app runs as a systemd service under its own user with nginx in front and local PostgreSQL DB that was restored from project dump.

## Goals:

- Main goal: Get a working, production-like deployment of PyForum on a Linux host.
- Other goals: Understand project structure and its dependencies. Run app under a dedicated non-login user, separate from my working copy of the repo. Setup a report branch for weekly reports.

## Tasks Completed:

| #   | Task                                                                                                        | Status | Owner | Finished   | Notes                                                           |
| --- | ----------------------------------------------------------------------------------------------------------- | ------ | ----- | ---------- | --------------------------------------------------------------- |
| 1   | Chose the project and documented the reasons (`project-selection.md`)                                       | Done   | Ivan  | 30.09.2026 | Python/Django stack, B2B topic                                  |
| 2   | Created system user `pyforum` (nologin, home `/srv/pyforum`) and cloned the code into `/srv/pyforum/app`    | Done   | Ivan  | 30.09.2026 | Production does not depend on my working folder                 |
| 3   | Installed Python 3.11 with `uv`, created venv `/srv/pyforum/venv`, installed requirements                   | Done   | Ivan  | 30.09.2026 | See "Problems and Solutions" below                              |
| 4   | Created PostgreSQL role and database `forum`, restored the dump `forum_d.sql`                               | Done   | Ivan  | 30.09.2026 | Peer auth over a Unix socket, no password                       |
| 5   | Created `.env` (mode 600), checked config with `manage.py check`                                            | Done   | Ivan  | 30.09.2026 | Console email backend                                           |
| 6   | Created systemd unit `pyforum.service` (gunicorn, 3 workers, socket `/run/pyforum/gunicorn.sock`)           | Done   | Ivan  | 30.09.2026 | `Restart=on-failure`                                            |
| 7   | Configured nginx site `pyforum`: proxy to the gunicorn socket, serving `/static/` and `/media/`            | Done   | Ivan  | 30.09.2026 | See "Problems and Solutions" below                              |
| 8   | Checked the result: main page and `/administrator/` work at http://localhost                                | Done   | Ivan  | 30.09.2026 | It works                                                        |
| 9   | Repo housekeeping: PR #1 (`logs/.gitkeep`, `logs/*.log` in `.gitignore`), created orphan branch `report`    | Done   | Ivan  | 30.09.2026 | The app needs the `logs/` folder to exist                       |

## Results:

- What I did: Deployed PyForum natively: PostgreSQL, gunicorn under systemd, and nginx as a reverse proxy. Isolated the app under dedicated system user in `/srv/pyforum`.
- What I achieved: Application works at http://localhost, including the admin panel. I now understand the project's components, configurations and dependencies.

## Problems and Solutions:

| #   | Problem                                                                                                            | Solution                                                                                         | Status |
| --- | ------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------ | ------ |
| 1   | The system Python 3.14 (Ubuntu 26.04 default) is too new for the project's pinned dependencies                     | Installed Python 3.11 with `uv` into `/opt/uv-python` and created the venv from it               | Done   |
| 2   | `requirements.txt` has both `psycopg2` and `psycopg2-binary` | Skipped `psycopg2` with `grep -v '^psycopg2=='`; `psycopg2-binary` provides the same module      | Done   |
| 3   | The dump `forum_d.sql` has `OWNER TO` lines for roles that do not exist locally                                    | Filtered them out with `grep -v 'OWNER TO'` before loading it with `psql`                        | Done   |
| 4   | nginx (`www-data`) had no access to the gunicorn socket                                                            | Added `www-data` to group `pyforum`  | Done   |

## Next Steps:

- Task 2: containerize the app (Dockerfile and docker-compose with PostgreSQL and nginx).
- Fix issues found in the code: `DEBUG=True` is hardcoded, `STATIC_ROOT` points to the project root (`collectstatic` cannot be used), migrations are in `.gitignore`.

## Tools and Technologies Used:

- Ubuntu 26.04: host OS.
- uv: Python 3.11 installation and virtual environment.
- Django, gunicorn: the application and its WSGI server.
- PostgreSQL: database, restored from the project dump.
- nginx: reverse proxy and static/media files.
- systemd: runs the gunicorn service.
- Git/GitHub: branches, pull requests, Conventional Commits.

## Comments and Conclusions:

The deployment went as planned, with a few small environment adjustments. As a result, deploying this application manually helped me to understand how it works, which will also help me containerize the app in the next task.

## Appendix and Resources:

- uv: https://docs.astral.sh/uv/
- Gunicorn deployment with nginx: https://gunicorn.org/deploy/
