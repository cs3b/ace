# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Hitl
    module Atoms
      class HitlEventTextTest < AceHitlTestCase
        def question_event
          Models::HitlEvent.new(id: "abc123", status: "pending", kind: "decision",
            type: "question", result: nil, title: "Which DB?", tags: [],
            questions: ["Postgres?", "SQLite?"], answer: nil, content: "",
            path: nil, file_path: nil, special_folder: nil, created_at: nil,
            metadata: {
              "task" => "8xg.t.sbz.1.2", "assignment" => "xyz789", "step" => "030",
              "reply_to_machine" => "lab01", "reply_to_folder" => ".ace-local/hitl",
              "reply_to_id" => "abc123"
            })
        end

        def report_event
          Models::HitlEvent.new(id: "rpt456", status: "recorded", kind: nil,
            type: "report", result: "success", title: "Work done", tags: [],
            questions: [], answer: nil,
            content: "# Work done\n\n## Report\n\nResult: success\n\n- Did the thing\n- Tests green",
            path: nil, file_path: nil, special_folder: nil, created_at: nil,
            metadata: {"task" => "8xg.t.sbz.1.2"})
        end

        def test_question_rendering_with_reply_to_and_context
          text = HitlEventText.call(question_event)
          lines = text.split("\n")

          assert_equal "[HITL question] Which DB? (case abc123)", lines[0]
          assert_equal "Q: Postgres?", lines[1]
          assert_equal "Q: SQLite?", lines[2]
          assert_equal "Reply-To: lab01/.ace-local/hitl/abc123", lines[3]
          assert_equal "Task: 8xg.t.sbz.1.2", lines[4]
          assert_equal "Assignment: xyz789", lines[5]
          assert_equal "Step: 030", lines[6]
        end

        def test_report_rendering_has_no_reply_to
          text = HitlEventText.call(report_event)
          lines = text.split("\n")

          assert_equal "[HITL report success] Work done (case rpt456)", lines[0]
          assert_includes lines, "Result: success"
          assert_includes lines, "- Did the thing"
          assert_includes lines, "- Tests green"
          assert_includes lines, "Task: 8xg.t.sbz.1.2"
          refute_includes lines.join("\n"), "Reply-To:"
        end

        def test_question_without_questions_renders_pending_placeholder
          event = question_event
          event.questions = []
          text = HitlEventText.call(event)
          assert_includes text, "Q: (pending human input)"
        end

        def test_question_without_reply_to_omits_line
          event = question_event
          event.metadata = event.metadata.reject { |key, _| key.start_with?("reply_to") }
          refute_includes HitlEventText.call(event), "Reply-To:"
        end
      end
    end
  end
end
