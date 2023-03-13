require "rails_helper"

RSpec.describe AtomicLti::OpenId do
  describe "validate_open_id_state" do
    it "validates state provided by the platform" do
      state = AtomicLti::OpenId.state
      expect(state.present?).to eq true
    end
  end
  describe "state" do
    it "generates state to be sent to the platform" do
      AtomicLti.jwt_secret = "test"
      state = AtomicLti::OpenId.state
      expect(AtomicLti::OpenId.validate_open_id_state(state)).to be true
    end
  end
end
