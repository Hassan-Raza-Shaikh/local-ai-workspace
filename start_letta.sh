#!/usr/bin/env bash
set -euo pipefail

echo "Starting Letta local stateful agent server..."

# Ensure Docker is running and start the pgvector database container on-demand
if ! docker info >/dev/null 2>&1; then
    echo "⚠️  Docker is not running! Launching Docker Desktop..."
    open -a "Docker"
    echo -n "Waiting for Docker daemon to start"
    while ! docker info >/dev/null 2>&1; do
        echo -n "."
        sleep 2
    done
    echo ""
fi

echo "Starting Letta PostgreSQL database container..."
docker compose -f /Users/hassan/local-ai/docker-compose.tools.yml up -d letta-db

# Wait for database port 5432 to be ready
echo -n "Waiting for database to accept connections"
while ! nc -z localhost 5432 >/dev/null 2>&1; do
    echo -n "."
    sleep 1
done
echo ""

echo "Enabling pgvector extension in database..."
docker exec -i letta-db psql -U letta -d letta -c "CREATE EXTENSION IF NOT EXISTS vector;"

echo "Starting Letta server container..."
docker compose -f /Users/hassan/local-ai/docker-compose.tools.yml up -d letta-server

# Wait for Letta server port 8283 to be ready
echo -n "Waiting for Letta server to accept connections"
while ! nc -z localhost 8283 >/dev/null 2>&1; do
    echo -n "."
    sleep 1
done
echo ""

echo "✔ Letta server started in Docker!"
echo "  - Local Agent API: http://localhost:8283"
echo "  - Server Logs: run 'docker logs -f letta-server'"
