require "rails_helper"
require "support/lti_advantage_helper"
require "support/config_helpers"

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

      it "throws an exception if the target link uri claim is missing" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token.delete(AtomicLti::Definitions::TARGET_LINK_URI_CLAIM)
          { decoded_id_token: decoded_id_token }
        end
        expect {
          Lti.validate!(mocks[:decoded_id_token])
        }.to raise_error(AtomicLti::Exceptions::InvalidLTIToken)
      end

      it "throws an exception if the resource link claim is missing" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token.delete(AtomicLti::Definitions::RESOURCE_LINK_CLAIM)
          { decoded_id_token: decoded_id_token }
        end
        expect {
          Lti.validate!(mocks[:decoded_id_token])
        }.to raise_error(AtomicLti::Exceptions::InvalidLTIToken)
      end

      it "throws an exception if the message claim is missing" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token.delete(AtomicLti::Definitions::MESSAGE_TYPE)
          { decoded_id_token: decoded_id_token }
        end
        expect {
          Lti.validate!(mocks[:decoded_id_token])
        }.to raise_error(AtomicLti::Exceptions::InvalidLTIToken)
      end

      it "throws an exception if the roles claim is missing" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token.delete(AtomicLti::Definitions::ROLES_CLAIM)
          { decoded_id_token: decoded_id_token }
        end
        expect {
          Lti.validate!(mocks[:decoded_id_token])
        }.to raise_error(AtomicLti::Exceptions::InvalidLTIToken)
      end

      it "allows only custom roles when role_enforcement_mode is DEFAULT" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token[AtomicLti::Definitions::ROLES_CLAIM] = ["invalid_role"]
          { decoded_id_token: decoded_id_token }
        end
        with_config(role_enforcement_mode: "DEFAULT") do
          valid = Lti.validate!(mocks[:decoded_id_token])
          expect(valid).to eq(true)
        end
      end

      it "disallows no provided roles" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token[AtomicLti::Definitions::ROLES_CLAIM] = []
          { decoded_id_token: decoded_id_token }
        end
        expect {
          valid = Lti.validate!(mocks[:decoded_id_token])
          expect(valid).to eq(true)
        }.to raise_error(AtomicLti::Exceptions::InvalidLTIToken)
      end

      it "disallows only custom roles when role_enforcement_mode is STRICT" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token[AtomicLti::Definitions::ROLES_CLAIM] = ["invalid_role"]
          { decoded_id_token: decoded_id_token }
        end
        with_config(role_enforcement_mode: "STRICT") do
          expect {
            Lti.validate!(mocks[:decoded_id_token])
          }.to raise_error(AtomicLti::Exceptions::InvalidLTIToken)
        end
      end

      it "handles roles claim with invalid members" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token[AtomicLti::Definitions::ROLES_CLAIM] = [
            "invalid_role",
            AtomicLti::Definitions::LEARNER_CONTEXT_ROLE,
          ]
          { decoded_id_token: decoded_id_token }
        end
        with_config(role_enforcement_mode: "STRICT") do
          valid = Lti.validate!(mocks[:decoded_id_token])
          expect(valid).to eq(true)
        end
      end

      it "throws an exception if the User (sub) claim is missing" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token.delete("sub")
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

      it "handles a deep link payload" do
        mocks = setup_canvas_lti_advantage(
          message_type: "LtiDeepLinkingRequest",
        )
        valid = Lti.validate!(mocks[:decoded_id_token])
        expect(valid).to eq(true)
      end

      it "throws an exception if the azp is invalid" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token["aud"] = ["aud1", "aud2"]
          decoded_id_token["azp"] = "else"
          { decoded_id_token: decoded_id_token }
        end
        expect {
          Lti.validate!(mocks[:decoded_id_token])
        }.to raise_error(AtomicLti::Exceptions::InvalidLTIToken)
      end

      it "throws an exception when the aud is missing" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token.delete("aud")
          { decoded_id_token: decoded_id_token }
        end
        expect {
          Lti.validate!(mocks[:decoded_id_token])
        }.to raise_error(AtomicLti::Exceptions::InvalidLTIToken)
      end

      it "throws an error when the azp is missing" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token["aud"] = ["aud1", "aud2"]
          decoded_id_token.delete("azp")
          { decoded_id_token: decoded_id_token }
        end
        expect {
          Lti.validate!(mocks[:decoded_id_token])
        }.to raise_error(AtomicLti::Exceptions::InvalidLTIToken)
      end

      it "returns true when the aud is an array of one" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token["aud"] = ["aud1"]
          decoded_id_token.delete("azp")
          { decoded_id_token: decoded_id_token }
        end
        valid = Lti.validate!(mocks[:decoded_id_token])
        expect(valid).to eq(true)
      end

      it "returns true when the azp is an array of more than one" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token["aud"] = ["aud1", "aud2"]
          decoded_id_token["azp"] = "aud2"
          { decoded_id_token: decoded_id_token }
        end
        valid = Lti.validate!(mocks[:decoded_id_token])
        expect(valid).to eq(true)
      end
    end

    describe "client_id" do
      it "works when aud is an array of one" do
        id_token = {
          "aud" => ["962fa4d8-bcbf-49a0-94b2-2de05ad274af"],
          "azp" => "962fa4d8-bcbf-49a0-94b2-2de05ad274af",
        }
        expect(described_class.client_id(id_token)).to eq("962fa4d8-bcbf-49a0-94b2-2de05ad274af")
      end
      it "works when aud is a string" do
        id_token = {
          "aud" => "962fa4d8-bcbf-49a0-94b2-2de05ad274af",
          "azp" => "962fa4d8-bcbf-49a0-94b2-2de05ad274af",
        }
        expect(described_class.client_id(id_token)).to eq("962fa4d8-bcbf-49a0-94b2-2de05ad274af")
      end
      it "returns azp when aud is a array of multiple auds" do
        id_token = {
          "aud" => ["962fa4d8-bcbf-49a0-94b2-2de05ad274af", "something else"],
          "azp" => "962fa4d8-bcbf-49a0-94b2-2de05ad274af",
        }
        expect(described_class.client_id(id_token)).to eq("962fa4d8-bcbf-49a0-94b2-2de05ad274af")
      end
      it "returns nil when aud is a array of multiple with no azp" do
        id_token = {
          "aud" => ["962fa4d8-bcbf-49a0-94b2-2de05ad274af", "something else"],
        }
        expect(described_class.client_id(id_token)).not_to be_present
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
