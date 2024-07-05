require "rails_helper"

RSpec.describe AtomicLti::Services::PlatformNotifications do
  before do
    setup_canvas_lti_advantage
    @id_token_decoded = AtomicLti::Authorization.validate_token(@params["id_token"])
    # mock all requests to get a token
    stub_token_create
  end

  describe "valid?" do
    it "indicates if the launch contains the names and roles scope" do
      pns_service = AtomicLti::Services::PlatformNotifications.new(id_token_decoded: @id_token_decoded)
      expect(pns_service.valid?).to eq true
    end
  end

  describe "list" do
    before do
      stub_platform_notifications_get
    end

    it "requests only the names and roles scope" do
      expect(AtomicLti::Authorization).to receive(:request_token).
        with(hash_including({ scopes: [AtomicLti::Definitions::PNS_SCOPE_NOTICEHANDLERS] })).
        and_return("token")
      pns_service = AtomicLti::Services::PlatformNotifications.new(id_token_decoded: @id_token_decoded)
      pns_service.get
    end

    it "gets the platform notifications" do
      pns_service = AtomicLti::Services::PlatformNotifications.new(id_token_decoded: @id_token_decoded)
      notifications = pns_service.get
      expect(notifications["client_id"]).to be_present
    end
  end

  describe "update" do
    before do
      stub_platform_notifications_put
    end

    it "updates the platform notifications" do
      pns_service = AtomicLti::Services::PlatformNotifications.new(id_token_decoded: @id_token_decoded)
      response = pns_service.update("notice_type", "handler")
      expect(response.parsed_response).to be_present
    end
  end

  describe "validate_notification" do
    let(:valid_token) do
      {
        "iss" => "issuer",
        "aud" => ["audience"],
        AtomicLti::Definitions::DEPLOYMENT_ID => "deployment_id",
        AtomicLti::Definitions::NOTICE_TYPE_CLAIM => "notice_type",
        AtomicLti::Definitions::LTI_VERSION => "1.3",
      }
    end

    before do
      allow(AtomicLti::Authorization).to receive(:validate_token).and_return(decoded_token)
    end

    context "with a valid token" do
      let(:decoded_token) { valid_token }

      it "does not raise an exception" do
        expect { described_class.validate_notification(decoded_token) }.not_to raise_error
      end
    end

    context "with a blank token" do
      let(:decoded_token) { {} }

      it "raises an InvalidPlatformNotification exception" do
        expect { described_class.validate_notification(decoded_token) }.to raise_error(AtomicLti::Exceptions::InvalidPlatformNotification)
      end
    end

    context "with missing iss" do
      let(:decoded_token) { valid_token.except("iss") }

      it "raises an InvalidPlatformNotification exception with a specific error message" do
        expect { described_class.validate_notification(decoded_token) }.to raise_error(AtomicLti::Exceptions::InvalidPlatformNotification, /LTI token is missing required field iss/)
      end
    end

    context "with missing aud" do
      let(:decoded_token) { valid_token.except("aud") }

      it "raises an InvalidPlatformNotification exception with a specific error message" do
        expect { described_class.validate_notification(decoded_token) }.to raise_error(AtomicLti::Exceptions::InvalidPlatformNotification, /LTI token is missing required field aud/)
      end
    end

    context "with missing deployment_id" do
      let(:decoded_token) { valid_token.except(AtomicLti::Definitions::DEPLOYMENT_ID) }

      it "raises an InvalidPlatformNotification exception with a specific error message" do
        expect { described_class.validate_notification(decoded_token) }.to raise_error(AtomicLti::Exceptions::InvalidPlatformNotification, /LTI token is missing required field #{AtomicLti::Definitions::DEPLOYMENT_ID}/)
      end
    end

    context "with missing notice type claim" do
      let(:decoded_token) { valid_token.except(AtomicLti::Definitions::NOTICE_TYPE_CLAIM) }

      it "raises an InvalidPlatformNotification exception with a specific error message" do
        expect { described_class.validate_notification(decoded_token) }.to raise_error(AtomicLti::Exceptions::InvalidPlatformNotification, /LTI token is missing required claim #{AtomicLti::Definitions::NOTICE_TYPE_CLAIM}/)
      end
    end

    context "with missing lti version" do
      let(:decoded_token) { valid_token.except(AtomicLti::Definitions::LTI_VERSION) }

      it "raises a NoLTIVersion exception" do
        expect { described_class.validate_notification(decoded_token) }.to raise_error(AtomicLti::Exceptions::NoLTIVersion)
      end
    end

    context "with aud as an array and invalid azp" do
      let(:decoded_token) { valid_token.merge("aud" => ["aud1", "aud2"], "azp" => "invalid_azp") }

      it "raises an InvalidPlatformNotification exception with azp error" do
        expect { described_class.validate_notification(decoded_token) }.to raise_error(AtomicLti::Exceptions::InvalidPlatformNotification, /LTI token azp is not one of the aud's/)
      end
    end
  end
end
