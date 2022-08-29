module AtomicLti
  # This is for extracting data from the lti jwt in more human-readable ways
  class Params
    attr_reader :token

    def initialize(lti_token)
      @token = lti_token.with_indifferent_access
    end

    def lti_advantage?
      true
    end

    def deployment_id
      token[AtomicLti::Definitions::DEPLOYMENT_ID]
    end

    def iss
      token[:iss]
    end

    def version
      token[AtomicLti::Definitions::VERSION]
    end

    def client_id
      token[:aud]
    end

    def context_data
      token[AtomicLti::Definitions::CONTEXT_CLAIM] || {}
    end

    def launch_context
      # This is an array, I'm not sure what it means to have more than one
      # value. In courses and accounts there's only one value
      contexts = context_data[:type] || []
      if contexts.include? AtomicLti::Definitions::COURSE_CONTEXT
        "COURSE"
      elsif contexts.include? AtomicLti::Definitions::ACCOUNT_CONTEXT
        "ACCOUNT"
      else
        "UNKNOWN"
      end
    end

    def context_id
      context_data[:id]
    end

    def resource_link_data
      token[AtomicLti::Definitions::RESOURCE_LINK_CLAIM] || {}
    end

    def resource_link_title
      resource_link_data[:title]
    end

    def lis_data
      token[AtomicLti::Definitions::LIS_CLAIM] || {}
    end

    def tool_platform_data
      token[AtomicLti::Definitions::TOOL_PLATFORM_CLAIM] || {}
    end

    def product_family_code
      tool_platform_data[:product_family_code]
    end

    def tool_consumer_instance_guid
      tool_platform_data[:guid]
    end

    def tool_consumer_instance_name
      tool_platform_data[:name]
    end

    def launch_presentation_data
      token[AtomicLti::Definitions::LAUNCH_PRESENTATION] || {}
    end

    def launch_locale
      launch_presentation_data[:locale]
    end

    def ags_data
      token[AtomicLti::Definitions::AGS_CLAIM] || {}
    end

    def deep_linking_data
      token[AtomicLti::Definitions::DEEP_LINKING_DATA_CLAIM] || {}
    end

    def deep_linking_claim
      token[AtomicLti::Definitions::DEEP_LINKING_CLAIM]
    end

    def message_type
      token[AtomicLti::Definitions::MESSAGE_TYPE]
    end

    def is_deep_link
      AtomicLti::Definitions.deep_link_launch?(token)
    end

    # This extracts the custom parameters from the jwt token from the lti launch
    # These values must be added to the developer key under "Custom Fields"
    # for example: canvas_course_id=$Canvas.course.id
    def custom_data
      token[AtomicLti::Definitions::CUSTOM_CLAIM]&.reject { |s| s.start_with?("$Canvas") } || {}
    end

    def canvas_course_id
      custom_data[:canvas_course_id]
    end

    def canvas_section_ids
      custom_data[:canvas_section_ids]
    end

    def canvas_account_id
      custom_data[:canvas_account_id]
    end

    def canvas_course_name
      custom_data[:canvas_course_name]
    end

    def canvas_assignment_id
      custom_data[:canvas_assignment_id]
    end

  end
end
