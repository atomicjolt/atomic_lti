require "rails_helper"

describe AtomicLti::PagingHelper do
  let(:link_header) do
    '<https://www.example.com/api/v1/courses/:id/discussion_topics.json?opaqueA>; rel="current",' \
    '<https://www.example.com/api/v1/courses/:id/discussion_topics.json?opaqueB>; rel="next",' \
    '<https://www.example.com/api/v1/courses/:id/discussion_topics.json?opaqueC>; rel="first",' \
    '<https://www.example.com/api/v1/courses/:id/discussion_topics.json?opaqueD>; rel="last"'
  end
  let(:response) do
    OpenStruct.new(
      headers: { "link" => link_header },
    )
  end

  describe "response_link_urls" do
    it "returns the requested links from the link header" do
      current_link, last_link = described_class.response_link_urls(response, "current", "last")

      expect(current_link).to eq("https://www.example.com/api/v1/courses/:id/discussion_topics.json?opaqueA")
      expect(last_link).to eq("https://www.example.com/api/v1/courses/:id/discussion_topics.json?opaqueD")
    end
  end

  describe "link_url" do
    it "returns the requested link URL" do
      expect(described_class.link_url(link_header.split(","), "next")).
        to eq("https://www.example.com/api/v1/courses/:id/discussion_topics.json?opaqueB")
    end
  end

  describe "paginate_request" do
    it "yields the response and next_url to the block" do
      yields = []
      AtomicLti::PagingHelper.paginate_request(response) do |response, next_url|
        yields.push([response, next_url])
        nil
      end

      expect(yields.count).to eq 2
    end

    it "raises if it hits the pagination limit" do
      expect do
        AtomicLti::PagingHelper.paginate_request(response) do |_, _|
          response
        end
      end.to raise_error(AtomicLti::Exceptions::PaginationLimitExceeded)
    end
  end
end
