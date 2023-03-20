require "rails_helper"

RSpec.describe AtomicLti::DeepLinking do
  describe "create_deep_link_jwt" do
    let(:iss) { "https://example.com" }
    let(:deployment_id) { "123" }
    let(:content_items) { "content_items" }
    let(:deep_link_claim_data) { "deep_link_claim_data" }

    context "when deployment is not found" do
      it "raises NoLTIDeployment exception" do
        expect {
          described_class.create_deep_link_jwt(
            iss: iss,
            deployment_id: deployment_id,
            content_items: content_items,
            deep_link_claim_data: deep_link_claim_data,
          )
        }.to raise_error(AtomicLti::Exceptions::NoLTIDeployment)
      end
    end

    context "when install is not found" do
      before do
        allow(AtomicLti::Deployment).to receive(:find_by).and_return(double(install: nil))
      end

      it "raises NoLTIInstall exception" do
        expect {
          described_class.create_deep_link_jwt(
            iss: iss,
            deployment_id: deployment_id,
            content_items: content_items,
            deep_link_claim_data: deep_link_claim_data,
          )
        }.to raise_error(AtomicLti::Exceptions::NoLTIInstall)
      end
    end

    context "when deployment and install are found" do
      before do
        allow(AtomicLti::Deployment).to receive(:find_by).and_return(double(install: double(client_id: "client_id")))
        allow(AtomicLti::Authorization).to receive(:sign_tool_jwt).and_return("jwt")
      end

      it "returns a signed JWT" do
        expect(
          described_class.create_deep_link_jwt(
            iss: iss,
            deployment_id: deployment_id,
            content_items: content_items,
            deep_link_claim_data: deep_link_claim_data,
          )
        ).to eq("jwt")
      end
    end
  end
end
