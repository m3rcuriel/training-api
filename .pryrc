# vim: ft=ruby

require File.expand_path('../init', __FILE__)

require 'lib/better-number-inspect'
require 'lib/database'

Dir[File.expand_path("../controllers/**/*.rb", __FILE__)].each { |f| require f }

