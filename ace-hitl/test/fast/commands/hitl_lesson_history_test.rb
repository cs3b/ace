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
        end
      end
    end
  end
end
