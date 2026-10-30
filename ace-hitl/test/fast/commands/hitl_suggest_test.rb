# frozen_string_literal: true

require_relative "../../test_helper"
require "json"

module Ace
  module Hitl
    module CLI
      module Commands
        # Second Captain suggestions (task 8xs.t.pu0.b): one marked,
        # authored, rationale-carrying section per case; the Answer can
        # never remove it; the human decision always outranks it.
        class HitlSuggestTest < AceHitlTestCase
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

          def suggest(case_id: @event.id, by: "second-captain", text: "Proceed with batch 2",
            rationale: "tests green at the reviewed head")
            out, = capture_io do
              with_cli_root(@root, config: @config) do
                Suggest.new.call(case_id: case_id, by: by, text: text,
                  rationale: rationale, refs: "pr:398,task:8xs.t.pu0.b")
              end
            end
            JSON.parse(out)
          end

          def deliver_answer(text = "Proceed\n")
            capture_io do
              with_cli_root(@root, config: @config) do
                $stdin = StringIO.new(text)
                begin
                  Reply.new.call(case_id: @event.id, stdin: true, quiet: true)
                ensure
                  $stdin = STDIN
                end
              end
            end
          end

          def test_a_suggestion_is_marked_authored_and_grounded_in_the_case
            result = suggest

            assert_equal "written", result["suggestion"]
            body = File.read(@event.file_path)
            assert_match(/^## Suggestion/, body)
            assert_match(/^author: second-captain$/, body)
            assert_match(/^proposal: Proceed with batch 2$/, body)
            assert_match(/^rationale: tests green at the reviewed head$/, body)
            assert_match(%r{^refs: pr:398, task:8xs\.t\.pu0\.b$}, body)
            refute_match(/^answered: true/, body, "a suggestion never answers the case")
          end

          def test_an_identical_repeat_is_a_noop_and_a_different_second_is_refused
            first = suggest
            second = suggest

            assert_equal "written", first["suggestion"]
            assert_equal "duplicate", second["suggestion"]

            error = assert_raises(Ace::Support::Cli::Error) do
              suggest(text: "Actually stop", rationale: "changed my mind")
            end
            assert_match(/suggestion refused:.*one proposal per case/, error.message)
          end

          def test_the_answer_never_removes_the_suggestion
            suggest
            deliver_answer("Proceed with batch 2\n")

            body = File.read(@event.file_path)
            assert_match(/^## Suggestion/, body, "the suggestion survives the answer")
            assert_match(/^## Answer/, body)
            assert body.index("## Suggestion") < body.index("## Answer"),
              "the suggestion sits before the Answer section"
          end

          def test_a_suggestion_after_the_human_answered_is_discarded
            deliver_answer("Proceed\n")

            error = assert_raises(Ace::Support::Cli::Error) { suggest }
            assert_match(/suggestion refused:.*already answered/, error.message)
            refute File.read(@event.file_path).include?("## Suggestion")
          end

          def test_secret_cases_are_never_delegated_to_the_advisor
            secret = @manager.create("OTP?", type: "question", to: "captain",
              secret: true)

            error = assert_raises(Ace::Support::Cli::Error) do
              suggest(case_id: secret.id)
            end
            assert_match(/suggestion refused:.*secret/, error.message)
          end

          def test_unknown_or_shortcut_case_ids_are_refused
            error = assert_raises(Ace::Support::Cli::Error) { suggest(case_id: "8xt0zz") }
            assert_match(/suggestion refused:.*exact id/, error.message)

            error = assert_raises(Ace::Support::Cli::Error) do
              suggest(case_id: @event.id[-3..])
            end
            assert_match(/suggestion refused:.*exact case id/, error.message)
          end
        end
      end
    end
  end
end
