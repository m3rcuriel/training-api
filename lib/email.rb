require 'mail'

module Firebots
  module Email

    def self.send(&block)
      mail = Mail.new(&block)
      mail.deliver!
    end

  end
end
