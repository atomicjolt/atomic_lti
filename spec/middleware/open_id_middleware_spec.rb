require "rails_helper"
require "support/lti_advantage_helper"

module AtomicLti
  RSpec.describe AtomicLti::OpenIdMiddleware do
    let(:env) { Rack::MockRequest.env_for }

    # dummy app to validate success
    let(:app) { ->(env) { [200, {}, [env]] } }

    subject { OpenIdMiddleware.new(app) }

    before do
      AtomicLti.oidc_init_path = "/oidc/init"
      AtomicLti.oidc_redirect_path = "/oidc/redirect"
      AtomicLti.target_link_path_prefixes = ["/lti_launches"]
      AtomicLti.default_deep_link_path = "/lti_launches"
      AtomicLti.jwt_secret = "bar"
      AtomicLti.scopes = AtomicLti::Definitions.scopes.join(" ")
    end

    it "Passes non lti launch request" do
      status, _headers, _response = subject.call(env)
      expect(status).to eq(200)
    end

    describe "init" do
      let(:renderer) { ApplicationController.renderer }

      before do
        allow(AtomicLti::OpenId).to receive(:generate_state).and_return(["nonce", "state", "csrf"])
        allow(ApplicationController.renderer).to receive(:render).and_return(renderer)
      end

      it "Throws an exception when the platform is invalid" do
        setup_canvas_lti_advantage
        req_env = Rack::MockRequest.env_for(
          "https://test.atomicjolt.xyz/oidc/init",
          { method: "POST", params: { "iss" => "badvalue" } },
        )
        expect { subject.call(req_env) }.to raise_error(AtomicLti::Exceptions::NoLTIPlatform)
      end

      it "sets cookies" do
        setup_canvas_lti_advantage
        req_env = Rack::MockRequest.env_for(
          "https://test.atomicjolt.xyz/oidc/init",
          { method: "POST", params: { "iss" => "https://canvas.instructure.com" } },
        )
        _status, headers, _response = subject.call(req_env)
        expect(headers["Set-Cookie"]).
          to match("open_id_cookie_storage=1; path=/; max-age=31536000; secure; SameSite=None")
        expect(headers["Set-Cookie"]).
          to match("open_id_state=csrf; path=/; max-age=300; secure; SameSite=None")
      end

      context "with cookies" do
        it "renders a 302 redirect" do
          setup_canvas_lti_advantage
          req_env = Rack::MockRequest.env_for(
            "https://test.atomicjolt.xyz/oidc/init",
            { method: "POST", params: { "iss" => "https://canvas.instructure.com" } },
          )
          req_env["HTTP_COOKIE"] = "open_id_cookie_storage=1"
          status, headers, _response = subject.call(req_env)
          expect(status).to eq(302)
          expect(headers["Location"]).to start_with "https://canvas.instructure.com/api/lti/authorize_redirect?client_id="
        end
      end

      context "without cookies" do
        let(:req_env) do
          Rack::MockRequest.env_for(
            "https://test.atomicjolt.xyz/oidc/init",
            { method: "POST", params: { "iss" => "https://canvas.instructure.com" } },
          )
        end
        before do
          setup_canvas_lti_advantage
        end
        it "renders a view" do
          status, _headers, _response = subject.call(req_env)
          expect(status).to eq(200)
          expect(renderer).to have_received(:render).with(:html, hash_including({ template: "atomic_lti/shared/init" }))
        end
        it "passes settings" do
          _status, _headers, _response = subject.call(req_env)
          expect(renderer).to have_received(:render).with(
            :html,
            hash_including(
              {
                assigns: hash_including(
                  {
                    settings: {
                      state: "state",
                      csrf_token: "csrf",
                      response_url: start_with("https://canvas.instructure.com/api/lti/authorize_redirect"),
                      lti_storage_params: nil,
                      privacy_policy_url: "#",
                      privacy_policy_message: nil,
                      relaunch_init_url: "https://test.atomicjolt.xyz/oidc/init?iss=https%3A%2F%2Fcanvas.instructure.com",
                    },
                  },
                ),
              },
            ),
          )
        end
      end
      context "with lti storage params" do
        let(:req_env) do
          Rack::MockRequest.env_for(
            "https://test.atomicjolt.xyz/oidc/init",
            { method: "POST",
              params: { "iss" => "https://canvas.instructure.com", "lti_storage_target" => "_parent" } },
          )
        end
        before do
          setup_canvas_lti_advantage
        end
        it "passes lti storage params" do
          _status, _headers, _response = subject.call(req_env)
          expect(renderer).to have_received(:render).with(
            :html,
            hash_including(
              {
                assigns: hash_including(
                  {
                    settings: hash_including(
                      {
                        lti_storage_params: {
                          target: "_parent",
                          origin_support_broken: anything,
                          oidc_url: "https://canvas.instructure.com/api/lti/authorize_redirect",
                        },
                      },
                    ),
                  },
                ),
              },
            ),
          )
        end
      end
    end

    describe "redirect" do
      it "handles redirect" do
        mocks = setup_canvas_lti_advantage
        req_env = Rack::MockRequest.env_for(
          "https://test.atomicjolt.xyz/oidc/redirect",
          { method: "POST", params: mocks[:params] },
        )
        status, _headers, response = subject.call(req_env)
        expect(status).to eq(200)
        expect(response[0]).to match('<form action="http://atomicjolt-test.atomicjolt.xyz/lti_launches" method="POST">')
      end

      it "passes lti storage params" do
        mocks = setup_canvas_lti_advantage
        req_env = Rack::MockRequest.env_for(
          "https://test.atomicjolt.xyz/oidc/redirect",
          { method: "POST", params: mocks[:params].merge({ "lti_storage_target" => "_parent" }) },
        )
        status, _headers, response = subject.call(req_env)
        expect(status).to eq(200)
        expect(response[0]).to match('"lti_storage_params":{"target":"_parent"')
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
            id_token: id_token,
          }
        end
        req_env = Rack::MockRequest.env_for(
          "https://test.atomicjolt.xyz/oidc/redirect",
          { method: "POST", params: mocks[:params] },
        )
        status, _headers, response = subject.call(req_env)
        expect(status).to eq(401)
        expect(response[0]).to match("The launch token is invalid.")
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
            id_token: id_token,
          }
        end
        req_env = Rack::MockRequest.env_for(
          "https://test.atomicjolt.xyz/oidc/redirect",
          { method: "POST", params: mocks[:params] },
        )
        status, _headers, response = subject.call(req_env)
        expect(status).to eq(401)
        expect(response[0]).to match("The launch token is invalid.")
      end

      it "returns an error when the LTI version is invalid" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token[AtomicLti::Definitions::LTI_VERSION] = "1.4.3"
          { decoded_id_token: decoded_id_token }
        end
        req_env = Rack::MockRequest.env_for(
          "https://test.atomicjolt.xyz/oidc/redirect",
          { method: "POST", params: mocks[:params] },
        )
        expect { subject.call(req_env) }.to raise_error(AtomicLti::Exceptions::InvalidLTIVersion)
      end

      it "returns an error when the LTI version is not passed" do
        mocks = setup_canvas_lti_advantage do |decoded_id_token|
          decoded_id_token.delete(AtomicLti::Definitions::LTI_VERSION)
          { decoded_id_token: decoded_id_token }
        end
        req_env = Rack::MockRequest.env_for(
          "https://test.atomicjolt.xyz/oidc/redirect",
          { method: "POST", params: mocks[:params] },
        )
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
        req_env = Rack::MockRequest.env_for(
          "https://test.atomicjolt.xyz/oidc/redirect",
          { method: "POST", params: params },
        )
        expect { subject.call(req_env) }.to raise_error(AtomicLti::Exceptions::InvalidLTIToken)
      end
    end

    describe "lti deep link launches" do
      it "redirects after the OIDC flow" do
        mocks = setup_canvas_lti_advantage(
          message_type: "LtiDeepLinkingRequest",
        )
        req_env = Rack::MockRequest.env_for(
          "http://atomicjolt-test.atomicjolt.xyz/oidc/redirect",
          { method: "POST", params: mocks[:params] },
        )
        status, _headers, response = subject.call(req_env)

        expect(status).to eq(200)
        expect(response[0]).to match('<form action="http://atomicjolt-test.atomicjolt.xyz/lti_launches" method="POST">')
      end

      it "LTI launches" do
        mocks = setup_canvas_lti_advantage(
          message_type: "LtiDeepLinkingRequest",
        )
        req_env = Rack::MockRequest.env_for(
          "http://atomicjolt-test.atomicjolt.xyz/lti_launches",
          { method: "POST", params: mocks[:params] },
        )
        status, _headers, response = subject.call(req_env)

        returned_env = response[0]
        expect(status).to eq(200)
        expect(returned_env["atomic.validated.id_token"]).to eq(mocks[:id_token])
        expect(returned_env["atomic.validated.decoded_id_token"]).to eq(mocks[:decoded_id_token])
      end
    end

    describe "lti_launches" do
      it "launches" do
        mocks = setup_canvas_lti_advantage
        req_env = Rack::MockRequest.env_for(
          "http://atomicjolt-test.atomicjolt.xyz/lti_launches",
          { method: "POST", params: mocks[:params] },
        )
        status, _headers, response = subject.call(req_env)

        returned_env = response[0]
        expect(status).to eq(200)
        expect(returned_env["atomic.validated.id_token"]).to eq(mocks[:id_token])
        expect(returned_env["atomic.validated.decoded_id_token"]).to eq(mocks[:decoded_id_token])
      end

      it "launches with csrf cookie" do
        mocks = setup_canvas_lti_advantage
        csrf_token = mocks[:params].delete("csrf_token")
        req_env = Rack::MockRequest.env_for(
          "http://atomicjolt-test.atomicjolt.xyz/lti_launches",
          { method: "POST", params: mocks[:params] },
        )
        status, _headers, _response = subject.call(req_env)
        expect(status).to eq(401)

        req_env["HTTP_COOKIE"] = "open_id_#{@state}=#{csrf_token}"
        status, _headers, _response = subject.call(req_env)
        expect(status).to eq(200)
      end

      it "doesn't launch with missing csrf token" do
        mocks = setup_canvas_lti_advantage
        mocks[:params].delete("csrf_token")
        req_env = Rack::MockRequest.env_for(
          "http://atomicjolt-test.atomicjolt.xyz/lti_launches",
          { method: "POST", params: mocks[:params] },
        )
        status, _headers, response = subject.call(req_env)

        returned_env = response[0]
        expect(status).to eq(401)
        expect(returned_env["atomic.validated.id_token"]).to eq(nil)
        expect(returned_env["atomic.validated.decoded_id_token"]).to eq(nil)
        expect(response[0]).to match("Unauthorized. Please check that your browser allows cookies.")
      end

      it "doesn't launch with invalid state" do
        mocks = setup_canvas_lti_advantage
        mocks[:params]["state"] += "1"
        req_env = Rack::MockRequest.env_for(
          "http://atomicjolt-test.atomicjolt.xyz/lti_launches",
          { method: "POST", params: mocks[:params] },
        )
        status, _headers, response = subject.call(req_env)
        expect(status).to eq(401)
        expect(response[0]).to match("Invalid launch state")
      end

      it "checks the nonce agrees" do
        mocks = setup_canvas_lti_advantage
        _nonce, state, csrf_token = AtomicLti::OpenId.generate_state
        mocks[:params]["state"] = state
        mocks[:params]["csrf_token"] = csrf_token
        req_env = Rack::MockRequest.env_for(
          "http://atomicjolt-test.atomicjolt.xyz/lti_launches",
          { method: "POST", params: mocks[:params] },
        )
        status, _headers, response = subject.call(req_env)
        expect(status).to eq(401)
        expect(response[0]).to match("Invalid launch state")
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
          state: mocks[:state],
        }

        req_env = Rack::MockRequest.env_for(
          "http://atomicjolt-test.atomicjolt.xyz/lti_launches",
          { method: "POST", params: params },
        )
        status, _headers, response = subject.call(req_env)

        returned_env = response[0]
        expect(status).to eq(401)
        expect(returned_env["atomic.validated.id_token"]).to eq(nil)
        expect(returned_env["atomic.validated.decoded_id_token"]).to eq(nil)
        expect(response[0]).to match("Invalid LTI launch")
      end
    end
  end
end
