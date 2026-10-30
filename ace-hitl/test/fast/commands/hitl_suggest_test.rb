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

          # Regression (PR #398 review, F8): a reply landing between the
          # case resolution and the suggestion write must survive. The
          # whole read-validate-write cycle runs under one exclusive lock
          # against the CURRENT content, so the suggestion operates on the
          # answered case — and is discarded — instead of overwriting the
          # stale, unanswered body and deleting the human decision.
          def test_a_concurrent_reply_between_resolution_and_write_survives
            suggestion_error = nil

            # Hold the case lock BEFORE the suggestion starts, so the
            # suggestion blocks before its locked read; land the human
            # answer (the exact on-disk effect of a concurrent reply),
            # then let the suggestion through.
            File.open("#{@event.file_path}.lock", File::RDWR | File::CREAT, 0o600) do |lock|
              lock.flock(File::LOCK_EX)

              writer = Thread.new do
                begin
                  @manager.add_suggestion(@event.id, author: "second-captain",
                    text: "Proceed with batch 2", rationale: "tests green")
                rescue StandardError => e
                  suggestion_error = e
                end
              end

              writer.join(0.3)
              assert writer.alive?,
                "the suggestion must wait for the case lock (error: #{suggestion_error.inspect})"

              content = File.read(@event.file_path)
              frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse!(content)
              frontmatter["answered"] = true
              frontmatter["status"] = "answered"
              frontmatter["answered_at"] = Time.now.utc
              answered_body = Molecules::HitlAnswerEditor.apply(body.sub(/\A\n/, ""), "Stop the batch\n")
              File.write(@event.file_path, Ace::Support::Items::Atoms::FrontmatterSerializer.rebuild(
                frontmatter, answered_body))
              lock.flock(File::LOCK_UN)
              writer.join
            end

            body = File.read(@event.file_path)
            assert_match(/^## Answer/, body, "the human answer survives the suggestion write")
            assert_match(/^Stop the batch$/, body)
            assert body.include?("answered: true"),
              "the answered flag from the concurrent reply survives"
            refute body.include?("## Suggestion"),
              "a suggestion computed against the answered case is discarded, not written"
            assert suggestion_error.is_a?(Organisms::HitlManager::SuggestionRefusedError),
              "the suggestion is refused against the answered case, not silently written"
          end
        end
      end
    end
  end
end
