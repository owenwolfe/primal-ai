"""Stateless API: no accounts, sessions, database, or submitted-label storage."""

import os

DEBUG = os.environ.get("DJANGO_DEBUG", "0") == "1"
SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "")
if not SECRET_KEY:
    if not DEBUG:
        raise RuntimeError("DJANGO_SECRET_KEY is required outside local development")
    SECRET_KEY = "local-development-only-not-for-production"

ALLOWED_HOSTS = os.environ.get("ALLOWED_HOSTS", "localhost,127.0.0.1,[::1]").split(",")
ROOT_URLCONF = "primal.urls"
WSGI_APPLICATION = "primal.wsgi.application"
INSTALLED_APPS = []
DATABASES = {}
MIDDLEWARE = [
    "primal.middleware.APIBoundary",
    "django.middleware.security.SecurityMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]
APPEND_SLASH = False
DATA_UPLOAD_MAX_MEMORY_SIZE = 32768
SECURE_CONTENT_TYPE_NOSNIFF = True
CSRF_COOKIE_SECURE = not DEBUG
SECURE_SSL_REDIRECT = not DEBUG
SECURE_HSTS_SECONDS = 31536000 if not DEBUG else 0
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
# Enable only behind an ingress that strips user-supplied X-Forwarded-Proto.
if os.environ.get("TRUST_PROXY", "0") == "1":
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
DEFAULT_CHARSET = "utf-8"
USE_TZ = True

# Do not log request bodies, OCR text, or photos. Gunicorn access logging is disabled.
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {"null": {"class": "logging.NullHandler"}},
    "loggers": {"django.request": {"handlers": ["null"], "propagate": False}},
}
