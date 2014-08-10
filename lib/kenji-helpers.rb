require 'kenji'


# 1. Include KenjiRequireMethod automatically.

require 'lib/authentication'

module Kenji
  class Controller
    include Firebots::Authentication::KenjiRequireMethod
  end
end

# 2. Define helper map block to sanitize hash values for API response.

module Firebots::InternalAPI
  module Controllers

    module Helpers

      HashPairSanitizer = lambda do |(k, v)|
        v = case v
            when Time; v.to_i
            when BigDecimal; v.to_s('F')
            else v
            end
        [k, v]
      end

    end
  end
end
