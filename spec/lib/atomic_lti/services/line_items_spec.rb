require "rails_helper"

RSpec.describe AtomicLti::Services::LineItems do
  before do
    setup_canvas_lti_advantage
    @lti_token = AtomicLti::Authorization.validate_token(@params["id_token"])
    @line_item = AtomicLti::Services::LineItems.new(lti_token: @lti_token, iss: nil, deployment_id: nil)
    @id = "https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31"
    # mock all requests to get a token
    stub_token_create
  end

  describe "list" do
    it "lists all line items in the course" do
      stub_line_items_list
      line_items = @line_item.list
      parsed = JSON.parse(line_items.body)
      expect(parsed.empty?).to be false
    end
  end

  describe "show" do
    it "gets a specific line item" do
      stub_line_item_show
      result = @line_item.show(@id)
      parsed = JSON.parse(result.body)
      expect(parsed["id"]).to eq "https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31"
    end
  end

  describe "create" do
    it "creates a new line item" do
      stub_line_item_create
      line_item_attrs = @line_item.generate(
        label: "LTI Advantage test item #{Time.now.utc}",
        max_score: 10,
        resource_id: 1,
        tag: "test",
        start_date_time: Time.now.utc - 1.day,
        end_date_time: Time.now.utc + 45.days,
        external_tool_url: "https://www.example.com/url",
      )
      result = @line_item.create(line_item_attrs)
      parsed = JSON.parse(result.body)
      expect(parsed["id"]).to eq "https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/29"
    end
  end

  describe "update" do
    it "updates a line item" do
      stub_line_item_update
      line_item_attrs = {
        label: "LTI Advantage test item #{Time.now.utc}",
        scoreMaximum: 10,
        resourceId: 1,
        tag: "test",
      }
      result = @line_item.update(@id, line_item_attrs)
      parsed = JSON.parse(result.body)
      expect(parsed["id"]).to eq "https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31"
    end
  end

  describe "delete" do
    it "it deletes a line item" do
      stub_line_item_delete
      result = @line_item.delete(@id)
      expect(result.response.code).to eq "200"
    end
  end
end
