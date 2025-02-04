#!/bin/bash
set -e

until mysql -h db -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1"; do
  echo "MySQL is not ready - sleeping"
  sleep 2
done

echo "MySQL is up and running!"

if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

bundle exec rails db:create
bundle exec rails db:migrate

exec "$@"