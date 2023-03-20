require "rails_helper"

RSpec.describe AtomicLti::Definitions do
  describe "lms_host" do
    context "when deep_link_launch? is true" do
      it "returns the deep_link_return_url" do
        payload = {
          AtomicLti::Definitions::MESSAGE_TYPE => "LtiDeepLinkingRequest",
          AtomicLti::Definitions::DEEP_LINKING_CLAIM => {
            "deep_link_return_url" => "https://www.example.com",
          },
        }
        expect(described_class.lms_host(payload)).to eq("www.example.com")
      end
    end

    context "when deep_link_launch? is false" do
      it "returns the return_url" do
        payload = {
          AtomicLti::Definitions::LAUNCH_PRESENTATION => {
            "return_url" => "https://www.example.com",
          },
        }
        expect(described_class.lms_host(payload)).to eq("www.example.com")
      end
    end
  end

  describe "lms_url" do
    it "returns the LMS URL" do
      payload = {
          AtomicLti::Definitions::MESSAGE_TYPE => "LtiDeepLinkingRequest",
          AtomicLti::Definitions::DEEP_LINKING_CLAIM => {
            "deep_link_return_url" => "https://www.example.com",
          },
        }
      expect(described_class.lms_url(payload)).to eq("https://www.example.com")
    end
  end

  describe "deep_link_launch?" do
    context "when the message type is LtiDeepLinkingRequest" do
      it "returns true" do
        payload = {
          AtomicLti::Definitions::MESSAGE_TYPE => "LtiDeepLinkingRequest",
          AtomicLti::Definitions::DEEP_LINKING_CLAIM => {
            "deep_link_return_url" => "https://www.example.com",
          },
        }
        expect(described_class.deep_link_launch?(payload)).to be true
      end
    end

    context "when the message type is not LtiDeepLinkingRequest" do
      it "returns false" do
        payload = {
          AtomicLti::Definitions::LAUNCH_PRESENTATION => {
            "return_url" => "https://www.example.com",
          },
        }
        expect(described_class.deep_link_launch?(payload)).to be false
      end
    end
  end

  describe "names_and_roles_launch?" do
    context "when the names and roles claim is present" do
      it "returns true" do
        payload = {
          AtomicLti::Definitions::NAMES_AND_ROLES_CLAIM => {
            "service_versions" => AtomicLti::Definitions::NAMES_AND_ROLES_SERVICE_VERSIONS,
          },
        }
        expect(described_class.names_and_roles_launch?(payload)).to be true
      end
    end

    context "when the names and roles claim is not present" do
      it "returns false" do
        payload = {}
        expect(described_class.names_and_roles_launch?(payload)).to be false
      end
    end
  end

  describe "assignment_and_grades_launch?" do
    context "when the AGS claim is present" do
      it "returns true" do
        payload = { AtomicLti::Definitions::AGS_CLAIM => "ags_claim" }
        expect(described_class.assignment_and_grades_launch?(payload)).to be true
      end
    end

    context "when the AGS claim is not present" do
      it "returns false" do
        payload = {}
        expect(described_class.assignment_and_grades_launch?(payload)).to be false
      end
    end
  end
end
