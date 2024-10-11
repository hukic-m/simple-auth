require 'dotenv'
require 'roda'
Dotenv.load
require_relative './lib/db'
require_relative './models'
require 'rake'
require 'logger'

class SimpleAuth < Roda
  plugin :json
  plugin :route_list
  plugin :default_headers,
         'Content-Type' => 'application/json',
         'X-Content-Type-Options' => 'nosniff'
  plugin :route_csrf
  plugin :hash_branch_view_subdir

  Dir['./routes/**/*.rb'].each do |route_file|
    require_relative route_file.delete_suffix('.rb')
  end

  logger = Logger.new($stdout)
  logger.level = Logger::WARN

  route do |r|
    r.hash_branches

    r.root do
      { message: 'All systems operational' }
    end
  end
end
