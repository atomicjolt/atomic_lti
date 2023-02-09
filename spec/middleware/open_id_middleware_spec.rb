require "rails_helper"
require "support/lti_advantage_helper"

module AtomicLti
  FactoryBot.define do
    sequence :client_id do |n|
      "1200000#{n}"
    end
  end

  RSpec.describe AtomicLti::OpenIdMiddleware do

    let(:env) { Rack::MockRequest.env_for }

    # dummy app to validate success
    let(:app) { ->(env) { [200, {}, [env]] } }

    subject { OpenIdMiddleware.new(app) }


    before do
      AtomicLti.oidc_init_path = '/oidc/init'
      AtomicLti.oidc_redirect_path = '/oidc/redirect'
      AtomicLti.target_link_path_prefixes = ['/lti_launches']
      AtomicLti.jwt_secret = "bar"
    end

    it "Passes non lti launch request" do
      status, _headers, _response = subject.call(env)
      expect(status).to eq(200)
    end

    describe "init" do
      it "Handles init" do
        setup_canvas_lti_advantage
        req_env = Rack::MockRequest.env_for("https://registrar.atomicjolt.xyz/oidc/init", {method: "POST", params: {"iss" => "https://canvas.instructure.com"}})
        status, _headers, _response = subject.call(req_env)
        expect(status).to eq(302)
      end
    end

    describe "redirect" do
      it "handles redirect" do
        mocks = setup_canvas_lti_advantage
        req_env = Rack::MockRequest.env_for("https://registrar.atomicjolt.xyz/oidc/redirect", {method: "POST", params: mocks[:params]})
        status, _headers, response = subject.call(req_env)
        expect(status).to eq(200)
        expect(response[0].include?(" <form action=\"http://atomicjolt-registrar.atomicjolt.xyz/lti_launches\" method=\"POST\">")).to eq(true)
      end

      it "returns an error when the KID is missing from the JWT header" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token, canvas_jwk|
          id_token = JWT.encode(
            decoded_id_token,
            canvas_jwk.private_key,
            canvas_jwk.alg,
            kid: "",
            typ: "JWT",
          )
          {
            id_token: id_token
          }
        end
        req_env = Rack::MockRequest.env_for("https://registrar.atomicjolt.xyz/oidc/redirect", {method: "POST", params: mocks[:params]})
        expect { subject.call(req_env) }.to raise_error(JWT::DecodeError)
      end

      it "returns an error when an incorrect KID is passed in the JWT header" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token, canvas_jwk|
          id_token = JWT.encode(
            decoded_id_token,
            canvas_jwk.private_key,
            canvas_jwk.alg,
            kid: "2345",
            typ: "JWT",
          )
          {
            id_token: id_token
          }
        end
        req_env = Rack::MockRequest.env_for("https://registrar.atomicjolt.xyz/oidc/redirect", {method: "POST", params: mocks[:params]})
        expect { subject.call(req_env) }.to raise_error(JWT::DecodeError)
      end

      it "returns an error when the LTI version is invalid" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token[AtomicLti::Definitions::LTI_VERSION] = "1.4.3"
          { decoded_id_token: decoded_id_token }
        end
        req_env = Rack::MockRequest.env_for("https://registrar.atomicjolt.xyz/oidc/redirect", {method: "POST", params: mocks[:params]})
        expect { subject.call(req_env) }.to raise_error(AtomicLti::Exceptions::InvalidLTIVersion)
      end

      it "returns an error when the LTI version is not passed" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token.delete(AtomicLti::Definitions::LTI_VERSION)
          { decoded_id_token: decoded_id_token }
        end
        req_env = Rack::MockRequest.env_for("https://registrar.atomicjolt.xyz/oidc/redirect", {method: "POST", params: mocks[:params]})
        expect { subject.call(req_env) }.to raise_error(AtomicLti::Exceptions::NoLTIVersion)
      end

      it "returns an error when the JWT isn't an LTI 1.3 JWT" do
        mocks = setup_canvas_lti_advantage
        bad_token = {
          "name" => "bad_lti_token",
        }
        canvas_jwk = mocks[:canvas_jwk]
        id_token ||= JWT.encode(
          bad_token,
          canvas_jwk.private_key,
          canvas_jwk.alg,
          kid: canvas_jwk.kid,
          typ: "JWT",
        )
        params = {
          "id_token" => id_token,
          "state" => mocks[:state],
        }
        req_env = Rack::MockRequest.env_for("https://registrar.atomicjolt.xyz/oidc/redirect", {method: "POST", params: params})
        expect { subject.call(req_env) }.to raise_error(AtomicLti::Exceptions::InvalidLTIToken)
      end
    end

    describe "lti_launches" do
      it "launches" do
        mocks = setup_canvas_lti_advantage
        req_env = Rack::MockRequest.env_for("http://atomicjolt-registrar.atomicjolt.xyz/lti_launches", {method: "POST", params: mocks[:params]})
        status, _headers, response = subject.call(req_env)

        returned_env = response[0]
        expect(status).to eq(200)
        expect(returned_env['atomic.validated.id_token']).to eq(mocks[:id_token])
        expect(returned_env['atomic.validated.decoded_id_token']).to eq(mocks[:decoded_id_token])
      end

      it "doesn't launch with invalid token" do
        mocks = setup_canvas_lti_advantage

        other_jwk = AtomicLti::Jwk.new
        other_jwk.generate_keys

        fake_token = JWT.encode(
          @decoded_id_token,
          other_jwk.private_key,
          @canvas_jwk.alg,
          kid: @canvas_jwk.kid,
          typ: "JWT",
        )

        params = {
          id_token: fake_token,
          state: mocks[:state]
        }

        req_env = Rack::MockRequest.env_for("http://atomicjolt-registrar.atomicjolt.xyz/lti_launches", {method: "POST", params: params})
        status, _headers, response = subject.call(req_env)

        returned_env = response[0]
        expect(status).to eq(401)
        expect(returned_env['atomic.validated.id_token']).to eq(nil)
        expect(returned_env['atomic.validated.decoded_id_token']).to eq(nil)
      end
    end
  end
end