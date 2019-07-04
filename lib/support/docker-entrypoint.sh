#!/bin/bash

echo "Starting ..."

if [ "$RAILS_ENV" == "test" ]; then
    HOST=${POSTGRES_HOST:-postgres}
    DATABASE=${POSTGRES_DATABASE:-erica_store_test}
    USERNAME=${POSTGRES_USERNAME:-postgres}
    PASSWORD=${POSTGRES_PASSWORD}
fi
if [ "$RAILS_ENV" == "development" ]; then
    HOST=${POSTGRES_HOST:-postgres}
    DATABASE=${POSTGRES_DATABASE:-erica_store_development}
    USERNAME=${POSTGRES_USERNAME:-postgres}
    PASSWORD=${POSTGRES_PASSWORD}
fi
if [ "$RAILS_ENV" == "production" ]; then
    HOST=${POSTGRES_HOST:-postgres}
    DATABASE=${POSTGRES_DATABASE:-erica_store_production}
    USERNAME=${POSTGRES_USERNAME:-erica_store}
    PASSWORD=${POSTGRES_PASSWORD}
fi

# If the container has been killed, there may be a stale pid file
# preventing rails from booting up
rm -f tmp/pids/server.pid

# Trap SIGINT. Otherwise, if postgres doesn't come up, we cannot stop
# the container with ctrl+c.
trap_int_signal() {
    echo "Stopping (from SIGINT)"
    exit 0
}
trap "trap_int_signal" INT

echo "Checking postgres availability ..."
until PGPASSWORD=$PASSWORD psql -h $HOST -U $USERNAME -c '\q' 2>/dev/null; do
  echo "Postgres is unavailable - sleeping"
  sleep 1
done

exec "$@"
