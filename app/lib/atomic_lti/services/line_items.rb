module AtomicLti
  module Services
    # Canvas API docs https://canvas.instructure.com/doc/api/line_items.html
    class LineItems < AtomicLti::Services::Base

      def endpoint(id_token_decoded)
        url = id_token_decoded.dig(AtomicLti::Definitions::AGS_CLAIM, "lineitems")
        raise AtomicLti::Exceptions::LineItemError, "Unable to access line items" unless url.present?

        url
      end

      def scopes
        @id_token_decoded&.dig(AtomicLti::Definitions::AGS_CLAIM, "scope")
      end

      # Helper method to generate a default set of attributes
      def self.generate(
        label:,
        max_score:,
        start_date_time: nil,
        end_date_time: nil,
        resource_id: nil,
        tag: nil,
        resource_link_id: nil,
        external_tool_url: nil
      )
        attrs = {
          scoreMaximum: max_score,
          label: label,
          resourceId: resource_id,
          tag: tag,
          startDateTime: start_date_time,
          endDateTime: end_date_time,
          resourceLinkId: resource_link_id,
        }.compact
        if external_tool_url
          attrs[AtomicLti::Definitions::CANVAS_SUBMISSION_TYPE] = {
            type: "external_tool",
            external_tool_url: external_tool_url,
          }
        end
        attrs
      end

      def generate(attrs)
        self.class.generate(**attrs)
      end

      def self.can_manage_line_items?(id_token_decoded)
        id_token_decoded.dig(AtomicLti::Definitions::AGS_CLAIM, "scope")&.
          include?(AtomicLti::Definitions::AGS_SCOPE_LINE_ITEM)
      end

      def self.can_query_line_items?(id_token_decoded)
        can_manage_line_items?(id_token_decoded) ||
          id_token_decoded.dig(AtomicLti::Definitions::AGS_CLAIM, "scope").
            include?(AtomicLti::Definitions::AGS_SCOPE_LINE_ITEM_READONLY)
      end

      # List line items
      # Canvas: https://canvas.beta.instructure.com/doc/api/line_items.html#method.lti/ims/line_items.index
      def list(query = {}, page_url: nil)
        url = if page_url.present?
                page_url
              else
                uri = Addressable::URI.parse(endpoint(@id_token_decoded))
                uri.query_values = (uri.query_values || {}).merge(query)
                uri.to_str
              end

        accept = { "Accept" => "application/vnd.ims.lis.v2.lineitemcontainer+json" }
        HTTParty.get(url, headers: headers(accept), query: query)
      end

      def list_all(query = {})
        AtomicLti::PagingHelper.paginate_request do |next_link|
          result_page = list(query, page_url: next_link)
          [JSON.parse(result_page.body), get_next_url(result_page)]
        end
      end

      # Get a specific line item
      # https://canvas.beta.instructure.com/doc/api/line_items.html#method.lti/ims/line_items.show
      def show(line_item_url)
        accept = { "Accept" => "application/vnd.ims.lis.v2.lineitem+json" }
        HTTParty.get(line_item_url, headers: headers(accept))
      end

      # Create a line item
      # https://www.imsglobal.org/spec/lti-ags/v2p0/#creating-a-new-line-item
      # Canvas: https://canvas.beta.instructure.com/doc/api/line_items.html#method.lti/ims/line_items.create
      def create(attrs = nil)
        content_type = { "Content-Type" => "application/vnd.ims.lis.v2.lineitem+json" }
        HTTParty.post(endpoint(@id_token_decoded), body: JSON.dump(attrs), headers: headers(content_type))
      end

      # Update a line item
      # Canvas: https://canvas.beta.instructure.com/doc/api/line_items.html#method.lti/ims/line_items.update
      def update(line_item_url, attrs)
        content_type = { "Content-Type" => "application/vnd.ims.lis.v2.lineitem+json" }
        HTTParty.put(line_item_url, body: JSON.dump(attrs), headers: headers(content_type))
      end

      def delete(line_item_url)
        HTTParty.delete(line_item_url, headers: headers)
      end
    end
  end
end
