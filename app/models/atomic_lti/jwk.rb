module AtomicLti
  class Jwk < ApplicationRecord
    before_create :generate_keys

    def generate_keys
      if kid.blank?
        pkey = OpenSSL::PKey::RSA.generate(2048)
        self.pem = pkey.to_pem
        self.kid = pkey.to_jwk.thumbprint
      end
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
  end
end
