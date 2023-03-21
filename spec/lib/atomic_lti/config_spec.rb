require "rails_helper"

RSpec.describe AtomicLti::Config do
  describe "lti_to_lti_advantage" do
    let(:jwk) { double }
    let(:domain) { "domain" }

    context "when a required argument is missing" do
      it "raises an exception" do
        expect do
          described_class.lti_to_lti_advantage(jwk, domain, { title: "title", secure_launch_url: "secure_launch_url" })
        end.to raise_error(AtomicLti::Exceptions::LtiConfigMissing, "Please provide an LTI launch url")
      end
    end
  end
end
