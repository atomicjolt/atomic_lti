require "rails_helper"
require "support/lti_advantage_helper"

module AtomicLti
  RSpec.describe AtomicLti::ErrorHandlingMiddleware do

    let(:env) { Rack::MockRequest.env_for }

    it "returns status 200 when no errors are found" do
      app = ->(env) { [200, {}, [env]] }
      middleware = ErrorHandlingMiddleware.new(app)
      status, _headers, _response = middleware.call(env)
      expect(status).to eq(200)
    end

    describe "404 exceptions" do
      it "returns status 404 when an AtomicLtiNotFoundException is thrown" do
        app = ->(env) do
          raise AtomicLti::Exceptions::AtomicLtiNotFoundException
        end
        middleware = ErrorHandlingMiddleware.new(app)
        status, _headers, _response = middleware.call(env)
        expect(status).to eq(404)
      end

      it "returns status 404 when an NoLTIDeployment is thrown" do
        app = ->(env) do
          raise AtomicLti::Exceptions::NoLTIDeployment.new(iss: 'fakeiss', deployment_id: 'fake_id')
        end
        middleware = ErrorHandlingMiddleware.new(app)
        status, _headers, _response = middleware.call(env)
        expect(status).to eq(404)
      end

      it "returns status 404 when an NoLTIInstall is thrown" do
        app = ->(env) do
          raise AtomicLti::Exceptions::NoLTIInstall.new(iss: 'fakeiss', deployment_id: 'fake_id')
        end
        middleware = ErrorHandlingMiddleware.new(app)
        status, _headers, _response = middleware.call(env)
        expect(status).to eq(404)
      end

      it "returns status 404 when an NoLTIPlatform is thrown" do
        app = ->(env) do
          raise AtomicLti::Exceptions::NoLTIPlatform.new(iss: 'fakeiss', deployment_id: 'fake_id')
        end
        middleware = ErrorHandlingMiddleware.new(app)
        status, _headers, _response = middleware.call(env)
        expect(status).to eq(404)
      end
    end

    describe "500 exceptions" do
      it "returns status 500 when an AtomicLtiException is thrown" do
        app = ->(env) do
          raise AtomicLti::Exceptions::AtomicLtiException.new
        end
        middleware = ErrorHandlingMiddleware.new(app)
        status, _headers, _response = middleware.call(env)
        expect(status).to eq(500)
      end
    end
  end
end
