module AtomicLti
  class DynamicRegistrationsController < ApplicationController
    def index
      byebug
      # The URL where the Tool will read all the information about the Platform (as per OIDC Reg specification).
      config_url = params["openid_configuration"]

      # Get the configuration from the LMS
      response = HTTParty.get(config_url, headers: { "Accept" => "application/json" })
      platform_config = JSON.parse(response.body)

      # The issuer domain must match the openid-configuration URL domain
      if URI(config_url).host != URI(platform_config["issuer"]).host
        raise AtomicLti::Exceptions::InvalidIssuer
      end

      registration_endpoint = platform_config["registration_endpoint"]
      issuer = platform_config["issuer"]

      if !registration_endpoint.starts_with?(issuer)
        raise AtomicLti::Exceptions::InvalidOIDCRegistrationEndpoint
      end

      # site = Site.find_or_create_by(
      #   url: platform_config["issuer"],
      # )

      # application_instance = ApplicationInstance.find_or_create_by(
      #   application_id: current_application.id,
      #   site: site,
      # )

      # Send a request to the provider to register the tool
      headers = {
        "Content-Type": "application/json",
      }
      if registration_token = params["registration_token"]
        headers["Authorization"] = "Bearer #{registration_token}"
      end

      response = HTTParty.post(
        registration_endpoint,
        headers: headers,
        body: client_registration_request.to_json,
      )

      platform_response = JSON.parse(response.body)

      # Create LTI Install. Note that a given LMS instance can have multiple lti installs
      client_id = platform_response["client_id"]
      registration_client_uri = platform_response["registration_client_uri"]
      platform = AtomicLti::Platform.find_or_initialize_by(iss: issuer)
      platform.update!(
        jwks_url: platform_config["jwks_uri"],
        token_url: platform_config["token_endpoint"],
        oidc_url: platform_config["authorization_endpoint"],
      )

      AtomicLti::Install.find_or_create_by!(iss: issuer, client_id: client_id)

      # Associated deployment id with the application instance and the lti install
      deployment_id = platform_response[AtomicLti::Definitions::TOOL_CONFIGURATION]["deployment_id"]

      if deployment_id.present?
        AtomicLti::Deployment.find_or_create_by!(
          deployment_id: deployment_id,
          lti_install: lti_install,
        )
      end
    end

    private

    # TODO put in real values for tos and privacy
    def client_registration_request
      {
        "application_type": "web",
        "response_types": ["id_token"],
        "grant_types": ["implict", "client_credentials"],
        "initiate_login_uri": init_launches_url,
        "redirect_uris": [
          launches_url,
        ],
        "client_name": "Atomic Lti",
        "jwks_uri": jwks_url(format: :json),
        "logo_uri": "#{request.host_with_port}/atomicjolt.png",
        "client_uri": "https://#{request.host_with_port}",
        "policy_uri": "https://www.atomicjolt.com/privacy",
        "tos_uri": "https://www.atomicjolt.com/tos",
        "token_endpoint_auth_method": "private_key_jwt",
        "contacts": [
          "support@atomicjolt.com",
        ],
        "scope": AtomicLti::Definitions.scopes,
        "https://purl.imsglobal.org/spec/lti-tool-configuration": {
        "domain": request.host_with_port,
          "description": "Atomic Lti",
          "target_link_uri": launches_url,
          "custom_parameters": {
            "context_history": "$Context.id.history",
            "canvas_sis_id": "$Canvas.user.sisid",
            "canvas_user_id": "$Canvas.user.id",
            "canvas_course_id": "$Canvas.course.id",
            "canvas_term_name": "$Canvas.term.name",
            "canvas_account_id": "$Canvas.account.id",
            "canvas_api_domain": "$Canvas.api.domain",
            "canvas_section_ids": "$Canvas.course.sectionIds",
            "canvas_account_name": "$Canvas.account.name",
            "canvas_user_timezone": "$Person.address.timezone",
            "canvas_root_account_id": "$Canvas.rootAccount.id",
          },
          "claims": ["iss", "sub", "name", "given_name", "family_name"],
          "messages": [
            {
              "type": "LtiDeepLinkingRequest",
              "target_link_uri": launches_url,
              "label": "Atomic Lti",
            },
          ],
        },
      }
    end

  end
end
