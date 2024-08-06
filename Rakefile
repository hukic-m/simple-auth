# require 'sequel'
# require 'dotenv/load'

# desc 'Setup the database'
# task :setup_db do
#   sh 'bash setup_db.sh'
# end

# namespace :db do
#   desc 'Migrate the database'
#   task :migrate, [:env, :version] do |_t, args|
#     env = args[:env] || 'development'
#     version = args[:version]&.to_i

#     ENV['RACK_ENV'] = env

#     require_relative './lib/db'

#     migrate = lambda do |_env, version|
#       require 'logger'
#       Sequel.extension :migration
#       DB.loggers << Logger.new($stdout) if DB.loggers.empty?
#       Sequel::Migrator.apply(DB, 'migrate', version)
#     end

#     migrate.call(env, version)
#   end

#   desc 'Migrate test database to latest version'
#   task :test_up do
#     Rake::Task['db:migrate'].invoke('test')
#   end

#   desc 'Migrate test database all the way down'
#   task :test_down do
#     Rake::Task['db:migrate'].invoke('test', 0)
#   end

#   desc 'Migrate test database all the way down and then back up'
#   task :test_bounce do
#     Rake::Task['db:migrate'].invoke('test', 0)
#     Rake::Task['db:migrate'].invoke('test')
#   end

#   desc 'Migrate development database to latest version'
#   task :dev_up do
#     Rake::Task['db:migrate'].invoke('development')
#   end

#   desc 'Migrate development database all the way down'
#   task :dev_down do
#     Rake::Task['db:migrate'].invoke('development', 0)
#   end

#   desc 'Migrate development database all the way down and then back up'
#   task :dev_bounce do
#     Rake::Task['db:migrate'].invoke('development', 0)
#     Rake::Task['db:migrate'].invoke('development')
#   end

#   desc 'Migrate production database to latest version'
#   task :prod_up do
#     Rake::Task['db:migrate'].invoke('production')
#   end
# end

# irb = proc do |env|
#   ENV['RACK_ENV'] = env
#   trap('INT', 'IGNORE')
#   dir, base = File.split(FileUtils::RUBY)
#   cmd = if base.sub!(/\Aruby/, 'irb')
#           File.join(dir, base)
#         else
#           "#{FileUtils::RUBY} -S irb"
#         end
#   sh "#{cmd} -r ./models"
# end

# desc 'Open irb shell in test mode'
# task :test_irb do
#   irb.call('test')
# end

# desc 'Open irb shell in development mode'
# task :dev_irb do
#   irb.call('development')
# end

# desc 'Open irb shell in production mode'
# task :prod_irb do
#   irb.call('production')
# end

# # Specs

# spec = proc do |type|
#   desc "Run #{type} specs"
#   task :"#{type}_spec" do
#     sh "#{FileUtils::RUBY} -w spec/#{type}.rb"
#   end

#   desc "Run #{type} specs with coverage"
#   task :"#{type}_spec_cov" do
#     ENV['COVERAGE'] = type
#     sh "#{FileUtils::RUBY} spec/#{type}.rb"
#     ENV.delete('COVERAGE')
#   end
# end
# spec.call('model')
# spec.call('web')

# desc 'Run all specs'
# task default: %i[model_spec web_spec]

# desc 'Run all specs with coverage'
# task :spec_cov do
#   ENV['RODA_RENDER_COMPILED_METHOD_SUPPORT'] = 'no'
#   FileUtils.rm_r('coverage') if File.directory?('coverage')
#   Dir.mkdir('coverage')
#   Rake::Task['_spec_cov'].invoke
# end
# task _spec_cov: %i[model_spec_cov web_spec_cov]

# # Other

# desc 'Annotate Sequel models'
# task 'annotate' do
#   ENV['RACK_ENV'] = 'development'
#   require_relative 'models'
#   DB.loggers.clear
#   require 'sequel/annotate'
#   Sequel::Annotate.annotate(Dir['models/**/*.rb'])
# end

# Migrate

migrate = lambda do |env, version|
  ENV['RACK_ENV'] = env
  require_relative './lib/db'
  require 'logger'
  Sequel.extension :migration
  DB.loggers << Logger.new($stdout) if DB.loggers.empty?
  Sequel::Migrator.apply(DB, 'migrate', version)
end

desc 'Migrate test database to latest version'
task :test_up do
  migrate.call('test', nil)
end

desc 'Migrate test database all the way down'
task :test_down do
  migrate.call('test', 0)
end

desc 'Migrate test database all the way down and then back up'
task :test_bounce do
  migrate.call('test', 0)
  Sequel::Migrator.apply(DB, 'migrate')
end

desc 'Migrate development database to latest version'
task :dev_up do
  migrate.call('development', nil)
end

desc 'Migrate development database to all the way down'
task :dev_down do
  migrate.call('development', 0)
end

desc 'Migrate development database all the way down and then back up'
task :dev_bounce do
  migrate.call('development', 0)
  Sequel::Migrator.apply(DB, 'migrate')
end

desc 'Migrate production database to latest version'
task :prod_up do
  migrate.call('production', nil)
end

# Shell

irb = proc do |env|
  ENV['RACK_ENV'] = env
  trap('INT', 'IGNORE')
  dir, base = File.split(FileUtils::RUBY)
  cmd = if base.sub!(/\Aruby/, 'irb')
          File.join(dir, base)
        else
          "#{FileUtils::RUBY} -S irb"
        end
  sh "#{cmd} -r ./models"
end

desc 'Open irb shell in test mode'
task :test_irb do
  irb.call('test')
end

desc 'Open irb shell in development mode'
task :dev_irb do
  irb.call('development')
end

desc 'Open irb shell in production mode'
task :prod_irb do
  irb.call('production')
end

# Specs

spec = proc do |type|
  desc "Run #{type} specs"
  task :"#{type}_spec" do
    sh "#{FileUtils::RUBY} -w spec/#{type}.rb"
  end

  desc "Run #{type} specs with coverage"
  task :"#{type}_spec_cov" do
    ENV['COVERAGE'] = type
    sh "#{FileUtils::RUBY} spec/#{type}.rb"
    ENV.delete('COVERAGE')
  end
end
spec.call('model')
spec.call('web')

desc 'Run all specs'
task default: %i[model_spec web_spec]

desc 'Run all specs with coverage'
task :spec_cov do
  ENV['RODA_RENDER_COMPILED_METHOD_SUPPORT'] = 'no'
  FileUtils.rm_r('coverage') if File.directory?('coverage')
  Dir.mkdir('coverage')
  Rake::Task['_spec_cov'].invoke
end
task _spec_cov: %i[model_spec_cov web_spec_cov]

# Other

desc 'Annotate Sequel models'
task 'annotate' do
  ENV['RACK_ENV'] = 'development'
  require_relative 'models'
  DB.loggers.clear
  require 'sequel/annotate'
  Sequel::Annotate.annotate(Dir['models/**/*.rb'])
end
