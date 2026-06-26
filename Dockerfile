# Dockerfile
FROM apache/airflow:2.9.2-python3.11

# Copy the uv binary from the official uv Docker image.
# This is the recommended approach — no pip required to get uv into the container.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy the dependency declaration and the lock file.
# Copying these before the rest of the project means Docker can cache
# this layer and skip re-installing packages when only code files change.
COPY pyproject.toml uv.lock ./

# Export pinned production dependencies from uv.lock to a flat requirements file,
# then install them directly into the Airflow system Python.
# Runs as root so uv has write access to /usr/local/lib/python3.11/site-packages/.
# --no-dev:         exclude the dev dependency group (pytest, ruff).
# --no-hashes:      omit hash verification (not needed inside a controlled image build).
# --no-emit-project: exclude the local pricewatch-ph package itself (source is volume-mounted).
# --system:         install into the system Python instead of creating a virtualenv.
RUN /usr/local/bin/uv export --no-dev --no-hashes --no-emit-project -o /tmp/requirements.txt \
    && /usr/local/bin/uv pip install --system -r /tmp/requirements.txt

USER airflow