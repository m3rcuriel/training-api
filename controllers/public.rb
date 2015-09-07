require 'curl'
require 'lib/cache'

module Firebots
  module InternalAPI::Controllers

    class Public < Kenji::Controller

      get '/about' do
        url = 'https://gist.githubusercontent.com/m3rcuriel/a617b50b0296b792c180/raw/about.md'
        unless message = Cache.get('about')
          Cache.set('about', message = Curl.get(url).body_str, 60)
        end

        {
          status:  200,
          message: message.force_encoding('UTF-8'),
        }
      end

      get '/important-info' do
        url = 'https://gist.githubusercontent.com/m3rcuriel/c7b1088531115c7b53d0/raw/important-info.md'
        unless message = Cache.get('important-info')
          Cache.set('important-info', message = Curl.get(url).body_str, 60)
        end

        {
          status:  200,
          message: message.force_encoding('UTF-8'),
        }
      end

      get '/message' do
        url = 'https://gist.githubusercontent.com/glinia/97bb3fdebbc0446c964a/raw/alert'
        unless message = Cache.get('message')
          Cache.set('message', message = Curl.get(url).body_str, 60)
        end

        {
          status:  200,
          message: message.force_encoding('UTF-8')
        }
      end
    end
  end
end
