
Dir[File.expand_path('../*.rb', __FILE__)].each do |f|
  require f
end

module Firebots::InternalAPI::Controllers

  class Root < Kenji::Controller

    pass '/auth', Auth
    pass '/account', Account
    pass '/badges', Badges
    pass '/public', Public

  end
end
