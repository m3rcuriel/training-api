require 'curl'
require 'lib/cache'

module Firebots
  module InternalAPI::Controllers

    class Public < Kenji::Controller

      get '/about' do
        url = 'https://gist.githubusercontent.com/PikaDotus/f65b98b347cc12816c36/raw/about.md'
        unless message = Cache.get('about')
          Cache.set('about', message = Curl.get(url).body_str, 60)
        end

        {
          status: 200,
          message: message.force_encoding('UTF-8'),
        }
      end

      get '/important-info' do
        url = 'https://gist.githubusercontent.com/PikaDotus/7a9e39020c0276c3034a/raw/important-info.md'
        unless message = Cache.get('important-info')
          Cache.set('important-info', message = Curl.get(url).body_str, 60)
        end

        {
          status: 200,
          message: message.force_encoding('UTF-8'),
        }
      end

      get '/message' do
        url = 'https://gist.githubusercontent.com/PikaDotus/97bb3fdebbc0446c964a/raw/alert'
        unless message = Cache.get('message')
          Cache.set('message', message = Curl.get(url).body_str, 60)
        end

        {
          status: 200,
          message: message.force_encoding('UTF-8')
        }
      end

    end
  end
end
