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
end
