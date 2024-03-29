module AtomicLti
  class Jwk < ApplicationRecord
    before_create :ensure_keys_exist

    def generate_keys
      pkey = OpenSSL::PKey::RSA.generate(2048)
      self.pem = pkey.to_pem
      self.kid = pkey.to_jwk.thumbprint
    end

    def alg
      "RS256"
    end

    def private_key
      OpenSSL::PKey::RSA.new(pem)
    end

    def public_key
      pkey = OpenSSL::PKey::RSA.new(pem)
      pkey.public_key
    end

    def to_json
      pkey = OpenSSL::PKey::RSA.new(pem)
      json = JSON::JWK.new(pkey.public_key, kid: kid).as_json
      json["use"] = "sig"
      json["alg"] = alg
      json
    end

    def to_pem
      pkey = OpenSSL::PKey::RSA.new(pem)
      pkey.public_key.to_pem
    end

    def self.current_jwk
      self.last
    end

    private

    def ensure_keys_exist
      if kid.blank?
        generate_keys
      end
    end

  end
end
