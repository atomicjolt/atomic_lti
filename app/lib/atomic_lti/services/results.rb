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
                uri = Addressable::URI.parse(line_item_id)
                uri.path = "#{uri.path}/results"
                uri.query_values = (uri.query_values || {}).merge(query)
                uri.to_str
              end

        accept = { "Accept" => "application/vnd.ims.lis.v2.resultcontainer+json" }
        response, = service_get(url, headers: headers(accept))
        response
      end

      def list_all(line_item_id, query: {})
        AtomicLti::PagingHelper.paginate_request do |next_link|
          result_page = list(line_item_id, query: query, page_url: next_link)
          [JSON.parse(result_page.body), get_next_url(result_page)]
        end
      end

      def show(result_id)
        response, = service_get(result_id, headers: headers)
        response
      end

    end
  end
end
