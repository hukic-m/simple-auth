#!/bin/bash

set -e

# Run the create_db script
./create_db.sh

# Load environment variables from .env file, ignoring comments and empty lines
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Explicitly set the DATABASE_URL for development and production
export DATABASE_URL_DEVELOPMENT="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME_DEVELOPMENT}"
export DATABASE_URL_PRODUCTION="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME_PRODUCTION}"

echo "Running migrations."

# Run migrations for development
RACK_ENV=development DATABASE_URL=$DATABASE_URL_DEVELOPMENT bundle exec rake db:migrate

# Run migrations for production
RACK_ENV=production DATABASE_URL=$DATABASE_URL_PRODUCTION bundle exec rake db:migrate

echo "Database setup and migrations completed."
