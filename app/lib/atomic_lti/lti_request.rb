# Class representing an lti advantage launch inside a controller
#
# When a controller includes the `lti_support` concern, an
# instance of this class will be accessible from the 'lti' property.

module AtomicLti
  class LtiRequest

    attr_reader :lti_token, :lti_params

    # delegate all other methods to the lti_params class
    delegate_missing_to :@lti_params

    def initialize(request, skip_validation: false)
      @request = request
      @lti_token = if skip_validation
                     # This is used to parse the original JWT following an oauth flow
                     JWT.decode(@request.params["id_token"], nil, false)[0]
                   else
                     validate!
                   end
      @lti_params = AtomicLti::Params.new(@lti_token)
    end

    def validate!
      # Validate the state by checking the database for the nonce
      if !AtomicLti::OpenId.validate_open_id_state(@request.params["state"])
        raise Exceptions::OpenIDStateError
      end

      token = AtomicLti::Authorization.validate_token(@request.params[:id_token])
      # Validate that we are at the target_link_uri
      target_link_uri = token[AtomicLti::Definitions::TARGET_LINK_URI_CLAIM]
      if target_link_uri != @request.url
        raise AtomicLti::Exceptions::OpenIDRedirectError
      end

      token
    end

    def user_from_lti
      AtomicLti::LtiUser.new(lti_token, @application_instance).user
    end

    def lti_provider
      AtomicLti::Definitions.lms_host(@lti_token)
    end

    def account_launch?
      canvas_account_id && !canvas_course_id
    end
  end
end
