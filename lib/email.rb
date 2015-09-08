require 'mailgun'

module Firebots
  module Email

    def self.send(params)
      Thread.new do
        client.send_message('trainings.mvrt.com', params)
      end
    end

    def self.client
      @client ||= Mailgun::Client.new(Konfiguration.creds(:mailgun, :key))
    end

  end
end
