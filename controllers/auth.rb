require 'validate/kenji'

# TODO: temporary, mac validation
require 'konfiguration'
require 'openssl'
require 'base64'
require 'cgi'

require 'lib/database'
require 'lib/authentication'
require 'lib/password'


module Firebots::InternalAPI::Controllers

  class Auth < Kenji::Controller
    include Firebots::Authentication::KenjiRequireMethod

    # This generates an authentication token for a user.
    #
    # In order for us to authenticate that it is indeed your app that is
    # requesting an authentication token, you must include a message
    # authentication code in the request. The code is generated using by
    # authenticating the `email` value with the app secret as key:
    #
    #   mac = HMAC-SHA256(app-secret, email)
    #
    # The resulting MAC must be base64-encoded.
    #
    # Sample request:
    #
    #   {
    #       "email": "some@email.tld",
    #       "password": "plaintext-password",
    #       "app": 9223372036854775807,
    #       "mac": "c2RqYma2FsZqXNiZ3a2RhaHNiaXVsYY="
    #   }
    #
    # Response:
    #
    #   {
    #       "token": "a2Fsc2RqYmZqa2RhaHNiaXVsYXNiZ3Y="
    #   }
    #
    post '/login' do

      input = kenji.validated_input do
        validates_type_of 'app', is: String
        validates_type_of 'password', 'mac', is: String
        validates_regex 'email', matches: /^.+@.+\..+$/
        validates_type_of 'ttl', is: Integer, when: :is_set
        allow_keys :valid
      end

      user = Models::Users[email: input['email']]
      unless user && Firebots::Password.new(user).verify(input['password'])
        kenji.respond(403, 'Invalid credentials.')
      end

      app = Konfiguration.apps(input['app'])
      mac = Base64.decode64(input['mac'])
      unless app && OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new,
                                         app['secret'], input['email']) == mac
        kenji.respond(403, 'Failed app authentication.')
      end

      # now that we have a user, generate the tokens
      meta = {permissions: :all, app: app['id']}
      meta[:ttl] = input['ttl'] if input['ttl']
      token = Firebots::Authentication.new(user).generate_token(meta)

      {
        status: 200,
        token: token,
        user: Account.new.send(:sanitized_user, user),
      }
    end

  end
end
