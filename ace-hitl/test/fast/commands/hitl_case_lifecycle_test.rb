# frozen_string_literal: true

require_relative "../../test_helper"
require "json"

module Ace
  module Hitl
    module CLI
      module Commands
        # Case lifecycle contract (task 8xs.t.pu0.6): receipt → received →
        # applied (with the effect owner reference) → closed; cancelled is
        # terminal without application; duplicates are no-ops; late or
        # conflicting answers never change a finished decision; sweep
        # removes only closed-linked transport leftovers.
        class HitlCaseLifecycleTest < AceHitlTestCase
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

          def run_with_cli_root
            out, = capture_io do
              with_cli_root(@root, config: @config) { yield }
            end
            JSON.parse(out)
          end

          def deliver_answer(text = "Proceed\n", case_id: @event.id)
            run_with_cli_root do
              $stdin = StringIO.new(text)
              begin
                Reply.new.call(case_id: case_id, stdin: true, quiet: true)
              ensure
                $stdin = STDIN
              end
            end
          end

          def test_lifecycle_records_receipt_application_and_close
            deliver_answer

            lifecycle = @manager.case_lifecycle(@event.id)
            assert_equal "received", lifecycle["receipt"]
            assert_equal "pending", lifecycle["application"]

            applied = run_with_cli_root { Apply.new.call(case_id: @event.id, ref: "pr:398") }
            assert_equal "applied", applied["state"]

            lifecycle = @manager.case_lifecycle(@event.id)
            assert_equal "applied", lifecycle["application"]
            assert_equal "pr:398", lifecycle["effect_ref"]

            closed = run_with_cli_root { Close.new.call(case_id: @event.id) }
            assert_equal "closed", closed["state"]
            assert_equal "closed", @manager.case_lifecycle(@event.id)["application"]
          end

          def test_close_requires_the_applied_proof
            deliver_answer

            error = assert_raises(Ace::Support::Cli::Error) do
              run_with_cli_root { Close.new.call(case_id: @event.id) }
            end
            assert_match(/not closed:.*no applied effect/, error.message)
          end

          def test_reapplying_the_same_effect_is_a_noop_and_a_different_effect_conflicts
            deliver_answer
            run_with_cli_root { Apply.new.call(case_id: @event.id, ref: "pr:398") }

            duplicate = run_with_cli_root { Apply.new.call(case_id: @event.id, ref: "pr:398") }
            assert_equal "duplicate", duplicate["state"]

            error = assert_raises(Ace::Support::Cli::Error) do
              run_with_cli_root { Apply.new.call(case_id: @event.id, ref: "pr:400") }
            end
            assert_match(/not applied:.*conflict/, error.message)
          end

          def test_late_different_answer_never_reopens_or_changes_a_closed_decision
            deliver_answer
            run_with_cli_root { Apply.new.call(case_id: @event.id, ref: "pr:398") }
            run_with_cli_root { Close.new.call(case_id: @event.id) }
            path = @event.file_path
            frozen = File.read(path)

            error = assert_raises(Ace::Support::Cli::Error) { deliver_answer("Actually stop\n") }
            assert_match(/not delivered:.*never overwrites/, error.message)
            assert_equal frozen, File.read(path), "a closed case never changes"

            error = assert_raises(Ace::Support::Cli::Error) do
              run_with_cli_root { Apply.new.call(case_id: @event.id, ref: "pr:398") }
            end
            assert_match(/not applied:.*never re-opens/, error.message)
          end

          def test_cancel_is_terminal_only_without_an_applied_effect
            cancelled = @manager.cancel_case(@event.id)
            assert_equal :cancelled, cancelled

            duplicate = @manager.cancel_case(@event.id)
            assert_equal :duplicate, duplicate

            # an answered-but-unapplied case may still be cancelled (the
            # answer was never applied); an APPLIED effect is history and
            # can only be closed
            answered = @manager.create("Answered but dropped", type: "question", to: "captain")
            deliver_answer("Never mind\n", case_id: answered.id)
            assert_equal :cancelled, @manager.cancel_case(answered.id)

            applied_case = @manager.create("Applied work", type: "question", to: "captain")
            deliver_answer("Go\n", case_id: applied_case.id)
            @manager.apply_answer_effect(applied_case.id, "pr:1")
            error = assert_raises(Organisms::HitlManager::LifecycleTransitionError) do
              @manager.cancel_case(applied_case.id)
            end
            assert_match(/only an unanswered, unapplied case/, error.message)
          end

          def test_sweep_lists_and_removes_only_closed_case_leftovers
            # an active case with its live wake request
            active_request = write_wake_request(@event.id)
            # a closed case with its leftover request
            closed_case = @manager.create("Closed work", type: "question", to: "captain")
            closed_request = write_wake_request(closed_case.id)
            deliver_answer("Done\n", case_id: closed_case.id)
            @manager.apply_answer_effect(closed_case.id, "assignment:job-7")
            @manager.close_case(closed_case.id)
            # a request pointing at an unknown case
            unknown_request = write_wake_request("8xt0unknown")

            report = @manager.sweep
            qualified = report["qualified"].map { |entry| entry["case"] }
            preserved = report["preserved"].map { |entry| File.basename(entry["request"]) }
            assert_equal [closed_case.id], qualified
            assert_includes preserved, File.basename(active_request)
            assert_includes preserved, File.basename(unknown_request)
            assert File.exist?(closed_request), "without --apply nothing is removed"

            applied_report = @manager.sweep(apply: true)
            assert_equal [closed_case.id], applied_report["removed"].map { |entry| entry["case"] }
            refute File.exist?(closed_request)
            assert File.exist?(active_request)
            assert File.exist?(unknown_request)

            # the canonical decision history survives the sweep
            assert File.exist?(closed_case.file_path)
            assert_match(/## Answer/, File.read(closed_case.file_path))
          end

          private

          def write_wake_request(case_id)
            requests_dir = File.join(@root, "wake-requests")
            FileUtils.mkdir_p(requests_dir)
            path = File.join(requests_dir, "#{case_id}.json")
            File.write(path, JSON.generate({"schema" => "ace.wake.ask/v1", "case_id" => case_id}))
            path
          end
        end
      end
    end
  end
end
