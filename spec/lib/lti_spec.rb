require "rails_helper"
require "support/lti_advantage_helper"

module AtomicLti
  RSpec.describe AtomicLti::Lti do
    describe "validate!" do
      it "throws an exception if the token is blank" do
        expect {
          Lti.validate!(nil)
        }.to raise_error(AtomicLti::Exceptions::InvalidLTIToken)
      end

      it "throws an exception if the LTI version is invalid" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token[AtomicLti::Definitions::LTI_VERSION] = "1.4.3"
          { decoded_id_token: decoded_id_token }
        end
        expect {
          Lti.validate!(mocks[:decoded_id_token])
        }.to raise_error(AtomicLti::Exceptions::InvalidLTIVersion)
      end

      it "throws an exception if the iss is missing" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token.delete("iss")
          { decoded_id_token: decoded_id_token }
        end
        expect {
          Lti.validate!(mocks[:decoded_id_token])
        }.to raise_error(AtomicLti::Exceptions::InvalidLTIToken)
      end

      it "throws an exception if the deployment_id is missing" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token.delete(AtomicLti::Definitions::DEPLOYMENT_ID)
          { decoded_id_token: decoded_id_token }
        end
        expect {
          Lti.validate!(mocks[:decoded_id_token])
        }.to raise_error(AtomicLti::Exceptions::InvalidLTIToken)
      end

      it "ensures the LTI token is valid" do
        mocks = setup_canvas_lti_advantage
        valid = Lti.validate!(mocks[:decoded_id_token])
        expect(valid).to eq(true)
      end
    end

    describe "valid_version?" do
      it "returns true when the LTI version is valid" do
        mocks = setup_canvas_lti_advantage
        valid = Lti.valid_version?(mocks[:decoded_id_token])
        expect(valid).to eq(true)
      end

      it "returns false when the LTI version is invalid" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token[AtomicLti::Definitions::LTI_VERSION] = "1.4.3"
          { decoded_id_token: decoded_id_token }
        end
        valid = Lti.valid_version?(mocks[:decoded_id_token])
        expect(valid).to eq(false)
      end

      it "returns false when the LTI version is not present" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token.delete(AtomicLti::Definitions::LTI_VERSION)
          { decoded_id_token: decoded_id_token }
        end
        valid = Lti.valid_version?(mocks[:decoded_id_token])
        expect(valid).to eq(false)
      end
    end

  end
end
