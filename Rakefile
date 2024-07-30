require 'sequel'
require 'dotenv/load'

desc 'Setup the database'
task :setup_db do
  sh 'bash setup_db.sh'
end


namespace :db do
  desc 'Migrate the database'
  task :migrate, [:env, :version] do |_t, args|
    env = args[:env] || 'development'
    version = args[:version]&.to_i

    ENV['RACK_ENV'] = env

    require_relative './db'

    migrate = lambda do |_env, version|
      require 'logger'
      Sequel.extension :migration
      DB.loggers << Logger.new($stdout) if DB.loggers.empty?
      Sequel::Migrator.apply(DB, 'migrate', version)
    end

    migrate.call(env, version)
  end

  desc 'Migrate test database to latest version'
  task :test_up do
    Rake::Task['db:migrate'].invoke('test')
  end

  desc 'Migrate test database all the way down'
  task :test_down do
    Rake::Task['db:migrate'].invoke('test', 0)
  end

  desc 'Migrate test database all the way down and then back up'
  task :test_bounce do
    Rake::Task['db:migrate'].invoke('test', 0)
    Rake::Task['db:migrate'].invoke('test')
  end

  desc 'Migrate development database to latest version'
  task :dev_up do
    Rake::Task['db:migrate'].invoke('development')
  end

  desc 'Migrate development database all the way down'
  task :dev_down do
    Rake::Task['db:migrate'].invoke('development', 0)
  end

  desc 'Migrate development database all the way down and then back up'
  task :dev_bounce do
    Rake::Task['db:migrate'].invoke('development', 0)
    Rake::Task['db:migrate'].invoke('development')
  end

  desc 'Migrate production database to latest version'
  task :prod_up do
    Rake::Task['db:migrate'].invoke('production')
  end
end
