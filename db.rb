require 'dotenv/load'
require 'sequel/core'

env = ENV['RACK_ENV'] || 'development'
db_url = ENV["DATABASE_URL_#{env.upcase}"]

DB = Sequel.connect(db_url)

DB.extension :pg_auto_parameterize if DB.adapter_scheme == :postgres && Sequel::Postgres::USES_PG

Dir[File.join(__dir__, './models', '*.rb')].each { |file| require file }

DB
