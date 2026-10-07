# DevOps Report:

## General Information:

- Period: 02.10.2026 - 07.10.2026
- Report date: 07.10.2026
- Author: Ivan Dukhota
- Project: PyForum
- Goal: Containerize PyForum application and run it with Docker Compose

## Summary:

This report covers the second task, deploying a containerized web application. First of all, I prepared the project settings for containers and then wrote Dockerfile, docker-compose.yml file and nginx configuration file. The app now runs in three containers: app itself (using gunicorn), database (PostgreSQL) and nginx. It works locally on the same Ubuntu 26.04 host that I used for the first task.

## Goals:

- Main goal: containerize web application with Docker.
- Other goals: Move configuration to environment variables, run the app as a non-root user inside the container and keep secrets out of image and repo.

## Architecture:

- nginx (nginx:alpine, port 80): serves /media/, proxies all other requests to app:8000.
- app (python:3.11-slim, non-root user): runs collectstatic on start, then gunicorn on port 8000. Static files are served by whitenoise.
- db (postgres:14): healthcheck, the dump is loaded on first start via /docker-entrypoint-initdb.d.
- Volumes: pgdata (database), media (uploaded files, shared between app and nginx).
- Config: .env file (not in git), DB_HOST=db is set in docker-compose.

## Tasks Completed:

| #   | Task                                                                                                          | Status | Owner | Finished   | Notes                               |
| --- | ------------------------------------------------------------------------------------------------------------- | ------ | ----- | ---------- | ----------------------------------- |
| 1   | Prepared settings for containers: DEBUG and ALLOWED_HOSTS from env, STATIC_ROOT=staticfiles/, console logging, fixed whitenoise order | Done | Ivan | 05.10.2026 | - |
| 2   | Removed psycopg2 from requirements, kept psycopg2-binary                                                  | Done   | Ivan  | 05.10.2026 | Same module, no build dependencies  |
| 3   | Wrote Dockerfile and .dockerignore                                                                        | Done   | Ivan  | 07.10.2026 | Non-root user, gunicorn             |
| 4   | Wrote docker-compose.yml (app, db, nginx) and nginx/default.conf                                          | Done   | Ivan  | 07.10.2026 | Healthcheck, named volumes          |
| 5   | Checked the result: main page, admin and media work at http://localhost                                      | Done   | Ivan  | 07.10.2026 | Branch feature/docker, PR to main |

## Results:

- What I did: Containerized PyForum: app image based on python:3.11-slim, PostgreSQL and nginx in separate containers, connected with docker-compose.
- What I achieved: The app runs with docker compose up, without installing Python or PostgreSQL on the host. Settings are now read from the environment.

## Problems and Solutions:

| #   | Problem                                                                    | Solution                                                               | Status |
| --- | -------------------------------------------------------------------------- | ---------------------------------------------------------------------- | ------ |
| 1   | DEBUG=True was hardcoded                                                 | Read DEBUG and ALLOWED_HOSTS from env with python-decouple       | Done   |
| 2   | STATIC_ROOT pointed to the project root, collectstatic could not run   | Set STATIC_ROOT to staticfiles/, added it to .gitignore          | Done   |
| 3   | Django does not serve media files when DEBUG=False                       | Added nginx container that serves /media/ from a shared volume       | Done   |
| 4   | The dump has OWNER TO postgres lines                                     | Used PG_USER=postgres for the db container                           | Done   |
| 5   | .env has DB_HOST=localhost, which does not work inside a container       | Overrode DB_HOST=db in the environment section of docker-compose     | Done   |
| 6   | Migrations are in .gitignore                                             | Dump already has the schema                    | Open   |

## Next Steps:

- Merge PR feature/docker into main.
- Task 3: implement CI/CD (most likely Jenkins).

## Tools and Technologies Used:

- Ubuntu 26.04: host OS.
- Docker, Docker Compose: containers for app, database and nginx.
- Django, gunicorn: the application and its WSGI server.
- whitenoise: serves static files from the app container.
- PostgreSQL 14: database, loaded from the project dump.
- nginx: reverse proxy and media files.
- Git/GitHub: branches, pull requests, Conventional Commits.

## Comments and Conclusions:

The second task went smoothly. The main challenge was to find issues in the app settings.

## Appendix and Resources:

- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Compose file reference: https://docs.docker.com/reference/compose-file/