require "rails_helper"

RSpec.describe AtomicLti::Services::Results do
  before do
    setup_canvas_lti_advantage
    @lti_token = AtomicLti::Authorization.validate_token(@params["id_token"])
    @results_service = AtomicLti::Services::Results.new(lti_token: @lti_token, iss: nil, deployment_id: nil)
    @line_item_id = "https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31"

    # mock all requests to get a token
    stub_token_create
  end

  describe "list" do
    it "requests only the results scope" do
      expect(AtomicLti::Authorization).to receive(:request_token).
        with(hash_including({ scopes: [AtomicLti::Definitions::AGS_SCOPE_RESULT] })).
        and_return("token")
      stub_line_items_list
      @results_service.list(@line_item_id)
    end
    it "lists results for the specified line item" do
      stub_line_items_list
      results = JSON.parse(@results_service.list(@line_item_id).body)
      expect(results.empty?).to be false
    end
  end

  describe "show" do
    it "gets specific result for the specified line item" do
      stub_line_item_show
      result_id = ""
      results = JSON.parse(@results_service.show(@line_item_id, result_id).body)
      expect(results.empty?).to be false
    end
  end
end
