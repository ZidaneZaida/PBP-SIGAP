#!/usr/bin/env bash
# Script build otomatis Render.com
set -o errexit  # Berhenti jika ada error

pip install --upgrade pip
pip install -r requirements.txt

python manage.py collectstatic --noinput
python manage.py migrate --noinput
python manage.py seed_demo

