require 'rspec'
require 'sequel'
require 'dotenv'
require 'rack/test'
Dotenv.load('.env.test')

# Set up the test database
TEST_DB = Sequel.connect(ENV['DATABASE_URL_TEST'])

Sequel.extension :migration
migration_path = File.expand_path('../migrate', __dir__)
Sequel::Migrator.run(TEST_DB, migration_path)

RSpec.configure do |config|
  config.around(:each) do |example|
    TEST_DB.transaction(rollback: :always, auto_savepoint: true) do
      example.run
    end
  end
end

# Load all model files
Dir[File.expand_path('../models/*.rb', __dir__)].each { |file| require file }
