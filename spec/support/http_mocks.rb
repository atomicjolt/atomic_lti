#
# LTI Advantage
#

# Request to get a token to make LTI service requests
def stub_token_create
  stub_request(:post, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/login/oauth2/token|).
    to_return(
      status: 200,
      body: "{\"access_token\":\"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2NhbnZhcy5pbnN0cnVjdHVyZS5jb20iLCJzdWIiOiI0MzQ2MDAwMDAwMDAwMDE5NCIsImF1ZCI6Imh0dHBzOi8vYXRvbWljam9sdC5pbnN0cnVjdHVyZS5jb20vbG9naW4vb2F1dGgyL3Rva2VuIiwiaWF0IjoxNTYzNDgxNTg2LCJleHAiOjE1NjM0ODUxODYsImp0aSI6IjU0ZTRmNTVmLTk2NmUtNGNhOS1iNmM2LTYzNTY0YTA5ZDg5MiIsInNjb3BlcyI6Imh0dHBzOi8vcHVybC5pbXNnbG9iYWwub3JnL3NwZWMvbHRpLWFncy9zY29wZS9saW5laXRlbSBodHRwczovL3B1cmwuaW1zZ2xvYmFsLm9yZy9zcGVjL2x0aS1hZ3Mvc2NvcGUvcmVzdWx0LnJlYWRvbmx5IGh0dHBzOi8vcHVybC5pbXNnbG9iYWwub3JnL3NwZWMvbHRpLWFncy9zY29wZS9zY29yZSBodHRwczovL3B1cmwuaW1zZ2xvYmFsLm9yZy9zcGVjL2x0aS1ucnBzL3Njb3BlL2NvbnRleHRtZW1iZXJzaGlwLnJlYWRvbmx5In0.L1a4ZRPRjIPdMdaLFP8oatdxxJVNeyX7zQv9KHDIG8s\",\"token_type\":\"Bearer\",\"expires_in\":3600,\"scope\":\"https://purl.imsglobal.org/spec/lti-ags/scope/lineitem https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly https://purl.imsglobal.org/spec/lti-ags/scope/score https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly\"}",
    )
end

# Names and roles
def stub_names_and_roles_list
  stub_request(:get, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/courses/[0-9]+/names_and_roles|).
    to_return(
      status: 200,
      body: "{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/names_and_roles\",\"context\":{\"id\":\"af9b5e18fe251409be18e77253d918dcf22d156e\",\"label\":\"Intro Geology\",\"title\":\"Introduction to Geology - Ball\"},\"members\":[{\"status\":\"Active\",\"user_id\":\"cfca15d8-2958-4647-a33e-a7c4b2ddab2c\",\"name\":\"George Washington\",\"roles\":[\"http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor\"]},{\"status\":\"Active\",\"user_id\":\"7c119130-88a1-4bc0-9dac-d5dab2569c58\",\"name\":\"James Madison\",\"roles\":[\"http://purl.imsglobal.org/vocab/lis/v2/membership#Learner\"]},{\"status\":\"Active\",\"user_id\":\"8e5f9e00-1dc1-4cd9-b321-5bec4c891fe2\",\"name\":\"Benjamin Franklin\",\"roles\":[\"http://purl.imsglobal.org/vocab/lis/v2/membership#Learner\"]},{\"status\":\"Active\",\"user_id\":\"abb134a1-58f1-42b2-84f7-78871b7ac6f6\",\"name\":\"John Adams\",\"roles\":[\"http://purl.imsglobal.org/vocab/lis/v2/membership#Learner\"]},{\"status\":\"Active\",\"user_id\":\"2f4ade7b-29b2-4189-b338-e8ee036f15aa\",\"name\":\"Thomas Jefferson\",\"roles\":[\"http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor\"]}]}",
    )
end

