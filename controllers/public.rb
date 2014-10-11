require 'curl'

module Firebots::InternalAPI::Controllers

  class Public < Kenji::Controller

    get '/about' do
      http = Curl.get('https://gist.githubusercontent.com/PikaDotus/'\
        'f65b98b347cc12816c36/raw/about.md')

      {
        status: 200,
        message: http.body_str.force_encoding('UTF-8'),
      }
    end

    get '/important-info' do
      http = Curl.get('https://gist.githubusercontent.com/PikaDotus/'\
        '7a9e39020c0276c3034a/raw/important-info.md')

      {
        status: 200,
        message: http.body_str.force_encoding('UTF-8'),
      }
    end

    get '/message' do
      http = Curl.get('https://gist.githubusercontent.com/PikaDotus/'\
        '97bb3fdebbc0446c964a/raw/alert')

      {
        status: 200,
        message: http.body_str.force_encoding('UTF-8')
      }
    end

  end
end
