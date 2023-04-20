module AtomicLti
  class OpenId
    def self.validate_state(nonce, state, csrf_token)
      if csrf_token.blank? && AtomicLti.enforce_csrf_protection
        return false
      end

      if csrf_token.present?
        csrf = AtomicLti::AuthToken.decode(csrf_token)[0]
        if state.blank? || csrf["state"] != state || csrf["nonce"] != nonce
          return false
        end
      end

      open_id_state = AtomicLti::OpenIdState.find_by(nonce: nonce)
      if !open_id_state
        return false
      end

      open_id_state.destroy
      true
    rescue StandardError => e
      Rails.logger.info("Error decoding token: #{e} - #{e.backtrace}")
      false
    end

    def self.generate_state
      nonce = SecureRandom.hex(64)
      state = SecureRandom.hex(32)

      AtomicLti::OpenIdState.create!(nonce: nonce)
      csrf_token = AtomicLti::AuthToken.issue_token({ state: state, nonce: nonce }, 15.minutes.from_now)

      [nonce, state, csrf_token]
    end
  end
end
