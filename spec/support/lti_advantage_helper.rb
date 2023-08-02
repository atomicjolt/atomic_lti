def canvas_headers(options = {})
  {
    "cache-control" => ["must-revalidate, private, max-age=0"],
    "content-type" => ["application/json; charset=utf-8"],
    "date" => ["Tue, 17 Mar 2015 20:58:42 GMT"],
    "etag" => ["\"c130ed4522ebea32d2649aff2e30fd3a\""],
    "p3p" => ["CP=\"None, see http://www.instructure.com/privacy-policy\""],
    "server" => ["Apache"],
    "set-cookie" => ["_csrf_token=9ATKDp5mkAhXm5DTVw54PeMj0FoKrA%2BUNQnFEfXgUs6eL4cl5hXEZwL5xoM%2FdhlS2xWAMT%2BHQs1iRLYkv9YTtg%3D%3D; path=/; secure", "canvas_session=LxC99e7zSpIBWuoSrxCHdg.xTKVNyuNeaLj864o1zvSA2YTzFQTPbQNpYoi2ktpSRSfjl0Q7CQe7W543_0So0FLILT3TkPbbGjcfoRGZNBhdWw8iOr7QRrIFwTHFdLNE7DWMRM4ZhX16kNxCI0_OD7g.iGFa_i2CresH7XxNz2ZwUksLtOk.VQiVgw; path=/; secure; HttpOnly"],
    "status" => ["200"],
    "vary" => ["Accept-Encoding"],
    "x-canvas-meta" => ["a=1;g=4MRcxnx6vQbFXxhLb8005m5WXFM2Z2i8lQwhJ1QT;s=4346;c=cluster35;z=us-east-1e;b=746692;m=746756;u=0.05;y=0.00;d=0.05;"],
    "x-canvas-user-id" => ["43460000000000001"],
    "x-frame-options" => ["SAMEORIGIN"],
    "x-rack-cache" => ["miss"],
    "x-request-context-id" => ["51a34ee0-af16-0132-cb5f-12e99fa8d58a"],
    "x-runtime" => ["0.186145"],
    "x-session-id" => ["48896cba407171322f5b940099073514"],
    "x-ua-compatible" => ["IE=Edge,chrome=1"],
    "content-length" => ["2561"],
    "connection" => ["Close"],
  }.merge(options)
end

def setup_lti_advantage_db_entries(
  client_id: FactoryBot.generate(:client_id),
  iss: "https://canvas.instructure.com",
  lti_user_id: SecureRandom.uuid,
  context_id: SecureRandom.hex(15),
  message_type: "LtiResourceLinkRequest",
  resource_link_id: SecureRandom.hex
)
  AtomicLti::Jwk.find_or_create_by(domain: nil)

  # Add some platforms
  AtomicLti::Platform.create_with(
    jwks_url: "https://canvas.instructure.com/api/lti/security/jwks",
    token_url: "https://canvas.instructure.com/login/oauth2/token",
    oidc_url: "https://canvas.instructure.com/api/lti/authorize_redirect"
  ).find_or_create_by(iss: "https://canvas.instructure.com")

  @iss = iss
  @client_id = client_id
  @lti_user_id = lti_user_id
  @context_id = context_id
  @deployment_id = "#{SecureRandom.hex(5)}:#{@context_id}"
  @message_type = message_type
  @resource_link_id = resource_link_id

  AtomicLti::Deployment.create!(iss: @iss, deployment_id: @deployment_id, client_id: @client_id)
  AtomicLti::Install.create!(iss: @iss, client_id: @client_id)

  canvas_jwk = AtomicLti::Jwk.new
  canvas_jwk.generate_keys

  @canvas_jwk = canvas_jwk

  stub_canvas_jwk(canvas_jwk)

  canvas_jwk
end

def setup_canvas_lti_advantage(
  client_id: FactoryBot.generate(:client_id),
  iss: "https://canvas.instructure.com",
  lti_user_id: SecureRandom.uuid,
  context_id: SecureRandom.hex(15),
  message_type: "LtiResourceLinkRequest",
  resource_link_id: SecureRandom.hex
)

  canvas_jwk = setup_lti_advantage_db_entries(
    client_id: client_id,
    iss: iss,
    lti_user_id: lti_user_id,
    context_id: context_id,
    message_type: message_type,
    resource_link_id: resource_link_id,
  )

  @nonce, @state = AtomicLti::OpenId.generate_state

  @decoded_id_token = build_payload(
    client_id: @client_id,
    iss: @iss,
    lti_user_id: @lti_user_id,
    context_id: @context_id,
    message_type: @message_type,
    resource_link_id: @resource_link_id,
    deployment_id: @deployment_id,
    nonce: @nonce,
  ).deep_stringify_keys

  if block_given?
    result = yield(@decoded_id_token, canvas_jwk)
    @decoded_id_token = result[:decoded_id_token] if result[:decoded_id_token]
    @id_token = result[:id_token]
  end

  @id_token ||= JWT.encode(
    @decoded_id_token,
    canvas_jwk.private_key,
    canvas_jwk.alg,
    kid: canvas_jwk.kid,
    typ: "JWT",
  )

  @params = {
    "id_token" => @id_token,
    "state" => @state,
    "lti_storage_target" => "_parent",
  }

  {
    iss: @iss,
    client_id: @client_id,
    lti_user_id: @lti_user_id,
    context_id: @context_id,
    deployment_id: @deployment_id,
    message_type: @message_type,
    resourse_link_id: @resource_link_id,
    id_token: @id_token,
    state: @state,
    params: @params,
    decoded_id_token: @decoded_id_token,
    canvas_jwk: canvas_jwk,
  }
