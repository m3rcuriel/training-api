require 'mail'

module Firebots::InternalAPI::Controllers

  class Account < Kenji::Controller

    # Creates a user. (aka Registration)
    #
    post '/' do
      user = requires_authentication!
      unless user[:permissions] == 'lead' || user[:permissions] == 'mentor'
        kenji.respond(403, 'Only leads/mentors can add users.')
      end

      input = kenji.validated_input do

        validates_type_of 'first_name', 'last_name', 'password', 'username',
          'technical_group', 'nontechnical_group', is: String
        validates_type_of 'title', is: String, when: :is_set

        validates_regex 'email', matches: /^.+@.+\..+$/

        validates 'password', with: -> { self.length >= 8 },
          reason: 'must be at least 8 characters.'

        validates 'email',
          with: -> { Models::Users[email: self].nil? },
          reason: 'must be unique.'
        validates 'username',
          with: -> { Models::Users[username: self].nil? },
          reason: 'must be unique.'

        allow_keys :valid
      end

      password = input.delete('password')
      input[:id] = Rubyflake.generate

      send_invite_email(input['first_name'], input['email'], password, user[:first_name])

      Models::Users.insert(input.merge(
        time_created: Time.now,
        time_updated: Time.now,
        permissions: 'student',
      ))

      user = Models::Users[id: input[:id]]

      Firebots::Password.new(user).save_password!(password)

      all_badges = Models::Badges.all
      all_badges.each do |badge|
        Models::UserBadges.insert({
          user_id: user[:id],
          badge_id: badge[:id],
          status: 'no',
          id: Rubyflake.generate,
          time_created: Time.now,
          time_updated: Time.now,
        })
      end

      {
        status: 200,
        user: sanitized_user(user),
      }
    end

    # Returns information about a user.
    #
    get '/:username' do |username|
      user = requires_authentication!

      user = Models::Users[username:  username]

      {
        status: 200,
        user: sanitized_user(user),
      }
    end

    # Returns information about a user by id.
    #
    get '/id/:id' do |id|
      user = requires_authentication!

      user = Models::Users[id: id]

      {
        status: 200,
        user: sanitized_user(user),
      }
    end

    # Returns information about the currently authenticated user.
    #
    get '/' do
      user = requires_authentication!

      {
        status: 200,
        user: sanitized_user(user),
      }
    end

    # Returns a list of all users.
    #
    get '/all' do
      user = requires_authentication!

      all = Models::Users.all

      {
        status: 200,
        users: all.map {|u| sanitized_user(u)},
      }
    end

    # Edits part of a user, eg. change password, email, etc.
    #
    # TODO: real patch keyword
    #
    route :patch, '/' do
      user = requires_authentication!

      input = kenji.validated_input do

        validates_type_of 'first_name', 'last_name', 'password',
          'technical_group', 'nontechnical_group', 'title',
          is: String, when: :is_set

        validates_regex 'email', matches: /^.+@.+\..+$/, when: :is_set

        validates 'email',
          with: -> { Models::Users[email: self].nil? || user[:email] == self },
          reason: 'must be unique.', when: :is_set

        validates_type_of 'password', is: String, when: :is_set
        validates 'password', with: -> { self.length >= 8 },
          reason: 'must be at least 8 characters.', when: :is_set

        # ensure old password is present and correct when necessary
        validates 'old_password',
          when: -> { !self['password'].nil? || !self['email'].nil? },
          with: -> { self && Firebots::Password.new(user).verify(self) },
          reason: 'is invalid.'

        allow_keys :valid
      end

      # save new password, if requested
      Firebots::Password.new(user).save_password!(input['password']) if input['password']

      # save other fields to the database
      input.delete('password')
      input.delete('old_password')

      Models::Users.where(id: user[:id]).update(input.merge(
        time_updated: Time.now
      )) unless input.empty?

      new_user = Models::Users[id: user[:id]]

      {
        status: 200,
        user: sanitized_user(new_user),
      }
    end


    # -- Helper methods
    private

    def sanitized_user(user)
      Hash[user.select do |k,_|
        [:id, :first_name, :last_name, :username, :email, :permissions,
          :time_created, :time_updated, :title, :technical_group,
          :nontechnical_group].include?(k)
      end.map(&Helpers::HashPairSanitizer)]
    end

    def send_invite_email(first_name, email, password, inviter_first_name)
      mail = Mail.new do
        from 'admin@oflogan.com'
        to email
        subject '3501 FRC Training'
        body <<-EOM
          Hello #{first_name},

          #{inviter_first_name} has added you to the FRC 3501 training site: https://app.oflogan.com.

          Your temporary password is `#{password}`. You should change it immediately.

          To get a proper avatar, sign up with your email at https://gravatar.com.

          Reply to this email to get help with anything.
        EOM
      end

      mail.deliver!
    end
  end
end
