require 'dalli'
require 'konfiguration'

module Firebots
  if ENV['HOME'] == '/home/ec2-user' || ENV['SUDO_USER'] == 'ec2-user'
    Cache ||= Dalli::Client.new('training.svgxct.cfg.usw2.cache.amazonaws.com:11211')
  else
    Cache ||= Dalli::Client.new(Konfiguration.cache(:main))
  end
end
