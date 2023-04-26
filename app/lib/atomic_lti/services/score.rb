module AtomicLti
  module Services
    # Canvas docs: https://canvas.instructure.com/doc/api/score.html
    class Score < AtomicLti::Services::Base

      attr_accessor :id

      def initialize(lti_token: nil, iss:nil, deployment_id: nil, id: nil)
        super(lti_token: lti_token, iss: iss, deployment_id: deployment_id)
        @id = id
      end

      def scopes
        [AtomicLti::Definitions::AGS_SCOPE_SCORE]
      end

      def endpoint
        if id.blank?
          raise ::AtomicLti::Exceptions::ScoreError,
                "Invalid id or no id provided. Unable to access scores. id should be in the form of a url."
        end
        uri = URI(id)
        uri.path = uri.path+'/scores'
        uri
      end

      def generate(
        user_id:,
        score:,
        max_score:,
        comment: nil,
        timestamp: Time.now,
        activity_progress: "Completed",
        grading_progress: "FullyGraded"
      )
        {
          # The lti_user_id or the Canvas user_id
          userId: user_id,
          # The Current score received in the tool for this line item and user, scaled to
          # the scoreMaximum
          scoreGiven: score,
          # Maximum possible score for this result; it must be present if scoreGiven is
          # present.
          scoreMaximum: max_score,
          # Comment visible to the student about this score.
          comment: comment,
          # Date and time when the score was modified in the tool. Should use subsecond
          # precision.
          timestamp: timestamp.iso8601(3),
          # Indicate to Canvas the status of the user towards the activity's completion.
          # Must be one of Initialized, Started, InProgress, Submitted, Completed
          activityProgress: activity_progress,
          # Indicate to Canvas the status of the grading process. A value of
          # PendingManual will require intervention by a grader. Values of NotReady,
          # Failed, and Pending will cause the scoreGiven to be ignored. FullyGraded
          # values will require no action. Possible values are NotReady, Failed, Pending,
          # PendingManual, FullyGraded
          gradingProgress: grading_progress,
        }.compact
      end

      def send(attrs)
        content_type = { "Content-Type" => "application/vnd.ims.lis.v1.score+json" }
        HTTParty.post(
          endpoint,
          body: attrs.to_json,
          headers: headers(content_type),
        )
      end

    end
  end
end
