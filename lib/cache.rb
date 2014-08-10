require 'dalli'
require 'konfiguration'

module Firebots
  Cache = Dalli::Client.new(Konfiguration.cache(:main))
end
