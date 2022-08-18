module AtomicLti
  module Services
    # Canvas docs: https://canvas.instructure.com/doc/api/score.html
    class ScoreCanvas < Score

      def generate(
        new_submission: true,
        submission_type: nil,
        submission_data: nil,
        submitted_at: nil,
        content_items: nil,
        **standard_attrs
      )
        submission_data = {
          # (EXTENSION field) flag to indicate that this is a new submission.
          # Defaults to true unless submission_type is none.
          new_submission: new_submission,

          # (EXTENSION field) permissible values are: none, basic_lti_launch,
          # online_text_entry, external_tool, online_upload, or online_url.
          # Defaults to external_tool. Ignored if content_items are provided.
          submission_type: submission_type,

          # (EXTENSION field) submission data (URL or body text). Only used
          # for submission_types basic_lti_launch, online_text_entry, online_url.
          # Ignored if content_items are provided.
          submission_data: submission_data,

          # (EXTENSION field) Date and time that the submission was originally created.
          # Should use ISO8601-formatted date with subsecond precision. This should match
          # the data and time that the original submission happened in Canvas.
          submitted_at: submitted_at,

          # (EXTENSION field) Files that should be included with the submission. Each item
          # should contain `type: file`, and a url pointing to the file. It can also contain
          # a title, and an explicit MIME type if needed (otherwise, MIME type will be
          # inferred from the title or url). If any items are present, submission_type
          # will be online_upload.
          content_items: content_items,
        }.compact

        super(**standard_attrs).
          merge({ "https://canvas.instructure.com/lti/submission": submission_data })
      end
    end
  end
end
