require 'lib/cache'

module Firebots
  module InternalAPI::Controllers

    class Stats < Kenji::Controller

      ##########
      # REWORK #
      ##########

      def ensure_cached(key, result)
        result = {
          status: 200,
          result: result,
        }

        Cache.set(key, result, 24 * 3600)
        result
      end
    end
  end
end
