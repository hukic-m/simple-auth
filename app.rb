require 'dotenv'
require 'roda'
Dotenv.load
require_relative './lib/db'
require_relative './models'
require 'rake'

class SimpleAuth < Roda
  plugin :json
  plugin :route_list
  plugin :default_headers,
         'Content-Type' => 'application/json',
         'X-Content-Type-Options' => 'nosniff'
  plugin :route_csrf
  plugin :hash_branch_view_subdir

  plugin :error_handler do |e|
    case e
    when Roda::RodaPlugins::RouteCsrf::InvalidToken
      @page_title = 'Invalid Security Token'
      response.status = 400
      view(content: '<p>An invalid security token was submitted with this request, and this request could not be processed.</p>')
    else
      $stderr.print "#{e.class}: #{e.message}\n"
      warn e.backtrace
      next exception_page(e, assets: true) if ENV['RACK_ENV'] == 'development'

      @page_title = 'Internal Server Error'
      view(content: '')
    end
  end

  Dir['./routes/**/*.rb'].each do |route_file|
    require_relative route_file.delete_suffix('.rb')
  end

  route do |r|
    r.hash_branches

    r.root do
      { message: 'Welcome to simple-auth' }
    end
  end
end
