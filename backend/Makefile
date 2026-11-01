.PHONY: install run migrate makemigrations test check lint format superuser shell seed

VENV := .venv
PY := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
RUFF := $(VENV)/bin/ruff

install:
	python3 -m venv $(VENV)
	$(PIP) install -U pip
	$(PIP) install -r requirements-dev.txt

run:
	$(PY) manage.py runserver 0.0.0.0:8000

check:
	$(PY) manage.py check

migrate:
	$(PY) manage.py migrate

makemigrations:
	$(PY) manage.py makemigrations

test:
	$(PY) manage.py test --keepdb

seed:
	$(PY) manage.py seed_demo

lint:
	$(RUFF) check .

format:
	$(RUFF) format .

superuser:
	$(PY) manage.py createsuperuser

shell:
	$(PY) manage.py shell