end

def stub_canvas_jwk(jwk)
  stub_request(:get, AtomicLti::Definitions::CANVAS_PUBLIC_LTI_KEYS_URL).
    to_return(
      status: 200,
      body: { keys: [jwk.to_json] }.to_json,
      headers: canvas_headers,
    )
end

def stub_canvas_token
  stub_request(:post, AtomicLti::Definitions::CANVAS_AUTH_TOKEN_URL).
    to_return(
      status: 200,
      body: {
        expires_in: DateTime.now + 1.day,
      }.to_json,
      headers: canvas_headers,
    )
end

def resource_link_claim(id)
  {
    "https://purl.imsglobal.org/spec/lti-ags/claim/endpoint": {
      "scope": [
        "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem",
        "https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly",
        "https://purl.imsglobal.org/spec/lti-ags/scope/score",
        "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly",
      ],
      "lineitems": "https://atomicjolt.instructure.com/api/lti/courses/3334/line_items",
      "validation_context": nil,
      "errors": {
        "errors": {},
      },
    },
    "https://purl.imsglobal.org/spec/lti/claim/target_link_uri": "http://atomicjolt-test.atomicjolt.xyz/lti_launches",
    "https://purl.imsglobal.org/spec/lti/claim/resource_link": {
      "id": id,
      "description": nil,
      "title": nil,
      "validation_context": nil,
      "errors": {
        "errors": {},
      },
    },
  }
end

def deep_link_settings_claim
  {
    "https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings": {
      "deep_link_return_url": "https://atomicjolt.instructure.com/courses/3505/deep_linking_response?modal=true",
      "accept_types": ["link", "file", "html", "ltiResourceLink", "image"],
      "accept_presentation_document_targets": ["embed", "iframe", "window"],
      "accept_media_types": "image/*,text/html,application/vnd.ims.lti.v1.ltilink,*/*",
      "accept_multiple": true,
      "auto_create": false,
      "validation_context": nil,
      "errors": {
        "errors": {},
      },
    },
  }
end

def build_payload(client_id:, iss:, lti_user_id:, context_id:, message_type:, resource_link_id:, deployment_id:, nonce:)
  exp = 24.hours.from_now
  payload = {
    "https://purl.imsglobal.org/spec/lti/claim/message_type": message_type,
    "https://purl.imsglobal.org/spec/lti/claim/version": "1.3.0",
    "aud": client_id,
    "azp": client_id,
    "https://purl.imsglobal.org/spec/lti/claim/deployment_id": deployment_id,
    "exp": exp.to_i,
    "iat": Time.now.to_i,
    "iss": iss,
    "nonce": nonce,
    "sub": lti_user_id,
    "https://purl.imsglobal.org/spec/lti/claim/context": {
      "id": context_id,
      "label": "Intro Geology",
      "title": "Introduction to Geology - Ball",
      "type": [
        "http://purl.imsglobal.org/vocab/lis/v2/course#CourseOffering",
      ],
      "validation_context": nil,
      "errors": {
        "errors": {},
      },
    },
    "https://purl.imsglobal.org/spec/lti/claim/tool_platform": {
      "guid": "4MRcxnx6vQbFXxhLb8005m5WXFM2Z2i8lQwhJ1QT:canvas-lms",
      "name": "Atomic Jolt",
      "version": "cloud",
      "product_family_code": "canvas",
      "validation_context": nil,
      "errors": {
        "errors": {},
      },
    },
    "https://purl.imsglobal.org/spec/lti/claim/launch_presentation": {
      "document_target": "iframe",
      "height": 500,
      "width": 500,
      "return_url": "https://atomicjolt.instructure.com/courses/3334/external_content/success/external_tool_redirect",
      "locale": "en",
      "validation_context": nil,
      "errors": {
        "errors": {},
      },
    },
    "locale": "en",
    "https://purl.imsglobal.org/spec/lti/claim/roles": [
      "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator",
      "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Instructor",
      "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student",
      "http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor",
      "http://purl.imsglobal.org/vocab/lis/v2/system/person#User",
    ],
    "https://purl.imsglobal.org/spec/lti/claim/custom": {
      "canvas_sis_id": "$Canvas.user.sisid",
      "canvas_user_id": 1,
      "canvas_api_domain": "atomicjolt.instructure.com",
    },
    "https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice": {
      "context_memberships_url": "https://atomicjolt.instructure.com/api/lti/courses/3334/names_and_roles",
      "service_versions": [
        "2.0",
      ],
      "validation_context": nil,
      "errors": {
        "errors": {},
      },
    },
    "errors": {
      "errors": {},
    },
  }

  payload.merge!(resource_link_claim(resource_link_id)) if @message_type == "LtiResourceLinkRequest"
  payload.merge!(deep_link_settings_claim) if @message_type == "LtiDeepLinkingRequest"

  payload
end
