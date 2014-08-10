require 'sequel'
require 'konfiguration'
require 'rubyflake'

if ENV['OPENSHIFT_POSTGRESQL_DB_URL']
  DB = Sequel.connect(ENV['OPENSHIFT_POSTGRESQL_DB_URL'])
else
  DB = Sequel.connect(Konfiguration.database(:uri))
end

module Models

  Users = DB[:users]
  Badges = DB[:badges]

end
