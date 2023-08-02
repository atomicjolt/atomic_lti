require "rails_helper"

RSpec.describe AtomicLti::Services::NamesAndRoles do
  before do
    setup_canvas_lti_advantage
    @id_token_decoded = AtomicLti::Authorization.validate_token(@params["id_token"])
    # mock all requests to get a token
    stub_token_create
  end

  describe "valid?" do
    it "indicates if the launch contains the names and roles scope" do
      names_and_roles_service = AtomicLti::Services::NamesAndRoles.new(id_token_decoded: @id_token_decoded)
      expect(names_and_roles_service.valid?).to eq true
    end
  end

  describe "list" do
    before do
      stub_names_and_roles_list
    end

    it "requests only the names and roles scope" do
      expect(AtomicLti::Authorization).to receive(:request_token).
        with(hash_including({ scopes: [AtomicLti::Definitions::NAMES_AND_ROLES_SCOPE] })).
        and_return("token")
      names_and_roles_service = AtomicLti::Services::NamesAndRoles.new(id_token_decoded: @id_token_decoded)
      names_and_roles_service.list
    end

    it "lists users in the course and their roles" do
      names_and_roles_service = AtomicLti::Services::NamesAndRoles.new(id_token_decoded: @id_token_decoded)
      names_and_roles = JSON.parse(names_and_roles_service.list.body)
      expect(names_and_roles["members"]).to be_present
    end

    it "adds a valid query string when a query argument is given" do
      allow(HTTParty).to receive(:get)
      names_and_roles_service = AtomicLti::Services::NamesAndRoles.new(id_token_decoded: @id_token_decoded)
      query = { role: "http://purl.imsglobal.org/vocab/lis/v2/membership#Learner" }
      names_and_roles_service.list(query: query)

      expect(HTTParty).to have_received(:get).with(
        "#{@id_token_decoded.dig(AtomicLti::Definitions::NAMES_AND_ROLES_CLAIM, 'context_memberships_url')}?#{query.to_query}",
        anything,
      )
    end

    context "when it looks like the LTI key is set to private" do
      before do
        allow(HTTParty).to receive(:get).and_return(
          OpenStruct.new(
            {
              body: {
                "members": [
                  { "status" => "Active", "user_id" => "1", "roles" => ["learner"] },
                  { "status" => "Active", "user_id" => "2", "roles" => ["learner"] },
                ],
              }.to_json,
            },
          ),
        )
      end

      it "raises an exception with a helpful error message" do
        names_and_roles_service = AtomicLti::Services::NamesAndRoles.new(id_token_decoded: @id_token_decoded)
        expect do
          names_and_roles_service.list
        end.to raise_exception(
          AtomicLti::Exceptions::NamesAndRolesError,
          "Unable to fetch user data. Your LTI key may be set to private.",
        )
      end
    end
  end
end
