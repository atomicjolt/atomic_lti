module AtomicLti
  class OpenId
    def self.validate_open_id_state(state)
      state = AtomicLti::AuthToken.decode(state)[0]
      if open_id_state = AtomicLti::OpenIdState.find_by(nonce: state["nonce"])
        open_id_state.destroy
        true
      else
        false
      end
    end

    def self.state
      nonce = SecureRandom.hex(64)
      AtomicLti::OpenIdState.create!(nonce: nonce)
      AtomicLti::AuthToken.issue_token({ nonce: nonce })
    end
  end
end
