require 'dotenv/load'
require 'sequel'

env = ENV['RACK_ENV'] || 'development'
db_url = ENV["DATABASE_URL_#{env.upcase}"] || ENV['DATABASE_URL']

DB = Sequel.connect(db_url)

DB.extension :pg_auto_parameterize if DB.adapter_scheme == :postgres && Sequel::Postgres::USES_PG
