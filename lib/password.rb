require 'securerandom'

module Firebots

  class Password

    KEY_LENGTH = 16

    # Initializes the password-crypting library with a user.
    #
    def initialize(user, min_difficulty = 10000)
      @user = user
      @difficulty = min_difficulty
    end

    # Generates a new key derived from password, and saves it to the database.
    #
    def save_password!(password)
      salt, difficulty, key = generate_key(password, difficulty)

      Models::Users.where(id: @user[:id]).update(
        password_difficulty: @difficulty,
        password_salt: salt.unpack('H*').first,
        password_key: key.unpack('H*').first,
        time_updated: Time.now,
      )
    end


    # Verifies a password is valid.
    #
    def verify(password)
      _, difficulty, key = generate_key(password,
                                        @user[:password_difficulty],
                                        [@user[:password_salt]].pack('H*'))
      actual_key = [@user[:password_key]].pack('H*')

      return false unless key == actual_key

      if difficulty < @difficulty
        save_password!(password)
      end
      true
    end

    private
    def generate_key(password, difficulty, salt = nil)
      salt = SecureRandom.random_bytes(12) unless salt
      key = OpenSSL::PKCS5.pbkdf2_hmac(password, salt, @difficulty, KEY_LENGTH,
                                       OpenSSL::Digest::SHA512.new)
      [salt, difficulty, key]
    end
  end
end