def stub_names_and_roles_list_all
  stub_request(:get, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/courses/[0-9]+/names_and_roles$|).
    to_return(
      status: 200,
      body: "{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/names_and_roles\",\"context\":{\"id\":\"af9b5e18fe251409be18e77253d918dcf22d156e\",\"label\":\"Intro Geology\",\"title\":\"Introduction to Geology - Ball\"},\"members\":[{\"status\":\"Active\",\"user_id\":\"cfca15d8-2958-4647-a33e-a7c4b2ddab2c\",\"name\":\"George Washington\",\"roles\":[\"http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor\"]},{\"status\":\"Active\",\"user_id\":\"7c119130-88a1-4bc0-9dac-d5dab2569c58\",\"name\":\"James Madison\",\"roles\":[\"http://purl.imsglobal.org/vocab/lis/v2/membership#Learner\"]},{\"status\":\"Active\",\"user_id\":\"8e5f9e00-1dc1-4cd9-b321-5bec4c891fe2\",\"name\":\"Benjamin Franklin\",\"roles\":[\"http://purl.imsglobal.org/vocab/lis/v2/membership#Learner\"]},{\"status\":\"Active\",\"user_id\":\"abb134a1-58f1-42b2-84f7-78871b7ac6f6\",\"name\":\"John Adams\",\"roles\":[\"http://purl.imsglobal.org/vocab/lis/v2/membership#Learner\"]},{\"status\":\"Active\",\"user_id\":\"2f4ade7b-29b2-4189-b338-e8ee036f15aa\",\"name\":\"Thomas Jefferson\",\"roles\":[\"http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor\"]}]}",
      headers: {
        "link" => %{<https://atomicjolt.instructure.com/api/lti/courses/3334/names_and_roles?opaqueA>; rel="current", <https://atomicjolt.instructure.com/api/lti/courses/3334/names_and_roles?opaqueB>; rel="next", <https://atomicjolt.instructure.com/api/lti/courses/3334/names_and_roles?opaqueC>; rel="first", <https://atomicjolt.instructure.com/api/lti/courses/3334/names_and_roles?opaqueD>; rel="last"}
      }
    )
  stub_request(:get, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/courses/[0-9]+/names_and_roles\?opaqueB|).
    to_return(
      status: 200,
      body: "{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/names_and_roles\",\"context\":{\"id\":\"af9b5e18fe251409be18e77253d918dcf22d156e\",\"label\":\"Intro Geology\",\"title\":\"Introduction to Geology - Ball\"},\"members\":[{\"status\":\"Active\",\"user_id\":\"dfca15d8-2958-4647-a33e-a7c4b2ddab2c\",\"name\":\"Abraham Lincoln\",\"roles\":[\"http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor\"]},{\"status\":\"Active\",\"user_id\":\"8c119130-88a1-4bc0-9dac-d5dab2569c58\",\"name\":\"Ulysses Grant\",\"roles\":[\"http://purl.imsglobal.org/vocab/lis/v2/membership#Learner\"]},{\"status\":\"Active\",\"user_id\":\"9e5f9e00-1dc1-4cd9-b321-5bec4c891fe2\",\"name\":\"William Sherman\",\"roles\":[\"http://purl.imsglobal.org/vocab/lis/v2/membership#Learner\"]},{\"status\":\"Active\",\"user_id\":\"bbb134a1-58f1-42b2-84f7-78871b7ac6f6\",\"name\":\"George McClellan\",\"roles\":[\"http://purl.imsglobal.org/vocab/lis/v2/membership#Learner\"]},{\"status\":\"Active\",\"user_id\":\"3f4ade7b-29b2-4189-b338-e8ee036f15aa\",\"name\":\"Ambrose Burnside\",\"roles\":[\"http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor\"]}]}",
      headers: {
        "link" => %{<https://atomicjolt.instructure.com/api/lti/courses/3334/names_and_roles?opaqueA>; rel="current", <https://atomicjolt.instructure.com/api/lti/courses/3334/names_and_roles?opaqueC>; rel="first", <https://atomicjolt.instructure.com/api/lti/courses/3334/names_and_roles?opaqueD>; rel="last"}
      }
    )
end

# Line items
def stub_line_items_list
  stub_request(:get, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/courses/[0-9]+/line_items|).
    to_return(
      status: 200,
      body: "[{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/25\",\"scoreMaximum\":10.0,\"label\":\"LTI Advantage test item 2019-07-18 23:18:24 UTC\",\"resourceId\":\"1\",\"tag\":\"lti-advantage\",\"#{AtomicLti::Definitions::CANVAS_SUBMISSION_TYPE}\":{\"type\":\"external_tool\",\"external_tool_url\":\"https://helloworld.atomicjolt.xyz/lti_launches\"}},{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/24\",\"scoreMaximum\":10.0,\"label\":\"LTI Advantage test item 2019-07-18 23:18:24 UTC\",\"resourceLinkId\":\"7c358941-9b49-45fd-be81-c222284d38d7\"},{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/27\",\"scoreMaximum\":10.0,\"label\":\"LTI Advantage test item 2019-07-17 22:59:42 UTC\",\"resourceId\":\"1\",\"tag\":\"lti-advantage\",\"#{AtomicLti::Definitions::CANVAS_SUBMISSION_TYPE}\":{\"type\":\"external_tool\",\"external_tool_url\":\"https://helloworld.atomicjolt.xyz/lti_launches\"}},{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/26\",\"scoreMaximum\":10.0,\"label\":\"LTI Advantage test item 2019-07-17 22:59:42 UTC\",\"resourceLinkId\":\"29ddee58-1636-4436-a5de-8c643695708f\"}]",
    )
end

def stub_line_items_list_all
  stub_request(:get, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/courses/[0-9]+/line_items$|).
    to_return(
      status: 200,
      body: "[{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/25\",\"scoreMaximum\":10.0,\"label\":\"LTI Advantage test item 2019-07-18 23:18:24 UTC\",\"resourceId\":\"1\",\"tag\":\"lti-advantage\",\"#{AtomicLti::Definitions::CANVAS_SUBMISSION_TYPE}\":{\"type\":\"external_tool\",\"external_tool_url\":\"https://helloworld.atomicjolt.xyz/lti_launches\"}},{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/24\",\"scoreMaximum\":10.0,\"label\":\"LTI Advantage test item 2019-07-18 23:18:24 UTC\",\"resourceLinkId\":\"7c358941-9b49-45fd-be81-c222284d38d7\"},{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/27\",\"scoreMaximum\":10.0,\"label\":\"LTI Advantage test item 2019-07-17 22:59:42 UTC\",\"resourceId\":\"1\",\"tag\":\"lti-advantage\",\"#{AtomicLti::Definitions::CANVAS_SUBMISSION_TYPE}\":{\"type\":\"external_tool\",\"external_tool_url\":\"https://helloworld.atomicjolt.xyz/lti_launches\"}},{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/26\",\"scoreMaximum\":10.0,\"label\":\"LTI Advantage test item 2019-07-17 22:59:42 UTC\",\"resourceLinkId\":\"29ddee58-1636-4436-a5de-8c643695708f\"}]",
      headers: {
        "link" => %{<https://atomicjolt.instructure.com/api/lti/courses/3334/line_items?opaqueA>; rel="current", <https://atomicjolt.instructure.com/api/lti/courses/3334/line_items?opaqueB>; rel="next", <https://atomicjolt.instructure.com/api/lti/courses/3334/line_items?opaqueC>; rel="first", <https://atomicjolt.instructure.com/api/lti/courses/3334/line_items?opaqueD>; rel="last"}
      }
    )
  stub_request(:get, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/courses/[0-9]+/line_items\?opaqueB|).
    to_return(
      status: 200,
      body: "[{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/125\",\"scoreMaximum\":10.0,\"label\":\"LTI Advantage test item 2019-07-18 23:18:24 UTC\",\"resourceId\":\"1\",\"tag\":\"lti-advantage\",\"#{AtomicLti::Definitions::CANVAS_SUBMISSION_TYPE}\":{\"type\":\"external_tool\",\"external_tool_url\":\"https://helloworld.atomicjolt.xyz/lti_launches\"}},{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/124\",\"scoreMaximum\":10.0,\"label\":\"LTI Advantage test item 2019-07-18 23:18:24 UTC\",\"resourceLinkId\":\"7c358941-9b49-45fd-be81-c222284d38d7\"},{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/127\",\"scoreMaximum\":10.0,\"label\":\"LTI Advantage test item 2019-07-17 22:59:42 UTC\",\"resourceId\":\"1\",\"tag\":\"lti-advantage\",\"#{AtomicLti::Definitions::CANVAS_SUBMISSION_TYPE}\":{\"type\":\"external_tool\",\"external_tool_url\":\"https://helloworld.atomicjolt.xyz/lti_launches\"}},{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/126\",\"scoreMaximum\":10.0,\"label\":\"LTI Advantage test item 2019-07-17 22:59:42 UTC\",\"resourceLinkId\":\"29ddee58-1636-4436-a5de-8c643695708f\"}]",
      headers: {
        "link" => %{<https://atomicjolt.instructure.com/api/lti/courses/3334/line_items?opaqueA>; rel="current", <https://atomicjolt.instructure.com/api/lti/courses/3334/line_items?opaqueC>; rel="first", <https://atomicjolt.instructure.com/api/lti/courses/3334/line_items?opaqueD>; rel="last"}
      }
    )
end

def stub_line_item_show
  stub_request(:get, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/courses/[0-9]+/line_items/[0-9]+|).
    to_return(
      status: 200,
      body: "{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31\",\"scoreMaximum\":10.0,\"label\":\"LTI Advantage test item 2019-07-18 23:46:09 UTC\",\"resourceId\":\"1\",\"tag\":\"lti-advantage\",\"#{AtomicLti::Definitions::CANVAS_SUBMISSION_TYPE}\":{\"type\":\"external_tool\",\"external_tool_url\":\"https://helloworld.atomicjolt.xyz/lti_launches\"}}",
    )
end

def stub_line_item_create
  stub_request(:post, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/courses/[0-9]+/line_items|).
    to_return(
      status: 200,
      body: "{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/29\",\"scoreMaximum\":10.0,\"label\":\"LTI Advantage test item 2019-07-18 23:43:16 UTC\",\"resourceId\":\"1\",\"tag\":\"lti-advantage\",\"#{AtomicLti::Definitions::CANVAS_SUBMISSION_TYPE}\":{\"type\":\"external_tool\",\"external_tool_url\":\"https://helloworld.atomicjolt.xyz/lti_launches\"}}",
    )
end

def stub_line_item_update
  stub_request(:put, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/courses/[0-9]+/line_items/[0-9]+|).
    to_return(
      status: 200,
      body: "{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31\",\"scoreMaximum\":10.0,\"label\":\"LTI Advantage test item 2019-07-18 23:46:09 UTC\",\"resourceId\":\"1\",\"tag\":\"lti-advantage\",\"#{AtomicLti::Definitions::CANVAS_SUBMISSION_TYPE}\":{\"type\":\"external_tool\",\"external_tool_url\":\"https://helloworld.atomicjolt.xyz/lti_launches\"}}",
    )
end

def stub_line_item_delete
  stub_request(:delete, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/courses/[0-9]+/line_items/[0-9]+|).
    to_return(
      status: 200,
      body: nil,
    )
end

def stub_result_show
  stub_request(:get, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/courses/[0-9]+/line_items/[0-9]+/results/[0-9]+|).
    to_return(
      status: 200,
      body: "{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31/results/101\",\"scoreOf\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31\",\"userId\":\"6adc5f3a-27dd-4c27-82f0-c013930ccf6a\",\"resultScore\":10.0,\"resultMaximum\":10.0,\"comment\":\"You wrote the thing\"}",
    )
end

def stub_result_list
  stub_request(:get, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/courses/[0-9]+/line_items/[0-9]+/results|).
    to_return(
      status: 200,
      body: "[{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31/results/101\",\"scoreOf\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31\",\"userId\":\"6adc5f3a-27dd-4c27-82f0-c013930ccf6a\",\"resultScore\":10.0,\"resultMaximum\":10.0,\"comment\":\"You wrote the thing\"}]",
    )
end

def stub_result_list_all
  stub_request(:get, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/courses/[0-9]+/line_items/[0-9]+/results$|).
    to_return(
      status: 200,
      body: "[{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31/results/101\",\"scoreOf\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31\",\"userId\":\"6adc5f3a-27dd-4c27-82f0-c013930ccf6a\",\"resultScore\":10.0,\"resultMaximum\":10.0,\"comment\":\"You wrote the thing\"}]",
      headers: {
        "link" => %{<https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31/results?opaqueA>; rel="current", <https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31/results?opaqueB>; rel="next", <https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31/results?opaqueC>; rel="first", <https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31/results?opaqueD>; rel="last"}
      }
    )
  stub_request(:get, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/courses/[0-9]+/line_items/[0-9]+/results\?opaqueB|).
    to_return(
      status: 200,
      body: "[{\"id\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31/results/201\",\"scoreOf\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31\",\"userId\":\"7adc5f3a-27dd-4c27-82f0-c013930ccf6a\",\"resultScore\":10.0,\"resultMaximum\":10.0,\"comment\":\"You wrote the thing\"}]",
      headers: {
        "link" => %{<https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31/results?opaqueA>; rel="current", <https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31/results?opaqueC>; rel="first", <https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31/results?opaqueD>; rel="last"}
      }
    )
end

# Scores
def stub_scores_create
  stub_request(:post, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/courses/[0-9]+/line_items/[0-9]+/scores|).
    to_return(
      status: 200,
      body: "{\"resultUrl\":\"https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31/results/4\"}",
    )
end

def stub_platform_notifications_get
  stub_request(:get, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/deployments/[0-9a-z-]+/pns|).
    to_return(
      status: 200,
      body: "{\"client_id\":\"c8b93c66-3cd9-4cd7-976f-9e49ad674a0c\",\"deployment_id\":\"d8d80f67-4def-46ea-9bed-ddd1151e5e6b\",\"notice_handlers\":[{\"notice_type\":\"LtiContextCopyNotice\",\"handler\":\"https://atomicjournalsds.atomicjolt.win/lti_platform_notifications\"}]}",
    )
end

def stub_platform_notifications_put
  stub_request(:put, %r|https*://[a-zA-Z0-9]+\.[a-zA-Z0-9]+.*com/api/lti/deployments/[0-9a-z-]+/pns|).
    to_return(
      status: 200,
      body: "{\"client_id\":\"c8b93c66-3cd9-4cd7-976f-9e49ad674a0c\",\"deployment_id\":\"d8d80f67-4def-46ea-9bed-ddd1151e5e6b\",\"notice_handlers\":[{\"notice_type\":\"LtiContextCopyNotice\",\"handler\":\"https://atomicjournalsds.atomicjolt.win/lti_platform_notifications\"}]}",
    )
end
