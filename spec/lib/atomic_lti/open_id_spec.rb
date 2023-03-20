require "rails_helper"

RSpec.describe AtomicLti::OpenId do
  describe "validate_open_id_state" do
    it "returns true if open_id_state is found and destroyed" do
      state = { "nonce" => "nonce" }
      allow(AtomicLti::AuthToken).to receive(:decode).and_return([state])
      allow(AtomicLti::OpenIdState).to receive(:find_by).and_return(double("open_id_state", destroy: true))

      expect(described_class.validate_open_id_state("token")).to eq(true)
    end

    it "returns false if open_id_state is not found" do
      state = { "nonce" => "nonce" }
      allow(AtomicLti::AuthToken).to receive(:decode).and_return([state])
      allow(AtomicLti::OpenIdState).to receive(:find_by).and_return(nil)

      expect(described_class.validate_open_id_state("token")).to eq(false)
    end

    it "returns false if there is an error decoding token" do
      allow(AtomicLti::AuthToken).to receive(:decode).and_raise(StandardError)

      expect(described_class.validate_open_id_state("token")).to eq(false)
    end
  end

  describe "state" do
    it "creates a new open_id_state and returns a token" do
      nonce = "nonce"
      allow(SecureRandom).to receive(:hex).and_return(nonce)
      open_id_state = double("open_id_state")
      allow(AtomicLti::OpenIdState).to receive(:create!).with(nonce: nonce).and_return(open_id_state)
      allow(AtomicLti::AuthToken).to receive(:issue_token).with({ nonce: nonce }).and_return("token")

      expect(described_class.state).to eq("token")
    end
  end
end