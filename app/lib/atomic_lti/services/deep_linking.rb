# Implemenation of
# https://github.com/1EdTech/LTI-central/blob/main/proposals/deeplinking-service/specification.md#deep-linking-rest-service-1
module AtomicLti
  module Services
    class DeepLinking < AtomicLti::Services::Base

      def initialize(id_token_decoded:)
        super(id_token_decoded: id_token_decoded)
      end

      def scopes
        @id_token_decoded&.dig(AtomicLti::Definitions::DEEP_LINKING_SERVICE_CLAIM, "scopes")
      end

      def content_items_endpoint
        url = @id_token_decoded.dig(AtomicLti::Definitions::DEEP_LINKING_SERVICE_CLAIM, "contentitems")
        raise AtomicLti::Exceptions::DEEP_LINKING_SERVICE_CLAIM, "Unable to access content items url" if url.blank?

        url
      end

      def content_item_endpoint
        url = @id_token_decoded.dig(AtomicLti::Definitions::DEEP_LINKING_SERVICE_CLAIM, "contentitem")
        raise AtomicLti::Exceptions::DEEP_LINKING_SERVICE_CLAIM, "Unable to access content item url" if url.blank?

        url
      end

      # Allows a tool to get a list of all items linked to the tool in a given context.
      # Parameters:
      #   query may include:
      #     limit: Specifies the maximum number of results to return. The platform may return fewer results.
      #     rlid: Filters results to the specified resource link id.
      #       See: https://github.com/1EdTech/LTI-central/blob/main/proposals/deeplinking-service/specification.md#filter-by-resourcelinkid
      # Returns:
      #  An array of items as JSON.
      # Example:
      #   "items": [
      #     {
      #       "readonly": ["available", "resourceLinkId", "id"],
      #       "id": "https://www.myuniv.example.com/2344/content_items/389a-5478-78fg",
      #       "type": "ltiResourceLink",
      #       "resourceLinkId": "389a-5478-78fg",
      #       "title": "A title",
      #       "text": "This is a link to an activity that will be graded",
      #       "url": "https://lti.example.com/launchMe",
      #       "icon": {
      #         "url": "https://lti.example.com/image.jpg",
      #         "width": 100,
      #         "height": 100
      #       },
      #       "thumbnail": {
      #         "url": "https://lti.example.com/thumb.jpg",
      #         "width": 90,
      #         "height": 90
      #       },
      #       "lineItemId": "https://www.myuniv.example.com/2344/lineitems/345991",
      #       "available": {
      #         "startDateTime": "2024-02-06T20:05:02Z",
      #         "endDateTime": "2024-03-07T20:05:02Z"
      #       },
      #       "submission": {
      #         "endDateTime": "2024-03-06T20:05:02Z"
      #       },
      #       "custom": {
      #         "quiz_id": "az-123",
      #         "duedate": "$Resource.submission.endDateTime"
      #       }
      #     }
      #   ]
      # }
      def list(query = {})
        accept = { "Accept" => "application/vnd.1edtech.lti.contentitems+json" }
        HTTParty.get(content_items_endpoint, headers: headers(accept), query: query)
      end

      # Updates the content item
      #
      # Parameters:
      #   content_item_url: The url of the content item to update
      #   content_item: The content item to update
      #     The id, lineItemId, resourceLinkId and type properties are inherently read-only.
      #
      # Example content_item:
      # {
      #   "id": "https://www.myuniv.example.com/2344/content_items/389a-5478-4712",
      #   "type": "ltiResourceLink",
      #   "resourceLinkId": "389a-5478-4712",
      #   "title": "The ghost of the republic updated",
      #   "text": "This is a link to a video resource",
      #   "url": "https://lti.example.com/launchMe",
      #   "custom": {
      #     "video_id": "89042-ejxl01-updated",
      #   }
      #   "available": {
      #     "startDateTime": "2024-02-06T20:05:02Z",
      #     "endDateTime": "2024-03-11T22:00:00Z"
      #   },
      #   "submission": {
      #     "endDateTime": "2024-03-08T22:00:00Z"
      #   }
      # }
      #
      # Returns:
      #  The updated content item as JSON.
      def update(content_item_url, content_item)
        accept = { "Accept" => "application/vnd.1edtech.lti.contentitem+json" }
        HTTParty.put(content_item_url, headers: headers(accept), body: content_item.to_json)
      end

      # Adds a new content item. This is an optional method since platforms are not required to support an add endpoint.
      # Check for platform support before calling add.
      # If a line item was requested, and the platform created it, the lineItemId must be included in the response.
      def add(content_item)
        accept = { "Accept" => "application/vnd.1edtech.lti.contentitem+json" }
        HTTParty.post(content_items_endpoint, headers: headers(accept), body: content_item.to_json)
      end

    end
  end
end
