# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module Organisms
      class DispatcherTest < Minitest::Test
        def setup
          @executor = HerdrTestHelper::FakeExecutor.new
          @dispatcher = Dispatcher.new(
            executor: @executor, default_agent_kind: "pi",
            agent_start_timeout_ms: 60_000
          )
        end

        def test_dispatch_creates_tab_exports_env_starts_and_prompts
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            tab_create: tab_result("t1", "p9")
          })
          dispatcher = build_dispatcher

          outcome = dispatcher.dispatch(
            label: "8wm.t.vs0", prompt: "do the work", workspace_id: "ws-1"
          )

          assert_equal "p9", outcome.pane
          assert outcome.tab_created
          assert outcome.prompted
          assert_equal "8wm.t.vs0", outcome.agent_name
          assert_equal "pi", outcome.kind
          run_export = @executor.calls_of(:pane_run).first
          assert_equal "export HERDR_SESSION=ws-1 HERDR_PANE=p9", run_export[:args][:command]
          start = @executor.calls_of(:agent_start).first
          assert_equal({name: "8wm.t.vs0", kind: "pi", pane: "p9", timeout_ms: 60_000}, start[:args])
          assert_equal 1, @executor.calls_of(:agent_prompt).length
        end

        def test_dispatch_uses_caller_workspace_from_env
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            tab_create: tab_result("t1", "p9")
          })
          dispatcher = build_dispatcher

          with_env("HERDR_WORKSPACE_ID" => "ws-env") do
            outcome = dispatcher.dispatch(label: "a1", prompt: "x")

            assert_equal "ws-env", outcome.workspace_id
          end
        end

        def test_dispatch_resolves_workspace_from_pane_current
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_current: Molecules::ExecutionResult.new(
              stdout: JSON.generate({pane_id: "p1", workspace_id: "ws-cur"}),
              stderr: "", success: true, exit_code: 0
            ),
            tab_create: tab_result("t1", "p9")
          })
          dispatcher = build_dispatcher

          with_env("HERDR_WORKSPACE_ID" => nil) do
            outcome = dispatcher.dispatch(label: "a1", prompt: "x")

            assert_equal "ws-cur", outcome.workspace_id
          end
        end

        def test_dispatch_into_existing_pane_does_not_create_tab
          outcome = @dispatcher.dispatch(
            label: "a1", prompt: "x", workspace_id: "ws-1", pane: "p3"
          )

          refute outcome.tab_created
          assert_empty @executor.calls_of(:tab_create)
          assert_equal "p3", outcome.pane
        end

        def test_dispatch_with_no_prompt_skips_prompt_submission
          outcome = @dispatcher.dispatch(
            label: "a1", prompt: "", workspace_id: "ws-1", pane: "p3"
          )

          refute outcome.prompted
          assert_empty @executor.calls_of(:agent_prompt)
        end

        def test_dispatch_without_resolvable_workspace_fails
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_current: Molecules::ExecutionResult.new(
              stdout: "", stderr: "", success: true, exit_code: 0
            )
          })
          dispatcher = build_dispatcher

          with_env("HERDR_WORKSPACE_ID" => nil) do
            error = assert_raises(TargetResolutionError) do
              dispatcher.dispatch(label: "a1", prompt: "x")
            end

            assert_match(/workspace/, error.message)
          end
        end

        def test_dispatch_tab_output_without_pane_id_fails_with_guidance
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            tab_create: Molecules::ExecutionResult.new(
              stdout: JSON.generate({id: "tab-9"}), stderr: "", success: true, exit_code: 0
            )
          })
          dispatcher = build_dispatcher

          error = assert_raises(TargetResolutionError) do
            dispatcher.dispatch(label: "a1", prompt: "x", workspace_id: "ws-1")
          end

          assert_match(/--pane/, error.message)
        end

        private

        def build_dispatcher
          Dispatcher.new(
            executor: @executor, default_agent_kind: "pi",
            agent_start_timeout_ms: 60_000
          )
        end

        def tab_result(tab_id, pane_id)
          Molecules::ExecutionResult.new(
            stdout: JSON.generate({id: tab_id, pane_id: pane_id}),
            stderr: "", success: true, exit_code: 0
          )
        end
      end
    end
  end
end
