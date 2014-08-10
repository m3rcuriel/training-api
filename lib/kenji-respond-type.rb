require 'rack'

module Kenji
  class Kenji

    def respond_type(type, body)
      throw(:KenjiRespondControlFlowInterrupt,
            Rack::Response.new(body, 200, 'Content-Type' => type).finish)
    end
  end
end
