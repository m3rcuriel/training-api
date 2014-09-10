# vim: ft=ruby
require 'rubygems'
require 'bundler/setup'
require 'rack'
require 'rack/cors'
require 'rack-json-logs'
require 'kenji'

# use Rack::ShowExceptions

use Rack::JsonLogs, pretty_print: (ENV['HOME'] != '/home/ec2-user'), print_options: {stdout: true, stderr: true}

use Rack::Cors do
  allow do
    origins '*'
    resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :patch]
  end
end

require File.expand_path('../init', __FILE__)
Dir[File.expand_path('../controllers/**/*.rb', __FILE__)].each { |f| require f }

require 'lib/json-url-parser'
use Firebots::JsonUrlParser::RackMiddleware

run Kenji::App.new(catch_exceptions: true, auto_cors: false,
                   root_controller: Firebots::InternalAPI::Controllers::Root)
