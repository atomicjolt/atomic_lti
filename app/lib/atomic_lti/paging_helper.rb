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
      matching_link = links.detect { |link| link.include?("rel=\"#{rel}\"") }

      return unless matching_link

      matching_link.split(";")[0].gsub(/[<>\s]/, "")
    end

    def self.paginate_request
      all = []
      next_link = nil
      loop do
        result, next_link = yield(next_link)
        all << result

        break if next_link.blank? || result.blank?

        raise AtomicLti::Exceptions::PaginationLimitExceeded if all.count > MAX_PAGES
      end
      all.compact.flatten
    end
  end
end
