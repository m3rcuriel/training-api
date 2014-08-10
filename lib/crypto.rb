require 'openssl'

module Firebots

  # This module abstracts away the crypto implementation. Internally, it uses
  # the AES cipher, with a length of 256, in CTR mode.
  #
  # The ciphertext and key are Base64 encoded strings. The plaintexts are not
  # encoded.
  #
  module Crypto

    VERSION = 1

    def self.encrypt(key, plaintext)

      cipher = OpenSSL::Cipher::AES256.new(:CTR)
      cipher.encrypt
      cipher.key = Base64.decode64(key)
      iv = cipher.random_iv
      raise unless iv.length == 16


      ciphertext = cipher.update(plaintext) + cipher.final
      mac = OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, key, iv + ciphertext)
      # output format = version byte + 16-byte iv + 32-byte mac + ciphertext
      Base64.strict_encode64(VERSION.chr + iv + mac + ciphertext)
    end

    def self.decrypt(key, cipherbody)
      cipherbody = Base64.decode64(cipherbody)

      raise unless cipherbody[0] == VERSION.chr
      iv, mac, ciphertext = cipherbody[1,16], cipherbody[17,32], cipherbody[49..-1]

      # verify MAC
      return false unless mac == OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, key, iv + ciphertext)

      cipher = OpenSSL::Cipher::AES256.new(:CTR)
      cipher.decrypt
      cipher.key = Base64.decode64(key)
      cipher.iv = iv

      cipher.update(ciphertext) + cipher.final
    end

    def self.random_key
      k = OpenSSL::Cipher::AES256.new(:CTR).random_key
      Base64.strict_encode64(k)
    end

  end
end
