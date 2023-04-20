require "rails_helper"

RSpec.describe AtomicLti::OpenId do
  describe "validate_state" do
    it "returns true if open_id_state is found and destroyed" do
      state = { "nonce" => "nonce", "state" => "state" }
      allow(AtomicLti::AuthToken).to receive(:decode).and_return([state])
      allow(AtomicLti::OpenIdState).to receive(:find_by).and_return(double("open_id_state", destroy: true))

      expect(described_class.validate_state("nonce", "state", "token")).to eq(true)
    end

    it "returns false if open_id_state is not found" do
      state = { "nonce" => "nonce", "state" => "state" }
      allow(AtomicLti::AuthToken).to receive(:decode).and_return([state])
      allow(AtomicLti::OpenIdState).to receive(:find_by).and_return(nil)

      expect(described_class.validate_state("nonce", "state", "token")).to eq(false)
    end

    it "returns false if there is an error decoding token" do
      allow(AtomicLti::AuthToken).to receive(:decode).and_raise(StandardError)

      expect(described_class.validate_state("nonce", "state", "token")).to eq(false)
    end

    it "returns false if the nonce doesn't agree" do
      state = { "nonce" => "nonce", "state" => "state" }
      allow(AtomicLti::AuthToken).to receive(:decode).and_return([state])
      allow(AtomicLti::OpenIdState).to receive(:find_by).and_return(double("open_id_state", destroy: true))

      expect(described_class.validate_state("nonce2", "state", "token")).to eq(false)
    end

    it "returns false if the state doesn't agree" do
      state = { "nonce" => "nonce", "state" => "state" }
      allow(AtomicLti::AuthToken).to receive(:decode).and_return([state])
      allow(AtomicLti::OpenIdState).to receive(:find_by).and_return(double("open_id_state", destroy: true))

      expect(described_class.validate_state("nonce", "state2", "token")).to eq(false)
    end

    it "returns false if the token is missing" do
      state = { "nonce" => "nonce", "state" => "state" }
      allow(AtomicLti::AuthToken).to receive(:decode).and_return([state])
      allow(AtomicLti::OpenIdState).to receive(:find_by).and_return(double("open_id_state", destroy: true))

      expect(described_class.validate_state("nonce", "state", "")).to eq(false)
    end

    it "allows the token to be missing when configured to not enforce csrf" do
      AtomicLti.enforce_csrf_protection = false
      state = { "nonce" => "nonce", "state" => "state" }
      allow(AtomicLti::OpenIdState).to receive(:find_by).and_return(double("open_id_state", destroy: true))

      expect(described_class.validate_state("nonce", "state", "")).to eq(true)
      AtomicLti.enforce_csrf_protection = true
    end

    it "still validates the token if present when configured to not enforce csrf" do
      AtomicLti.enforce_csrf_protection = false
      state = { "nonce" => "nonce", "state" => "state" }
      allow(AtomicLti::AuthToken).to receive(:decode).and_return([state])
      allow(AtomicLti::OpenIdState).to receive(:find_by).and_return(double("open_id_state", destroy: true))

      expect(described_class.validate_state("nonce", "state1", "token")).to eq(false)
      AtomicLti.enforce_csrf_protection = true
    end
  end

  describe "generate_state" do
    it "creates a new open_id_state and returns a token" do
      nonce = "nonce"
      state = "state"
      allow(SecureRandom).to receive(:hex).and_return(nonce, state)
      open_id_state = double("open_id_state")
      allow(AtomicLti::OpenIdState).to receive(:create!).with(nonce: nonce).and_return(open_id_state)
      allow(AtomicLti::AuthToken).to receive(:issue_token).with({ nonce: nonce, state: state }, anything).and_return("token")

      expect(described_class.generate_state).to eq([nonce, state, "token"])
    end
  end
end
