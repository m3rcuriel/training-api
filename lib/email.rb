require 'mail'

module Firebots
  module Email

    def self.send(&block)
      Thread.new do
        mail = Mail.new(&block)
        mail.deliver!
      end
    end

  end
end
