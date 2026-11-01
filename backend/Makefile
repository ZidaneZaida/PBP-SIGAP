.PHONY: install db-up db-down run migrate makemigrations test lint format superuser shell

VENV := .venv
PY := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
RUFF := $(VENV)/bin/ruff

install:
	python3 -m venv $(VENV)
	$(PIP) install -U pip
	$(PIP) install -r requirements-dev.txt

db-up:
	docker compose up -d

db-down:
	docker compose down

run:
	$(PY) manage.py runserver 0.0.0.0:8000

migrate:
	$(PY) manage.py migrate

makemigrations:
	$(PY) manage.py makemigrations

test:
	$(PY) manage.py test --parallel 1

lint:
	$(RUFF) check .

format:
	$(RUFF) format .

superuser:
	$(PY) manage.py createsuperuser

shell:
	$(PY) manage.py shell