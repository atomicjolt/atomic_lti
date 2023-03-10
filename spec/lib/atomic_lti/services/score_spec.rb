require "rails_helper"

RSpec.describe AtomicLti::Services::Score do
  before do
    setup_canvas_lti_advantage
    @lti_token = AtomicLti::Authorization.validate_token(@params["id_token"])
    @score_service = AtomicLti::Services::Score.new(lti_token: @lti_token, iss: nil, deployment_id: nil)
    @score_service.id = "https://atomicjolt.instructure.com/api/lti/courses/3334/line_items/31"
    # mock all requests to get a token
    stub_token_create
  end

  describe "send" do
    it "sends a score for the specified line item" do
      stub_scores_create
      score = @score_service.generate(
        user_id: "cfca15d8-2958-4647-a33e-a7c4b2ddab2c",
        score: 10,
        max_score: 10,
        comment: "Great job",
        activity_progress: "Completed",
        grading_progress: "FullyGraded",
      )
      result = JSON.parse(@score_service.send(score))
      expect(result["resultUrl"].present?).to be true
    end
  end
end
