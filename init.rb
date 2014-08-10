# require some common libraries
require 'kenji'
require 'validate/kenji'


$app_path = File.expand_path(File.dirname(__FILE__))
$: << $app_path

# Create the namespace
module Firebots
  module InternalAPI
  end
end

require 'lib/kenji-helpers'
