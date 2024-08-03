#!/bin/bash

# Ensure required environment variables are set
if [ -z "$DATABASE_URL" ]; then
  echo "DATABASE_URL is not set"
  exit 1
fi

if [ -z "$DB_NAME_PRODUCTION" ]; then
  echo "DB_NAME_PRODUCTION is not set"
  exit 1
fi

if [ -z "$POSTGRES_USER" ]; then
  echo "POSTGRES_USER is not set"
  exit 1
fi

if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "POSTGRES_PASSWORD is not set"
  exit 1
fi

# Extract connection parameters from DATABASE_URL
DB_HOST=$(echo $DATABASE_URL | awk -F[@/] '{print $3}' | awk -F[:] '{print $1}')
DB_PORT=$(echo $DATABASE_URL | awk -F[@/] '{print $3}' | awk -F[:] '{print $2}')
DB_ADMIN_USER=$(echo $DATABASE_URL | awk -F[@:/] '{print $4}')
DB_ADMIN_PASS=$(echo $DATABASE_URL | awk -F[@:/] '{print $5}')

# Connect to PostgreSQL
export PGPASSWORD=$DB_ADMIN_PASS

# Create the database if it doesn't exist
DB_EXISTS=$(psql -h $DB_HOST -U $DB_ADMIN_USER -p $DB_PORT -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME_PRODUCTION'")
if [[ $DB_EXISTS != 1 ]]; then
  psql -h $DB_HOST -U $DB_ADMIN_USER -p $DB_PORT -c "CREATE DATABASE $DB_NAME_PRODUCTION;"
else
  echo "Database $DB_NAME_PRODUCTION already exists"
fi

# Create the user if it doesn't exist
USER_EXISTS=$(psql -h $DB_HOST -U $DB_ADMIN_USER -p $DB_PORT -tc "SELECT 1 FROM pg_roles WHERE rolname = '$POSTGRES_USER'")
if [[ $USER_EXISTS != 1 ]]; then
  psql -h $DB_HOST -U $DB_ADMIN_USER -p $DB_PORT -c "CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';"
else
  echo "User $POSTGRES_USER already exists"
fi

# Grant privileges
psql -h $DB_HOST -U $DB_ADMIN_USER -p $DB_PORT -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME_PRODUCTION TO $POSTGRES_USER;"

echo "Database setup complete"
