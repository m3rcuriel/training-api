require 'sequel'
require 'konfiguration'
require 'rubyflake'

if ENV['RACK_ENV'] == 'production'
  DB = Sequel.connect('postgres://logan:Dj3AsZqAxG%h9?@aag9w68z5p862l.cehf3tpvjpkp.us-west-1.rds.amazonaws.com:5432')
else
  DB = Sequel.connect(Konfiguration.database(:uri))
end

module Models

  Users = DB[:users]
  Badges = DB[:badges]

end
