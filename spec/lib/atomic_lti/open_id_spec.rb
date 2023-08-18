require "rails_helper"

RSpec.describe AtomicLti::OpenId do
  describe "validate_state" do
    it "returns true if open_id_state is found and destroyed" do
      open_id_state = AtomicLti::OpenIdState.create!(nonce: "nonce", state: "state")
      expect(described_class.validate_state(open_id_state.nonce, open_id_state.state, true)).to eq(true)
    end

    it "returns false if open_id_state is not found" do
      expect(described_class.validate_state("nonce", "not_real_state", true)).to eq(false)
    end

    it "returns false if the nonce doesn't agree" do
      open_id_state = AtomicLti::OpenIdState.create!(nonce: "nonce", state: "state")
      expect(described_class.validate_state("fake_nonce", open_id_state.state, true)).to eq(false)
      open_id_state.destroy
    end
  end

  describe "generate_state" do
    it "creates a new open_id_state and returns a token" do
      nonce, state = described_class.generate_state
      expect(nonce.length).to eq(128)
      expect(state.length).to eq(64)
    end
  end
end
