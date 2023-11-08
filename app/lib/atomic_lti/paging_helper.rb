module AtomicLti
  module PagingHelper
    MAX_PAGES = 200

    def self.response_link_urls(response, *rels)
      links = response.headers["link"]&.split(",") || []
      urls = {}
      rels.each do |rel|
        urls[rel] = link_url(links, rel)
      end
      urls.values_at(*rels)
    end

    def self.link_url(links, rel)
      matching_link = links.find { |link| link.include?("rel=\"#{rel}\"") }

      return unless matching_link

      matching_link.split(";")[0].gsub(/[\<\>\s]/, "")
    end

    def self.paginate_request(response, &block)
      next_url, = response_link_urls(response, "next")
      response = yield response, next_url

      pages_fetched = 1;
      while next_url
        response = yield response, next_url
        break if response.blank?

        next_url, = response_link_urls(response, "next")

        pages_fetched += 1
        if pages_fetched > MAX_PAGES
          raise AtomicLti::Exceptions::PaginationLimitExceeded
        end
      end
    end
  end
end