require "rails_helper"

RSpec.describe AtomicLti::AuthToken do
  describe "issue_token" do
    let(:payload) { { "key" => "value" } }
    let(:exp) { 24.hours.from_now }
    let(:secret) { "secret" }
    let(:aud) { "aud" }
    let(:header_fields) { { "alg" => "HS512" } }

    it "returns a JWT" do
      expect(JWT).to receive(:encode).with(payload, secret, "HS512", header_fields)
      described_class.issue_token(payload, exp, secret, aud, header_fields)
    end
  end

  describe "valid?" do
    let(:token) { "token" }
    let(:secret) { "secret" }
    let(:algorithm) { "HS512" }

    it "decodes the token" do
      expect(described_class).to receive(:decode).with(token, secret, true, algorithm)
      described_class.valid?(token, secret, algorithm)
    end
  end

  describe "decode" do
    let(:token) { "token" }
    let(:secret) { "secret" }
    let(:validate) { true }
    let(:algorithm) { "HS512" }

    it "decodes the token" do
      expect(JWT).to receive(:decode).with(token, secret, validate, { algorithm: algorithm })
      described_class.decode(token, secret, validate, algorithm)
    end
  end
end