FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd --system --no-create-home app \
    && mkdir -p staticfiles logs media \
    && chown -R app:app staticfiles logs media

USER app

EXPOSE 8000

CMD ["sh", "-c", "python manage.py collectstatic --noinput && gunicorn forum-sandbox.wsgi:application --bind 0.0.0.0:8000 --workers 3"]
