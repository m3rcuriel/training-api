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
      input['email'] = input['email'].downcase

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

      # log email of person who logged in
      p user[:email]

      {
        status: 200,
        token: token,
        user: Account.new.send(:sanitized_user, user),
      }
    end

    # Sends a password reset email
    #
    post '/forgot-password' do

      input = kenji.validated_input do
        validates_regex 'email', matches: /^.+@.+\..+$/
        allow_keys :valid
      end

      user = Models::Users[email: input['email'].downcase]
      kenji.respond(404, 'No such user.') unless user

      send_reset_email(user)

      {
        status: 200,
        message: 'Password reset request received.',
      }
    end

    # Verifies a password reset token and uses it to reset the user's password.
    #
    post '/forgot-password/reset' do

      input = kenji.validated_input do
        validates_type_of 'reset-token', is: String
        validates 'password', with: -> { self.length >= 8 },
          reason: 'must be at least 8 characters.'
      end

      user = verify_token(input['reset-token'], 'password-reset')

      Firebots::Password.new(user).save_password!(input['password'])

      {
        status: 200,
        email: user[:email],
        message: 'Password reset.',
      }
    end

    private

    def send_reset_email(user)
      token = generate_token(user, 'password-reset')
      link = generate_link('/forgot-password/reset', {token: CGI.escape(token)})

      Firebots::Email.send(
        from: 'admin@mg.fremontrobotics.com',
        to: user[:email],
        subject: '3501 Firebots – Password Reset',
        text: <<-EOM
          Hi #{user[:first_name]},

          You appear to have requested a password reset.
          If this was not you, ignore this email.

          Click this link to choose a new password:

          #{link}


          The Firebots Team
        EOM
      )
    end

    def generate_link(endpoint, params)
      URI.const_get(:HTTPS).build(
        host: 'api.mvrt.com',
        path: endpoint,
        query: !params.empty? ? URI.encode_www_form(params) : nil
      ).to_s
    end

    def generate_token(user, permissions)
      Firebots::Authentication.new(user).generate_token(permissions: [permissions])
    end

    # This method is used to verify that a token is valid.
    #
    def verify_token(token, permission)
      meta = Firebots::Authentication.metadata(token)

      unless meta['user'] && meta['permissions'] && meta['permissions'].include?(permission)
        kenji.respond(403, 'Unauthorized.')
      end

      unless meta['time'] && meta['time'] + (3600 * 24) > Time.now.to_i
        kenji.respond(403, 'Token expired.')
      end

      user = Models::Users[id: meta['user']]

      unless user && Firebots::Authentication.new(user).verify_token(token)
        kenji.respond(403, 'Unauthorized.')
      end

      user
    end

  end
end
