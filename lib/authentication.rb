
require 'openssl'
require 'securerandom'
require 'base64'

module Firebots

  class Authentication

    # Instanciate the authentication library with a specific user model.
    #
    def initialize(user)
      @user = user
    end

    # Generates an authentication token for its user, embedding the login time,
    # and any extra metadata.
    #
    # Returns a token string.
    #
    def generate_token(extra_meta = {})
      auth = {
        user: @user[:id],
        time: Time.now.to_i,
      }.merge(extra_meta).to_json

      key = @user[:password_key]

      token = OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, [key].pack('H*'), auth)

      Base64.strict_encode64([auth, token].join("\0"))
    end

    # Verifies that a token is valid. Returns a bool.
    #
    def verify_token(token)
      key = @user[:password_key]
      auth, mac = self.class.split_token(token)
      computed_mac = OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, [key].pack('H*'), auth)
      mac == computed_mac
    end

    # This module provides a function that controllers can use to enforce that
    # requests are properly authenticated.
    #
    module KenjiRequireMethod

      # Checks the current request to enforce that it is properly
      # authenticated. Uses `kenji.respond` in case of failures.
      #
      # When given a block, an additional check is performed: The block is
      # called with the user as an argument, and it must return true in order
      # to pass authentication.
      #
      # Returns the current user's model, for convenience.
      #
      # When the authentication header contains the suffix `; renew`, a new
      # authenticated token will be returned with the `time` property set to
      # the current timestamp. This allows for tokens that expire after a short
      # amount of inactivity.
      #
      # NOTE: this must be included into a real Kenji controller.
      #
      def requires_authentication!(permission = :all, &user_authenticator)
        unless \
            (raw_header = kenji.env['HTTP_FIREBOTS_AUTHENTICATION']) &&
            (header = raw_header.split(';').map(&:strip)) &&
            (token = header.first) &&
            # extract data from token
            (meta = Authentication.metadata(token)) &&
            (user_id = meta['user']) &&
            (kenji.env[:user] = Models::Users[id: user_id]) &&
            # authenticate token
            (authentication = Authentication.new(kenji.env[:user])) &&
            authentication.verify_token(token) &&
            # check permissions
            (permissions = meta['permissions']) &&
            (permissions == 'all' || permissions.include?(permission.to_s)) &&
            # check for expired tokens
            (meta['ttl'].nil? || meta['time'] + meta['ttl'] > Time.now.to_i) &&
            # check custom authentication block
            (!block_given? || user_authenticator.call(kenji.env[:user], meta))
          kenji.respond(403, 'Request failed authentication.')
        end
        if header[1] && header[1] == 'renew'
          meta['login'] ||= meta['time']
          meta['time'] = Time.now.to_i
          new_token = authentication.generate_token(meta)
          kenji.header('Firebots-Authentication' => new_token)
        end
        kenji.env[:user]
      end
    end

    # Extracts the metadata from the token.
    #
    def self.metadata(token)
      JSON.parse(split_token(token).first)
    end

    # Splits token.
    #
    def self.split_token(token)
      Base64.decode64(token).split("\0", 2)
    end

  end
end
