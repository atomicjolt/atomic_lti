module AtomicLti
  class OpenId
    def self.validate_state(nonce, state)
      if state.blank?
        return false
      end

      open_id_state = AtomicLti::OpenIdState.find_by(state: state)
      if !open_id_state
        return false
      end

      open_id_state.destroy

      # Check that the state hasn't expired
      if open_id_state.created_at < 10.minutes.ago
        return false
      end

      if nonce != open_id_state.nonce
        return false
      end

      true
    end

    def self.generate_state
      nonce = SecureRandom.hex(64)
      state = SecureRandom.hex(32)
      AtomicLti::OpenIdState.create!(nonce: nonce, state: state)
      [nonce, state]
    end
  end
end
