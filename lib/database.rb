require 'sequel'
require 'konfiguration'
require 'rubyflake'

DB = Sequel.connect(Konfiguration.database(:uri))

module Models

  Users = DB[:users]
  Badges = DB[:badges]

end
