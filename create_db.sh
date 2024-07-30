#!/bin/bash

set -e

# Function to create a database if it doesn't exist
create_db() {
  local dbname=$1
  psql postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@$DB_HOST:$DB_PORT/postgres -c "SELECT 1 FROM pg_database WHERE datname='$dbname'" | grep -q 1 || \
  psql postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@$DB_HOST:$DB_PORT/postgres -c "CREATE DATABASE $dbname"
}

# Create development database
create_db $DB_NAME_DEVELOPMENT

# Create production database
create_db $DB_NAME_PRODUCTION

echo "Databases setup completed."
