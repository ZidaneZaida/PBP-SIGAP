.PHONY: install run check migrate makemigrations test seed lint format superuser shell db-init db-start db-stop db-create

# Venv: override dengan `make PY=/path/to/python <target>` bila berbeda.
VENV ?= server-django
PY ?= $(VENV)/bin/python
PIP ?= $(VENV)/bin/pip
RUFF ?= $(VENV)/bin/ruff

# Postgres lokal via conda (tanpa sudo, tanpa Docker).
PG_ENV ?= pg16
PG_BIN ?= $(HOME)/miniconda3/envs/$(PG_ENV)/bin
PG_DATA ?= $(HOME)/sigap-pgdata
PG_PORT ?= 5432

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
	$(PY) manage.py test --noinput

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

# --- Postgres lokal -------------------------------------------------------
db-init:
	@test -d $(PG_DATA) || (conda create -n $(PG_ENV) -c conda-forge --override-channels postgresql=16 -y && $(PG_BIN)/initdb -D $(PG_DATA) -U postgres --auth=trust)

db-start:
	@$(PG_BIN)/pg_ctl -D $(PG_DATA) -l $(PG_DATA)/server.log -o "-p $(PG_PORT)" start

db-stop:
	@$(PG_BIN)/pg_ctl -D $(PG_DATA) stop

db-create:
	@$(PG_BIN)/createdb -h 127.0.0.1 -p $(PG_PORT) -U postgres sigap || echo "database sigap sudah ada"
