# vim: ft=ruby
require 'rubygems'
require 'bundler/setup'
require 'rack'
require 'rack/cors'
require 'rack/ssl'
require 'kenji'

# use Rack::ShowExceptions

if ENV['PWD'].to_s.eql?('/home/ec2-user')
  puts 'forcing ssl'
  use Rack::SSL
end

use Rack::Cors do
  allow do
    origins '*'
    resource '*', :headers => :any, :methods => [:get, :post, :put, :delete, :patch]
  end
end

require File.expand_path('../init', __FILE__)
Dir[File.expand_path('../controllers/**/*.rb', __FILE__)].each { |f| require f }

run Kenji::App.new(catch_exceptions: true, auto_cors: false,
                   root_controller: Firebots::InternalAPI::Controllers::Root)
