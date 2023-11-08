module AtomicLti
  module Services
    # Canvas API docs: https://canvas.instructure.com/doc/api/result.html
    class Results < AtomicLti::Services::Base

      def scopes
        [AtomicLti::Definitions::AGS_SCOPE_RESULT]
      end

      def list(line_item_id, query: {}, page_url: nil)
        url = if page_url.present?
                page_url
              else
                uri = Addressable::URI.parse("#{line_item_id}/results")
                uri.query_values = (uri.query_values || {}).merge(query)
                uri.to_str
              end

        HTTParty.get(url, headers: headers)
      end

      def list_all(line_item_id, query: {})
        results = []
        AtomicLti::PagingHelper.paginate_request(list(line_item_id, query: query)) do |response, next_url|
          results += JSON.parse(response.body)
          if next_url.present?
            list(line_item_id, page_url: next_url)
          end
        end

        results
      end

      def show(result_id)
        HTTParty.get(result_id, headers: headers)
      end

    end
  end
end
