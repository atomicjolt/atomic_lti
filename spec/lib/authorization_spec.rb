require "rails_helper"
require "support/lti_advantage_helper"

module AtomicLti
  RSpec.describe AtomicLti::Authorization do
    describe "validate_token" do
      it "validates the provided token and returns true" do
        mocks = setup_canvas_lti_advantage
        token = Authorization.validate_token(mocks[:id_token])
        expect(token.dig("errors", "errors")).to eq({})
      end
    end

    describe "validate_lti!" do
      it "throws an exception if the LTI version is invalid" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token[AtomicLti::Definitions::LTI_VERSION] = "1.4.3"
          { decoded_id_token: decoded_id_token }
        end
        expect {
          Authorization.validate_lti!(mocks[:decoded_id_token])
        }.to raise_error(AtomicLti::Exceptions::InvalidLTIVersion)
      end

      it "ensures the LTI launch is valid" do
        mocks = setup_canvas_lti_advantage
        valid = Authorization.validate_lti!(mocks[:decoded_id_token])
        expect(valid).to eq(true)
      end
    end

    describe "valid_lti_version?" do
      it "returns true when the LTI version is valid" do
        mocks = setup_canvas_lti_advantage
        valid = Authorization.valid_lti_version?(mocks[:decoded_id_token])
        expect(valid).to eq(true)
      end

      it "returns false when the LTI version is invalidvalid" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token[AtomicLti::Definitions::LTI_VERSION] = "1.4.3"
          { decoded_id_token: decoded_id_token }
        end
        valid = Authorization.valid_lti_version?(mocks[:decoded_id_token])
        expect(valid).to eq(false)
      end
    end

    describe "sign_tool_jwt" do
      it "returns a signed jwt" do
        mocks = setup_canvas_lti_advantage
        payload = {
          iss:  mocks["iss"],
          sub: mocks["client_id"],
          aud: mocks["iss"],
          iat: Time.now.to_i,
          exp: Time.now.to_i + 300,
          jti: SecureRandom.hex(10),
        }
        signed = Authorization.sign_tool_jwt(payload)
        jwk = Jwk.current_jwk
        decoded_token, _keys = JWT.decode(signed, jwk.public_key, true, { algorithms: ["RS256"] })

        expect(decoded_token["iss"]).to eq(payload[:iss])
      end
    end

    describe "client_assertion" do
      it "returns a signed tool jwt" do
        mocks = setup_canvas_lti_advantage
        signed = Authorization.client_assertion(iss: mocks[:iss], deployment_id: mocks[:deployment_id])
        jwk = Jwk.current_jwk
        decoded_token, _keys = JWT.decode(signed, jwk.public_key, true, { algorithms: ["RS256"] })
        expect(decoded_token["iss"]).to eq(mocks[:client_id])
        expect(decoded_token["sub"]).to eq(mocks[:client_id])
        expect(decoded_token["aud"]).to eq("https://canvas.instructure.com/login/oauth2/token")
      end

      it "throws an exception when the deployment can't be found" do
        mocks = setup_canvas_lti_advantage
        expect {
          Authorization.client_assertion(iss: mocks[:iss], deployment_id: 'bad_id')
        }.to raise_error(AtomicLti::Exceptions::NoLTIDeployment)
      end

      it "throws an exception when the install can't be found" do
        mocks = setup_canvas_lti_advantage
        deployment = AtomicLti::Deployment.find_by(iss: mocks[:iss], deployment_id: mocks[:deployment_id])
        deployment.install.destroy
        expect {
          Authorization.client_assertion(iss: mocks[:iss], deployment_id: mocks[:deployment_id])
        }.to raise_error(AtomicLti::Exceptions::NoLTIInstall)
      end

      it "throws an exception when the platform can't be found" do
        mocks = setup_canvas_lti_advantage
        deployment = AtomicLti::Deployment.find_by(iss: mocks[:iss], deployment_id: mocks[:deployment_id])
        deployment.platform.destroy
        expect {
          Authorization.client_assertion(iss: mocks[:iss], deployment_id: mocks[:deployment_id])
        }.to raise_error(AtomicLti::Exceptions::NoLTIPlatform)
      end
    end

    describe "request_token" do
      it "returns a request token" do
        mocks = setup_canvas_lti_advantage
        stub_canvas_token
        token = Authorization.request_token(iss: mocks[:iss], deployment_id: mocks[:deployment_id])
        expect(token["expires_in"]).to be_present
      end

      it "throws an exception when the deployment can't be found" do
        mocks = setup_canvas_lti_advantage
        expect {
          Authorization.request_token(iss: mocks[:iss], deployment_id: 'bad_id')
        }.to raise_error(AtomicLti::Exceptions::NoLTIDeployment)
      end
    end

    describe "request_token_uncached" do
      it "returns a token" do
        mocks = setup_canvas_lti_advantage
        stub_canvas_token
        token = Authorization.request_token_uncached(iss: mocks[:iss], deployment_id: mocks[:deployment_id])
        expect(token["expires_in"]).to be_present
      end

      it "throws an exception when the deployment can't be found" do
        mocks = setup_canvas_lti_advantage
        stub_canvas_token
        expect {
          Authorization.request_token_uncached(iss: mocks[:iss], deployment_id: 'bad_id')
        }.to raise_error(AtomicLti::Exceptions::NoLTIDeployment)
      end

      it "throws an exception when the platform can't be found" do
        mocks = setup_canvas_lti_advantage
        stub_canvas_token
        deployment = AtomicLti::Deployment.find_by(iss: mocks[:iss], deployment_id: mocks[:deployment_id])
        deployment.platform.destroy
        expect {
          Authorization.request_token_uncached(iss: mocks[:iss], deployment_id: mocks[:deployment_id])
        }.to raise_error(AtomicLti::Exceptions::NoLTIPlatform)
      end
    end

  end
end
