# Changes in lti starter app:

jwks_url = application_instance.application.jwks_url(iss, client_id)
validate_token(jwks_url, token)

# Move method into library in the project
def self.application_instance_from_token(token)
  return unless token

  decoded_token = JWT.decode(token, nil, false)
  payload = decoded_token[PAYLOAD]
  client_id = payload["aud"]
  iss = payload["iss"]
  deployment_id = payload[AtomicLti::Definitions::DEPLOYMENT_ID]
  if client_id && deployment_id && iss
    ApplicationInstance.by_client_and_deployment(client_id, deployment_id, iss)
  end
end


# sign_tool_jwt changes
current_jwk = application_instance.application.current_jwk
sign_tool_jwt(current_jwk, payload)

# client_assertion changes:
current_jwk = application_instance.application.current_jwk
iss = application_instance.lti_key
token_url = application_instance.token_url(lti_token["iss"], lti_install.client_id)

client_assertion(current_jwk, iss, token_url, lti_token)

# request_token changes:
request_token(current_jwk, iss, token_url, lti_token)

# Any use of the lti advantage class will require that the
# intialize be updated to include current_jwk, iss, token_url, lti_token
# e.g.
#
current_jwk = application_instance.application.current_jwk
iss = application_instance.lti_key
token_url = application_instance.token_url(lti_token["iss"], lti_install.client_id)
lti_token = 
AtomicLti::Services::LineItems.new(current_jwk, iss, token_url, lti_token)