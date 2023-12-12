# `python-base` sets up all our shared environment variables
FROM python:3.12.0-slim as python-base

# python
# prevents python creating .pyc files
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# pip
ENV PIP_NO_CACHE_DIR=off
ENV PIP_DISABLE_PIP_VERSION_CHECK=on
ENV PIP_DEFAULT_TIMEOUT=100

# poetry
# make poetry install to this location /opt/poetry, create a virtual env with '.venv' name and not interactive
ENV POETRY_VERSION=1.7.1
ENV POETRY_HOME="/opt/poetry"
ENV POETRY_VIRTUALENVS_IN_PROJECTENV=true
ENV POETRY_NO_INTERACTION=1

# paths
# this is where our requirements + virtual environment will live
ENV PYSETUP_PATH="/opt/pysetup"
ENV VENV_PATH="/opt/pysetup/.venv"

# prepend poetry and venv to path
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

# FROM python-base as builder-base
RUN apt-get update && apt-get upgrade -y
RUN apt-get install --no-install-recommends -y curl build-essential libpq-dev gcc
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# install poetry - respects $POETRY_VERSION & $POETRY_HOME
RUN pip install "poetry==$POETRY_VERSION"
RUN pip install psycopg2

# copy project requirement files here to ensure they will be cached.
WORKDIR $PYSETUP_PATH
COPY poetry.lock pyproject.toml ./

# install runtime deps - uses $POETRY_VIRTUALENVS_IN_PROJECT internally
RUN poetry install --no-dev

# quicker install as runtime deps are already installed
RUN poetry install

# application configuration
WORKDIR /app
COPY . /app/
EXPOSE 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]