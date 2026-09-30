# Task 1 - Setup Webapp

## Goal:

Deploy the pyforum Django application on a Linux host (VM with Linux).

## Steps:

### 1. Install packages:

```bash
sudo apt update
sudo apt install -y postgresql nginx git curl
```

### 2. Create user and clone code:

```bash

sudo useradd --system --create-home --home-dir /srv/pyforum --shell /usr/sbin/nologin pyforum
sudo -u pyforum git clone https://github.com/IvanDukhota/pyforum-IvanDukhota.git /srv/pyforum/app
```

The app runs under a separate user without login access for security reasons. Code is cloned into /srv dir (standart for service data) as this user, so it owns the files and production does not depend on my working folder.

### 3. Install Python 3.11 and dependecies:

System Python 3.14 (Ubuntu 26.04 default) is too new for the project's dependencies, so Python 3.11 is installed via `uv`.

```bash
curl -LsSf https://astral.sh/uv/install.sh | sudo env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh
sudo env UV_PYTHON_INSTALL_DIR=/opt/uv-python uv python install 3.11

sudo -u pyforum -H bash
cd /srv/pyforum/app
UV_PYTHON_INSTALL_DIR=/opt/uv-python uv venv --python 3.11 /srv/pyforum/venv
source /srv/pyforum/venv/bin/activate
grep -v '^psycopg2==' requirements.txt | uv pip install -r -
exit
```

requirements.txt contains both psycopg2 and psycopg2-binary. psycopg2 is built from source and needs libpq-dev and a compiler, while psycopg2-binary is prebuilt and provides the same module. So grep -v '^psycopg2==' skips the source package, and the rest is installed as usual.

### 4. Setup database:

```
sudo -u postgres createuser pyforum
sudo -u postgres createdb -O pyforum forum
sudo -u puforum -H bash -c "grep -v 'OWNER TO' /srv/pyforum/app/forum_d.sql | psql -d forum"
```

DB restored from the dump forum_d.sql.

### 5. Configure app:

Create /srv/pyforum/app/.env:

```bash
SECRET_KEY=random
PG_USER=pyforum
PG_PASSWORD=
DB_HOST=
DB_PORT=
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
EMAIL_HOST=
EMAIL_PORT=587
EMAIL_USE_TLS=1
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=
CORS_ORIGIN_WHITELIST=http://localhost
```

```bash
chmod 600 .env
mkdir -p logs
/srv/pyforum/venv/bin/python manage.py check
```

### 6. Run gunicorn as a service:

etc/systemd/system/pyforum.service:

```bash
[Unit]
Description=PyForum Django app
After=network.target postgresql.service
Requires=postgresql.service

[Service]
User=pyforum
Group=pyforum
WorkingDirectory=/srv/pyforum/app
RuntimeDirectory=pyforum
RuntimeDirectoryMode=0750
UMask=0007
ExecStart=/srv/pyforum/venv/bin/gunicorn --workers 3 --bind unix:/run/pyforum/gunicorn.sock forum-sandbox.wsgi:application
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now pyforum
```

### 7. Configure nginx:

```bash
sudo usermod -aG pyforum www-data
```

etc/nginx/sites-available/pyforum:

```nginx
server {
    listen 80 default_server;
    server_name _;

    location /static/ { alias /srv/pyforum/app/static/; }
    location /media/  { alias /srv/pyforum/app/media/; }

    location / {
        proxy_pass http://unix:/run/pyforum/gunicorn.sock;
        proxy_set_header Host $host;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/pyforum /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

### 8. Check results:

- http://localhost/ - main page opens;
- htpp://localhost/administrator/ - admin login works;

## Results:

The application is deployed on Ubuntu 26.04 and available at http://localhost. It runs as a systemd service inder a dedicated user, with gunicorn behind nginx and a native PostgreSQL database that was restored from the dump. Static files and media are served by nginx.
