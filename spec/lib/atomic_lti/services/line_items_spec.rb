require "rails_helper"

RSpec.describe AtomicLti::Services::LineItems do
  before do
    setup_canvas_lti_advantage
    @id_token_decoded = AtomicLti::Authorization.validate_token(@params["id_token"])
    @line_item = AtomicLti::Services::LineItems.new(id_token_decoded: @id_token_decoded, iss: nil, deployment_id: nil)
    @id = "https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31"
    # mock all requests to get a token
    stub_token_create
  end

  describe "list" do
    it "requests all scopes in the token" do
      expect(AtomicLti::Authorization).to receive(:request_token).
        with(hash_including({ scopes: match_array(@id_token_decoded[AtomicLti::Definitions::AGS_CLAIM]["scope"]) })).
        and_return("token")
      stub_line_items_list
      @line_item.list
    end

    it "lists all line items in the course" do
      stub_line_items_list
      line_items = @line_item.list
      parsed = JSON.parse(line_items.body)
      expect(parsed.empty?).to be false
    end
  end

  describe "list_all" do
    it "lists all line items in the course across multiple pages" do
      stub_line_items_list_all
      line_items = @line_item.list_all
      expect(line_items.count).to eq 8
    end

    it "lists all line items in the course in a single page" do
      stub_line_items_list
      line_items = @line_item.list_all
      expect(line_items.count).to eq 4
    end

    it "adds a valid query string when a query argument is given" do
      allow(HTTParty).to receive(:get).and_return(
        OpenStruct.new({ headers: {}, body: "[]" }),
      )
      query = { resource_link_id: "6adc5f3a-27dd-4c27-82f0-c013930ccf6a" }
      @line_item.list_all(query)

      expect(HTTParty).to have_received(:get).with(
        "#{@id_token_decoded.dig(AtomicLti::Definitions::AGS_CLAIM, 'lineitems')}?#{query.to_query}",
        anything,
      )
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
