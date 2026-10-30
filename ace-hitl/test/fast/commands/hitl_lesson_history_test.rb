# frozen_string_literal: true

require_relative "../../test_helper"
require "json"

module Ace
  module Hitl
    module CLI
      module Commands
        # Learning from real decisions (task 8xs.t.pu0.c): a lesson is
        # written at the same case with verifiable references, one per
        # case, idempotent; the decision history is citable, scope-local
        # and secret-free; a closed case preserves question, suggestion,
        # answer AND lesson.
        class HitlLessonHistoryTest < AceHitlTestCase
          def setup
            @dir = Dir.mktmpdir
            @root = File.join(@dir, "hitl")
            @config = {"hitl" => {"root_dir" => @root, "machine" => "lab",
              "recipients" => {"captain" => {"machine" => "lab", "panel" => "cap"}}}}
            @manager = Organisms::HitlManager.new(root_dir: @root, config: @config)
            @event = @manager.create("Proceed?", type: "question", to: "captain",
              kind: "decision")
          end

          def teardown
            FileUtils.remove_entry(@dir) if @dir
          end

          def with_cli(&block)
            capture_io do
              with_cli_root(@root, config: @config, &block)
            end
          end

          def suggest_and_answer(case_event: @event, answer: "Stop the rollout")
            with_cli do
              Suggest.new.call(case_id: case_event.id, by: "second-captain",
                text: "Proceed with batch 2", rationale: "tests green", refs: "pr:398")
              $stdin = StringIO.new(answer)
              begin
                Reply.new.call(case_id: case_event.id, stdin: true, quiet: true)
              ensure
                $stdin = STDIN
              end
            end
          end

          def lesson(case_id: @event.id, takeaway: "Captain prioritized safety over speed",
            relation: "rejected")
            out, = with_cli do
              Lesson.new.call(case_id: case_id, by: "second-captain",
                relation: relation, takeaway: takeaway)
            end
            JSON.parse(out)
          end

          def test_a_rejected_suggestion_becomes_a_referenced_lesson
            suggest_and_answer

            result = lesson

            assert_equal "written", result["lesson"]
            body = File.read(@event.file_path)
            assert_match(/^## Lesson/, body)
            assert_match(/^relation: rejected$/, body)
            assert_match(/^takeaway: Captain prioritized safety over speed$/, body)
            assert_match(%r{^refs: .*case:#{@event.id}, suggestion:#{@event.id}-s1}, body)
            assert_match(/decision:/, body, "the lesson cites the exact decision revision")
            # history preserved: question, suggestion, answer all intact
            assert_match(/^## Suggestion/, body)
            assert_match(/^## Answer/, body)
            assert_match(/Stop the rollout/, body)
          end

          def test_reprocessing_is_idempotent_and_a_different_second_lesson_refused
            suggest_and_answer
            first = lesson
            repeat = lesson

            assert_equal "written", first["lesson"]
            assert_equal "duplicate", repeat["lesson"]

            error = assert_raises(Ace::Support::Cli::Error) do
              lesson(takeaway: "a different takeaway")
            end
            assert_match(/lesson refused:.*does not multiply/, error.message)
          end

          def test_no_suggestion_means_no_comparison_never_fabricated_agreement
            with_cli do
              $stdin = StringIO.new("Proceed\n")
              begin
                Reply.new.call(case_id: @event.id, stdin: true, quiet: true)
              ensure
                $stdin = STDIN
              end
            end

            error = assert_raises(Ace::Support::Cli::Error) { lesson }
            assert_match(/lesson refused:.*no suggestion/, error.message)
            refute File.read(@event.file_path).include?("## Lesson")
          end

          def test_history_is_citable_and_secret_free
            suggest_and_answer
            lesson

            secret = @manager.create("OTP?", type: "question", to: "captain", secret: true)
            with_cli do
              $stdin = StringIO.new("918273\n")
              begin
                Reply.new.call(case_id: secret.id, stdin: true, quiet: true)
              ensure
                $stdin = STDIN
              end
            end

            out, = capture_io do
              with_cli_root(@root, config: @config) do
                History.new.call
              end
            end
            payload = JSON.parse(out)

            assert_equal 1, payload["count"]
            row = payload["history"].first
            assert_equal @event.id, row["id"]
            assert_equal "Proceed with batch 2", row["suggestion"]
            assert_equal "Stop the rollout", row["decision"]
            assert_equal "Captain prioritized safety over speed", row["lesson"]
            assert_equal "rejected", row["lesson_relation"]
            refute payload["history"].any? { |entry| entry["id"] == secret.id },
              "secret/OTP cases never reach the model"
            refute out.include?("918273")
          end

          def test_closing_the_case_preserves_the_whole_history
            suggest_and_answer
            lesson

            with_cli do
              Apply.new.call(case_id: @event.id, ref: "pr:398")
              Close.new.call(case_id: @event.id)
            end

            body = File.read(@event.file_path)
            assert_match(/^## Suggestion/, body)
            assert_match(/^## Lesson/, body)
            assert_match(/^## Answer/, body)
            assert_match(/Stop the rollout/, body)
          end

          # Regression (feedback 8xte508c): history captures the Answer up
          # to the next `## ` header — a Resume Dispatch appended after the
          # Answer never becomes part of the citable decision.
          def test_history_decision_stops_at_the_next_section
            suggest_and_answer
            lesson
            content = File.read(@event.file_path)
            frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse!(content)
            File.write(@event.file_path,
              Ace::Support::Items::Atoms::FrontmatterSerializer.rebuild(
                frontmatter, body.sub(/\s*\z/, "") + "\n\n## Resume Dispatch\n\nresume later\n"))

            rows = @manager.decision_history
            assert_equal 1, rows.size
            assert_equal "Stop the rollout", rows.first["decision"],
              "the decision row carries ONLY the Answer section"
            refute rows.first["decision"].include?("Resume Dispatch")
            refute rows.first["decision"].include?("resume later")
          end

          # Regression (feedback 8xte508i): idempotency matching is scoped
          # to the Suggestion/Lesson sections — a `proposal:` line quoted
          # in the question body never produces a false :duplicate (which
          # would silently swallow a DIFFERENT second proposal instead of
          # refusing it).
          def test_a_quoted_proposal_line_in_the_question_body_is_not_a_duplicate
            @manager.add_suggestion(@event.id, author: "second-captain",
              text: "Proceed with batch 2", rationale: "tests green")

            content = File.read(@event.file_path)
            frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse!(content)
            question, rest = body.split(/^## Suggestion\b/, 2)
            quoted = question.sub(/\s*\z/, "") +
              "\nthe prior case's suggestion read:\nproposal: Actually stop\n\n"
            File.write(@event.file_path,
              Ace::Support::Items::Atoms::FrontmatterSerializer.rebuild(
                frontmatter, quoted + "## Suggestion" + rest.to_s))

            error = assert_raises(Organisms::HitlManager::SuggestionRefusedError) do
              @manager.add_suggestion(@event.id, author: "second-captain",
                text: "Actually stop", rationale: "different proposal")
            end
            assert_match(/one proposal per case/, error.message)
              "the different second proposal is REFUSED, never a silent :duplicate"
          end

          # Regression (feedback 8xte508f): --format table renders rows and
          # --quiet prints nothing — the advertised options are real.
          def test_history_table_format_and_quiet
            suggest_and_answer
            lesson

            out, = capture_io do
              with_cli_root(@root, config: @config) do
                History.new.call(format: "table")
              end
            end
            assert_match(/^CASE\s+DECISION\s+LESSON/, out)
            assert_includes out, @event.id
            assert_includes out, "Stop the rollout"
            assert_includes out, "rejected"

            quiet_out, = capture_io do
              with_cli_root(@root, config: @config) do
                History.new.call(quiet: true)
              end
            end
            assert_empty quiet_out
          end
        end
      end
    end
  end
end
