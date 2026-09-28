# frozen_string_literal: true

require "json"
require "test_helper"

module Ace
  module Herdr
    module Molecules
      class PaneTidyProbeTest < Minitest::Test
        # Native response shapes captured from herdr 0.9.1
        # (`herdr agent get`, `herdr pane process-info`).
        def agent_result(status)
          native_result(result: {agent: {"agent_status" => status, "pane_id" => "w5:p1"}, type: "agent_info"})
        end

        def process_result(processes)
          native_result(result: {
            process_info: {"foreground_processes" => processes, "pane_id" => "w5:p1", "shell_pid" => 96849},
            type: "pane_process_info"
          })
        end

        def native_result(payload)
          ExecutionResult.new(stdout: JSON.generate(payload), stderr: "", success: true, exit_code: 0)
        end

        def probe(outcomes = {})
          executor = HerdrTestHelper::FakeExecutor.new(outcomes: outcomes)
          [executor, PaneTidyProbe.pane_evidence(executor, "w5:p1")]
        end

        def test_agent_done_qualifies
          executor, evidence = probe(agent_get: agent_result("done"))

          assert_equal :agent_done, evidence
          assert_equal [{operation: :agent_get, args: {pane: "w5:p1"}}], executor.calls
        end

        def test_live_agent_states_preserve
          %w[idle working blocked].each do |status|
            _, evidence = probe(agent_get: agent_result(status))

            assert_equal :active, evidence, status
          end
        end

        def test_unknown_agent_status_preserves
          _, evidence = probe(agent_get: agent_result("unknown"))

          assert_equal :unknown, evidence
        end

        def test_missing_agent_status_preserves
          _, evidence = probe(agent_get: agent_result(nil))

          assert_equal :unknown, evidence
        end

        def test_malformed_agent_response_preserves
          broken = ExecutionResult.new(stdout: "{not json", stderr: "", success: true, exit_code: 0)

          _, evidence = probe(agent_get: broken)

          assert_equal :unknown, evidence
        end

        def test_unexpected_agent_response_shape_preserves
          _, evidence = probe(agent_get: native_result(result: {agent: "idle"}))

          assert_equal :unknown, evidence
        end

        def test_missing_agent_falls_through_to_process_probe
          outcomes = {
            agent_get: AgentNotFoundError.new("agent_not_found: gone"),
            pane_process_info: process_result([])
          }

          executor, evidence = probe(outcomes)

          assert_equal :process_exited, evidence
          assert_equal [:agent_get, :pane_process_info], executor.calls.map { |c| c[:operation] }
        end

        def test_empty_foreground_process_list_qualifies
          _, evidence = probe(
            agent_get: AgentNotFoundError.new("agent_not_found: gone"),
            pane_process_info: process_result([])
          )

          assert_equal :process_exited, evidence
        end

        def test_live_process_preserves
          _, evidence = probe(
            agent_get: AgentNotFoundError.new("agent_not_found: gone"),
            pane_process_info: process_result([{"argv0" => "fish", "name" => "fish", "pid" => 96849}])
          )

          assert_equal :active, evidence
        end

        def test_missing_process_info_object_preserves
          _, evidence = probe(
            agent_get: AgentNotFoundError.new("agent_not_found: gone"),
            pane_process_info: native_result(result: {nope: true})
          )

          assert_equal :unknown, evidence
        end

        # Native empty serialization: herdr omits foreground_processes when
        # empty (serde skip_serializing_if, v0.9.1 schema/panes.rs)
        def test_absent_foreground_processes_is_the_native_exit_proof
          _, evidence = probe(
            agent_get: AgentNotFoundError.new("agent_not_found: gone"),
            pane_process_info: native_result(result: {
              process_info: {"pane_id" => "w5:p1", "shell_pid" => 96849}
            })
          )

          assert_equal :process_exited, evidence
        end

        def test_non_array_foreground_processes_preserve
          _, evidence = probe(
            agent_get: AgentNotFoundError.new("agent_not_found: gone"),
            pane_process_info: native_result(result: {
              process_info: {"foreground_processes" => "fish", "pane_id" => "w5:p1"}
            })
          )

          assert_equal :unknown, evidence
        end

        def test_vanished_pane_reports_gone
          outcomes = {
            agent_get: PaneNotFoundError.new("pane_not_found: gone"),
            pane_process_info: PaneNotFoundError.new("pane_not_found: gone")
          }

          _, evidence = probe(outcomes)

          assert_equal :gone, evidence
        end

        def test_probe_failure_preserves
          _, evidence = probe(agent_get: CommandError.new("herdr command failed (exit 1)"))

          assert_equal :unreadable, evidence
        end

        def test_unavailable_runtime_preserves
          _, evidence = probe(agent_get: ExecutorUnavailableError.new("herdr CLI not found on PATH"))

          assert_equal :unreadable, evidence
        end
      end
    end
  end
end
