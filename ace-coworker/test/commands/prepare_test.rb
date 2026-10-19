# frozen_string_literal: true

require_relative "../test_helper"
require "stringio"

module Ace
  module Coworker
    module CLI
      module Commands
        class PrepareTest < AceCoworkerTestCase
          FakeOrchestrator = Struct.new(:result, :calls) do
            def call(kwargs)
              calls << kwargs
              result
            end
          end

          def preparation(**overrides)
            Models::Preparation.new(**{
              task: "8xg.t.aaa", task_path: "/proj/.ace-tasks/8xg.t.aaa-fixture",
              roles: %w[worker reviewer],
              worktree: {"path" => "/proj/.ace-wt/t.8xg-t-aaa", "branch" => "8xg-aaa-b",
                         "disposition" => "created"},
              assignments: [
                {"role" => "worker", "position" => 1, "of" => 2, "assignment" => "seq1",
                 "disposition" => "created", "steps" => 2, "outcome" => "worker outcome"},
                {"role" => "reviewer", "position" => 2, "of" => 2, "assignment" => "seq2",
                 "disposition" => "created", "steps" => 1, "outcome" => "reviewer outcome"}
              ],
              worktree_assignments: []}.merge(overrides))
          end

          def command(result)
            Prepare.new(orchestrator: FakeOrchestrator.new(result, []))
          end

          def capture
            original = $stdout
            $stdout = StringIO.new
            yield
            $stdout.string
          ensure
            $stdout = original
          end

          def test_success_renders_table_and_normalizes_roles
            fake = FakeOrchestrator.new(prep, [])
            out = capture do
              Prepare.new(orchestrator: fake).call(task: " 8xg.t.aaa ",
                roles: ["worker", " reviewer,worker ", ""], format: "table", quiet: false)
            end

            assert_includes out, "Coworker prepare"
            assert_includes out, "8xg.t.aaa"
            assert_includes out, "worker, reviewer"
            assert_includes out, "/proj/.ace-wt/t.8xg-t-aaa"
            assert_includes out, "created"
            assert_equal %w[worker reviewer], fake.calls.first[:roles]
          end

          def test_success_renders_sequence_assignments
            out = capture do
              command(prep).call(task: "8xg.t.aaa", roles: ["worker,reviewer"],
                format: "table", quiet: false)
            end

            assert_includes out, "sequence:"
            assert_includes out, "1/2 worker: seq1 (created, 2 steps)"
            assert_includes out, "2/2 reviewer: seq2 (created, 1 steps)"
            assert_includes out, "expected outcome: reviewer outcome"
          end

          def test_success_renders_json_contract
            out = capture { command(prep).call(task: "8xg.t.aaa", roles: ["worker"],
              format: "json", quiet: false) }
            payload = JSON.parse(out)

            assert_equal "8xg.t.aaa", payload["task"]
            assert_equal %w[worker reviewer], payload["roles"]
            assert_equal "created", payload["worktree"]["disposition"]
            assert_nil payload["conflict"]
            assert_nil payload["active_executor"]
            assert_equal 2, payload["assignments"].length
            first = payload["assignments"].first
            assert_equal "worker", first["role"]
            assert_equal 1, first["position"]
            assert_equal "seq1", first["assignment"]
            assert_equal "worker outcome", first["outcome"]
          end

          def test_conflict_renders_and_raises_cli_error
            conflict = preparation(worktree: nil,
              conflict: {"kind" => "active_executor",
                         "detail" => "a commissioned executor holds the worktree: assignment abc123 (state running)",
                         "hitl_event" => "hitl01", "delivered" => false})
            out = capture do
              error = assert_raises(Ace::Support::Cli::Error) do
                command(conflict).call(task: "8xg.t.aaa", roles: ["worker"], format: "table", quiet: false)
              end
              assert_includes error.message, "active_executor"
            end

            assert_includes out, "conflict:   active_executor"
            assert_includes out, "hitl01"
            assert_includes out, "retry: ace-hitl send hitl01"
          end

          def test_conflict_quiet_still_raises
            conflict = preparation(worktree: nil,
              conflict: {"kind" => "mismatched_worktree", "detail" => "foreign",
                         "hitl_event" => nil, "delivered" => nil})
            out = capture do
              assert_raises(Ace::Support::Cli::Error) do
                command(conflict).call(task: "8xg.t.aaa", roles: ["worker"],
                  format: "json", quiet: true)
              end
            end

            assert_equal "", out
          end

          def test_missing_task_option_raises
            error = assert_raises(Ace::Support::Cli::Error) do
              command(prep).call(task: "  ", roles: ["worker"], format: "table", quiet: false)
            end
            assert_includes error.message, "--task is required"
          end

          def test_missing_roles_option_raises
            error = assert_raises(Ace::Support::Cli::Error) do
              command(prep).call(task: "8xg.t.aaa", roles: [" , "], format: "table", quiet: false)
            end
            assert_includes error.message, "--roles is required"
          end

          def test_orchestrator_receives_options
            fake = FakeOrchestrator.new(prep, [])
            capture do
              Prepare.new(orchestrator: fake).call(task: "8xg.t.aaa", roles: ["worker"],
                to: "overseer@lab", config: "cfg.yml", :"dry-run" => true,
                format: "table", quiet: false)
            end
            kwargs = fake.calls.first

            assert_equal "overseer@lab", kwargs[:to]
            assert_equal "cfg.yml", kwargs[:config_path]
            assert_equal true, kwargs[:dry_run]
          end

          private

          def prep
            @prep ||= preparation
          end
        end
      end
    end
  end
end
