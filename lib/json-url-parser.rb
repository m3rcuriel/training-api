require 'json'

module Firebots

  module JsonUrlParser

    class << self

      def parse_url(url, key)
        parsed = CGI.parse(URI.parse(url).query)
        JSON.load(parsed[key][0])
      end

      def parse_query(query, key)
        parsed = CGI.parse(query)
        JSON.load(parsed[key][0])
      end

      def parse(string)
        JSON.load(string)
      end

    end

    class RackMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        query = env['QUERY_STRING']

        url_input = JsonUrlParser.parse_query(query, 'json') || {}
        normal_input = JsonUrlParser.parse(env['rack.input'].string) || {}
        new_input = normal_input.merge(url_input)

        env['rack.input'] = StringIO.new(new_input.to_json.to_s)
        @app.call(env)
      end
    end

  end
end
