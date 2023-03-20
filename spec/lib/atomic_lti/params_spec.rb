RSpec.describe AtomicLti::Params do
  let(:lti_token) do
    {
      iss: "https://canvas.instructure.com",
      aud: "1234",
      AtomicLti::Definitions::DEPLOYMENT_ID => "aj1",
      AtomicLti::Definitions::LTI_VERSION => "1.3.0",
    }
  end
  let(:params) { AtomicLti::Params.new(lti_token) }

  describe "lti_advantage?" do
    it "returns true" do
      expect(params.lti_advantage?).to eq(true)
    end
  end

  describe "deployment_id" do
    it "returns the deployment id" do
      expect(params.deployment_id).to eq("aj1")
    end
  end

  describe "iss" do
    it "returns the iss" do
      expect(params.iss).to eq("https://canvas.instructure.com")
    end
  end

  describe "version" do
    it "returns the version" do
      expect(params.version).to eq("1.3.0")
    end
  end

  describe "client_id" do
    it "returns the client id" do
      expect(params.client_id).to eq("1234")
    end
  end

  describe "context_data" do
    it "returns the context data" do
      expect(params.context_data).to eq({})
    end
  end

  describe "launch_context" do
    it "returns the launch context" do
      expect(params.launch_context).to eq("UNKNOWN")
    end
  end

  describe "context_id" do
    it "returns the context id" do
      expect(params.context_id).to eq(nil)
    end
  end

  describe "resource_link_data" do
    it "returns the resource link data" do
      expect(params.resource_link_data).to eq({})
    end
  end

  describe "resource_link_title" do
    it "returns the resource link title" do
      expect(params.resource_link_title).to eq(nil)
    end
  end

  describe "lis_data" do
    it "returns the lis data" do
      expect(params.lis_data).to eq({})
    end
  end

  describe "tool_platform_data" do
    it "returns the tool platform data" do
      expect(params.tool_platform_data).to eq({})
    end
  end

  describe "product_family_code" do
    it "returns the product family code" do
      expect(params.product_family_code).to eq(nil)
    end
  end

  describe "tool_consumer_instance_guid" do
    it "returns the tool consumer instance guid" do
      expect(params.tool_consumer_instance_guid).to eq(nil)
    end
  end

  describe "tool_consumer_instance_name" do
    it "returns the tool consumer instance name" do
      expect(params.tool_consumer_instance_name).to eq(nil)
    end
  end

  describe "launch_presentation_data" do
    it "returns the launch presentation data" do
      expect(params.launch_presentation_data).to eq({})
    end
  end

  describe "launch_locale" do
    it "returns the launch locale" do
      expect(params.launch_locale).to eq(nil)
    end
  end

  describe "ags_data" do
    it "returns the ags data" do
      expect(params.ags_data).to eq({})
    end
  end

  describe "deep_linking_data" do
    it "returns the deep linking data" do
      expect(params.deep_linking_data).to eq({})
    end
  end
end
