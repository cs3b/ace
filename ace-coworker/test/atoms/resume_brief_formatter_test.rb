# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module Atoms
      class ResumeBriefFormatterTest < AceCoworkerTestCase
        def plan(disposition:, **rest)
          Models::ResumePlan.new(disposition: disposition, **rest)
        end

        def test_complete_renders_informational_line
          out = ResumeBriefFormatter.format_table(plan(disposition: :complete))
          assert_includes out, "Coworker resume"
          assert_includes out, "nothing to resume"
        end

        def test_report_disposition_renders_resend_line
          result = Organisms::ResumeOrchestrator::ResumeResult.new(
            plan: nil, message: "redelivering", exit_code: 1)
          p = plan(disposition: :report, redeliver_event_id: "ab12cd")
          out = ResumeBriefFormatter.format_table(p, result)

          assert_includes out, "report delivery missing"
          assert_includes out, "resend event:      ab12cd"
          assert_includes out, "retrying delivery never retries the assignment"
        end

        def test_continue_rendes_full_guidance
          p = plan(disposition: :continue,
            preserved_steps: ["010 impl"],
            remaining_steps: ["020 merge-pr (active)"],
            in_flight: {"number" => "020", "name" => "merge-pr", "status" => "active"},
            in_flight_cause: "conflict",
            git: {"branch" => "feat", "dirty_entries" => ["M a.rb"]},
            effect_caution_steps: ["020 merge-pr (active)"])
          out = ResumeBriefFormatter.format_table(p)

          assert_includes out, "branch:            feat"
          assert_includes out, "done: 010 impl"
          assert_includes out, "020 merge-pr (active)"
          assert_includes out, "recorded cause:  conflict"
          assert_includes out, "do not reset local changes"
          assert_includes out, "M a.rb"
          assert_includes out, "effect caution"
          assert_includes out, "never replay blindly; same task, assignment and worktree"
        end
      end
    end
  end
end
