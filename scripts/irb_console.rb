require 'bundler/setup'
require 'irb'
require 'dotenv'

# Load environment variables
Dotenv.load

# Require your application files
require_relative '../lib/database'
require_relative '../models/account'
require_relative '../models/role'
require_relative '../models/permission'

# Start an IRB session
IRB.start
