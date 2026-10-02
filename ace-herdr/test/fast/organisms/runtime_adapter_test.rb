# frozen_string_literal: true

require "test_helper"
require "ace/runtime/adapters/herdr"

module Ace
  module Herdr
    module Organisms
      class RuntimeAdapterTest < Minitest::Test
        def setup
          @identity_dir = Dir.mktmpdir("herdr-runtime-tabs")
          @tabs = []
          @panes = []
          @agent = false
          @processes = ["busy"]
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_current: result(result: {pane_id: "w1:p0", tab_id: "w1:t0", workspace_id: "w1"}),
            tab_list: ->(_args) { result(result: {tabs: @tabs}) },
            pane_list: ->(_args) { result(result: {panes: @panes}) },
            tab_create: ->(args) {
              id = "w1:t#{@tabs.length + 1}"
              @tabs << {"tab_id" => id, "label" => args[:label], "workspace_id" => "w1", "focused" => false}
              @panes << {"pane_id" => "w1:p0", "tab_id" => id, "workspace_id" => "w1", "cwd" => args[:cwd]}
              result(result: {tab_id: id, root_pane_id: "w1:p0"})
            },
            pane_split: ->(_args) {
              id = "w1:p#{@panes.length}"
              @panes << {"pane_id" => id, "tab_id" => @tabs.last["tab_id"], "workspace_id" => "w1"}
              result(result: {pane_id: id})
            },
            pane_get: ->(args) {
              row = @panes.find { |pane| pane["pane_id"] == args[:pane] }
              row ||= {"pane_id" => "w1:p0", "tab_id" => "w1:t0", "workspace_id" => "w1"} if args[:pane] == "w1:p0"
              raise PaneNotFoundError, "pane_not_found" unless row
              result(result: {pane: row})
            },
            pane_process_info: ->(_args) { result(result: {process_info: {shell_pid: 42, foreground_processes: @processes}}) },
            tab_get: ->(args) {
              raise TabNotFoundError, "tab_not_found" unless @tabs.any? { |row| row["tab_id"] == args[:tab] }
              result(result: {tab_id: args[:tab]})
            },
            tab_focus: ->(args) {
              @tabs.each { |row| row["focused"] = row["tab_id"] == args[:tab] }
              result(result: {tab_id: args[:tab]})
            },
            tab_close: ->(args) {
              @tabs.reject! { |row| row["tab_id"] == args[:tab_id] }
              result(result: {tab_id: args[:tab_id]})
            },
            agent_get: ->(args) {
              raise PaneNotFoundError, "pane_not_found" unless @panes.any? { |row| row["pane_id"] == args[:pane] }
              raise AgentNotFoundError, "agent_not_found" unless @agent
              result(result: {state: "idle"})
            },
            pane_read: result("line one\nline two\n")
          })
          @adapter = RuntimeAdapter.new(
            executor: @executor, env: {"HERDR_SESSION" => "s1", "HERDR_PANE" => "w1:p0"},
            sleeper: FastSleeper.new, identity_dir: @identity_dir
          )
        end

        def teardown
          FileUtils.remove_entry(@identity_dir)
        end

        def result(value = nil, **payload)
          stdout = value || JSON.generate(payload)
          Molecules::ExecutionResult.new(stdout: stdout, stderr: "", success: true, exit_code: 0)
        end

        class FastSleeper
          def sleep(_seconds); end
        end

        def test_registration_and_context_map_workspace_tab_and_pane
          assert_instance_of RuntimeAdapter, Runtime.resolve("herdr")
          assert_equal({in_runtime: true, session: "w1", window: "w1:t0", pane: "w1:p0"}, @adapter.context)
          outside = RuntimeAdapter.new(executor: @executor, env: {})
          assert_equal({in_runtime: false, session: nil, window: nil, pane: nil}, outside.context)
          assert_raises(Runtime::RuntimeUnavailableError) { outside.list_windows }
        end

        def test_ensure_prepare_focus_list_and_close
          tab = @adapter.ensure_window(name: "my work!", root: "/tmp/work")
          assert_equal "w1:t1", tab
          assert_equal tab, @adapter.ensure_window(name: "my work!", root: "/tmp/work")
          assert_equal 1, @executor.calls_of(:tab_create).size
          assert_raises(Runtime::WindowConflictError) do
            @adapter.ensure_window(name: "my work!", root: "/other")
          end

          pane = @adapter.prepare_pane(window: tab)
          assert_equal "w1:p1", pane
          assert_equal pane, @adapter.prepare_pane(window: tab)
          assert_equal 1, @executor.calls_of(:pane_split).size
          @adapter.focus(window: tab)
          assert @adapter.list_windows.first[:active]
          assert_equal %w[w1:p0 w1:p1], @adapter.list_panes(window: tab).map { |row| row[:pane] }
          @adapter.close_window(window: tab)
          assert_empty @adapter.list_windows
        end

        def test_ensure_reuses_across_adapter_instances_and_rejects_unknown_preset_identity
          tab = @adapter.ensure_window(name: "work", root: "/tmp/work")
          another = RuntimeAdapter.new(executor: @executor, env: env, identity_dir: @identity_dir)
          assert_equal tab, another.ensure_window(name: "work", root: "/tmp/work")
          assert_equal 1, @executor.calls_of(:tab_create).size
          assert_raises(Runtime::WindowConflictError) do
            another.ensure_window(name: "work", root: "/tmp/work", preset: "main")
          end
        end

        def test_plain_send_keeps_order_and_agent_send_submits_once
          pane = prepared_pane
          @adapter.send(pane: pane, items: [{message: "one"}, {key: "Enter"}, {message: "two"}])
          assert_equal %i[pane_send_text pane_send_keys pane_send_text],
            @executor.calls.select { |call| %i[pane_send_text pane_send_keys].include?(call[:operation]) }
              .map { |call| call[:operation] }

          @agent = true
          result = @adapter.send(pane: pane, items: [{message: "hello"}, {key: "Enter"}])
          assert result.dropped_trailing_enter
          assert_equal 1, @executor.calls_of(:agent_prompt).size
          assert_equal "hello", @executor.calls_of(:agent_prompt).last[:args][:text]
          assert_raises(Runtime::SendRejectedError) do
            @adapter.send(pane: pane, items: [{message: "a"}, {key: "C-c"}, {message: "b"}])
          end
          assert_equal 1, @executor.calls_of(:agent_prompt).size
        end

        def test_agent_blocked_and_stalled_are_distinct_and_never_resent
          pane = prepared_pane
          @agent = true
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            agent_get: result(result: {state: "blocked"}),
            agent_prompt: AgentBlockedError.new("agent_blocked")
          })
          adapter = RuntimeAdapter.new(executor: @executor, env: env, identity_dir: @identity_dir)
          assert_raises(Runtime::SendRejectedError) { adapter.send_command(pane: pane, command: "hello") }
          assert_equal 1, @executor.calls_of(:agent_prompt).size

          stalled = HerdrTestHelper::FakeExecutor.new(outcomes: {
            agent_get: result(result: {state: "idle"}),
            agent_prompt: AgentNotReadyError.new("agent_prompt_stalled")
          })
          adapter = RuntimeAdapter.new(executor: stalled, env: env, identity_dir: @identity_dir)
          assert_raises(Runtime::SendStalledError) { adapter.send_command(pane: pane, command: "hello") }
          assert_equal 1, stalled.calls_of(:agent_prompt).size

          timed_out = HerdrTestHelper::FakeExecutor.new(outcomes: {
            agent_get: result(result: {state: "idle"}),
            agent_prompt: ExecutorTimeoutError.new("timeout")
          })
          adapter = RuntimeAdapter.new(executor: timed_out, env: env, identity_dir: @identity_dir)
          assert_raises(Runtime::WaitTimeoutError) { adapter.send_command(pane: pane, command: "hello") }
          assert_equal 1, timed_out.calls_of(:agent_prompt).size
        end

        def test_capture_and_native_agent_wait_convert_timeout_units
          pane = prepared_pane
          assert_equal "line one\nline two\n", @adapter.capture(pane: pane, lines: 2)
          assert @adapter.wait_agent(pane: pane, states: %w[idle done], timeout: 0.05)
          assert_equal 50, @executor.calls_of(:agent_wait).last[:args][:timeout_ms]
          assert @adapter.wait_output(pane: pane, pattern: "line", timeout: 0.05)
          assert_equal 50, @executor.calls_of(:pane_wait_output).last[:args][:timeout_ms]
        end

        def test_lifecycle_waits_are_condition_specific
          tab = @adapter.ensure_window(name: "work", root: "/tmp/work")
          pane = @adapter.prepare_pane(window: tab)
          assert @adapter.wait_lifecycle(condition: "window-exists", target: tab, timeout: 0.05)
          @adapter.focus(window: tab)
          assert @adapter.wait_lifecycle(condition: "window-active", target: tab, timeout: 0.05)
          assert @adapter.wait_lifecycle(condition: "pane-exists", target: pane, timeout: 0.05)
          assert_raises(Runtime::WaitTimeoutError) do
            @adapter.wait_lifecycle(condition: "pane-exited", target: pane, timeout: 0.01)
          end
          @processes = []
          assert @adapter.wait_lifecycle(condition: "pane-exited", target: pane, timeout: 0.05)
          assert @adapter.wait_lifecycle(condition: "pane-exited", target: "missing", timeout: 0.05)
          assert_raises(Runtime::WaitTimeoutError) do
            @adapter.wait_lifecycle(condition: "pane-exists", target: "missing", timeout: 0.01)
          end
        end

        def test_pane_exists_polls_until_created_and_pane_exited_requires_process_evidence
          calls = 0
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_get: ->(_args) {
              calls += 1
              raise PaneNotFoundError, "pane_not_found" if calls == 1
              result(result: {pane_id: "opaque-pane"})
            },
            pane_process_info: result(result: {process_info: {shell_pid: 42,
              foreground_processes: [{"pid" => 42}]}})
          })
          adapter = RuntimeAdapter.new(executor: @executor, env: env, sleeper: FastSleeper.new,
            identity_dir: @identity_dir)
          assert adapter.wait_lifecycle(condition: "pane-exists", target: "opaque-pane", timeout: 0.05)
          assert_equal 2, calls
          assert adapter.wait_lifecycle(condition: "pane-exited", target: "opaque-pane", timeout: 0.05)
        end

        def test_omitted_foreground_processes_proves_exit_but_empty_info_stays_inconclusive
          prepared_pane
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_get: result(result: {pane_id: "w1:p1"}),
            # herdr omits foreground_processes via skip_serializing_if when
            # the list is empty (PaneTidyProbe process-evidence semantics)
            pane_process_info: result(result: {process_info: {shell_pid: 42}})
          })
          adapter = RuntimeAdapter.new(executor: @executor, env: env, sleeper: FastSleeper.new,
            identity_dir: @identity_dir)
          assert adapter.wait_lifecycle(condition: "pane-exited", target: "w1:p1", timeout: 0.05)

          # A bare hash without shell pid proves nothing
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_get: result(result: {pane_id: "w1:p1"}),
            pane_process_info: result(result: {process_info: {}})
          })
          adapter = RuntimeAdapter.new(executor: @executor, env: env, sleeper: FastSleeper.new,
            identity_dir: @identity_dir)
          assert_raises(Runtime::WaitTimeoutError) do
            adapter.wait_lifecycle(condition: "pane-exited", target: "w1:p1", timeout: 0.01)
          end

          # An explicit null list is malformed evidence, not exit proof
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_get: result(result: {pane_id: "w1:p1"}),
            pane_process_info: result(result: {process_info: {shell_pid: 42, foreground_processes: nil}})
          })
          adapter = RuntimeAdapter.new(executor: @executor, env: env, sleeper: FastSleeper.new,
            identity_dir: @identity_dir)
          assert_raises(Runtime::WaitTimeoutError) do
            adapter.wait_lifecycle(condition: "pane-exited", target: "w1:p1", timeout: 0.01)
          end
        end

        def test_malformed_process_info_does_not_prove_exit
          prepared_pane
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_get: result(result: {pane_id: "w1:p1"}),
            pane_process_info: result(result: {other: {shell_pid: 42, foreground_processes: []}})
          })
          adapter = RuntimeAdapter.new(executor: @executor, env: env, sleeper: FastSleeper.new,
            identity_dir: @identity_dir)
          assert_raises(Runtime::WaitTimeoutError) do
            adapter.wait_lifecycle(condition: "pane-exited", target: "w1:p1", timeout: 0.01)
          end
        end

        def test_identity_records_are_stable_across_working_directories
          root = Dir.mktmpdir("herdr-adapter-root")
          dir_a = Dir.mktmpdir("herdr-cwd-a")
          dir_b = Dir.mktmpdir("herdr-cwd-b")
          tab = nil
          Dir.chdir(dir_a) do
            adapter = RuntimeAdapter.new(executor: @executor, env: env, sleeper: FastSleeper.new,
              identity_dir: @identity_dir)
            tab = adapter.ensure_window(name: "work", root: root)
          end
          Dir.chdir(dir_b) do
            adapter = RuntimeAdapter.new(executor: @executor, env: env, sleeper: FastSleeper.new,
              identity_dir: @identity_dir)
            assert_equal tab, adapter.ensure_window(name: "work", root: root)
            assert_equal 1, @executor.calls_of(:tab_create).size
          end
        ensure
          [root, dir_a, dir_b].each { |dir| FileUtils.remove_entry(dir) if dir && File.exist?(dir) }
        end

        def test_context_rejects_workspace_hint_conflicting_with_caller_pane
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_get: result(result: {pane: {"pane_id" => "w1:p0", "workspace_id" => "w1"}})
          })
          adapter = RuntimeAdapter.new(executor: @executor,
            env: {"HERDR_SESSION" => "s1", "HERDR_PANE" => "w1:p0", "HERDR_WORKSPACE_ID" => "w9"},
            identity_dir: @identity_dir)
          error = assert_raises(Runtime::RuntimeUnavailableError) { adapter.context }
          assert_match(/HERDR_WORKSPACE_ID/, error.message)

          matched = RuntimeAdapter.new(executor: @executor,
            env: {"HERDR_SESSION" => "s1", "HERDR_PANE" => "w1:p0", "HERDR_WORKSPACE_ID" => "w1"},
            identity_dir: @identity_dir)
          assert_equal "w1", matched.context[:session]
        end

        def test_same_label_in_other_root_conflicts_instead_of_duplicating
          @adapter.ensure_window(name: "work", root: "/tmp/work")
          other = RuntimeAdapter.new(executor: @executor, env: env, sleeper: FastSleeper.new,
            identity_dir: @identity_dir)
          assert_raises(Runtime::WindowConflictError) do
            other.ensure_window(name: "work", root: "/other")
          end
          assert_equal 1, @executor.calls_of(:tab_create).size
        end

        def test_interrupted_non_preset_create_leftover_is_adopted_by_matching_root
          @executor.tab_create(workspace_id: "w1", label: "work", cwd: "/tmp/work")
          tab = @adapter.ensure_window(name: "work", root: "/tmp/work")
          assert_equal "w1:t1", tab
          assert_equal 1, @executor.calls_of(:tab_create).size
          assert_equal 0, @executor.calls_of(:tab_close).size
        end

        def test_interrupted_preset_create_leftover_conflicts_and_is_never_closed
          @executor.tab_create(workspace_id: "w1", label: "work", cwd: "/tmp/work")
          assert_raises(Runtime::WindowConflictError) do
            @adapter.ensure_window(name: "work", root: "/tmp/work", preset: "agent")
          end
          assert_equal 1, @executor.calls_of(:tab_create).size
          assert_equal 0, @executor.calls_of(:tab_close).size
        end

        def test_manual_same_label_tab_is_never_closed_by_preset_request
          # A manually created tab (no adapter record) must survive any
          # adapter request — closing an unowned tab destroys running work.
          @executor.tab_create(workspace_id: "w1", label: "work", cwd: "/tmp/work")
          manual_tab = @adapter.list_windows.find { |row| row[:name] == "work" }[:window]
          assert_raises(Runtime::WindowConflictError) do
            @adapter.ensure_window(name: "work", root: "/tmp/work", preset: "agent")
          end
          assert @adapter.list_windows.any? { |row| row[:window] == manual_tab }
          assert_equal 0, @executor.calls_of(:tab_close).size
        end

        def test_rollback_only_closes_tabs_created_by_the_current_attempt
          @executor.tab_create(workspace_id: "w1", label: "other", cwd: "/tmp/work")
          manual_tabs_before = @adapter.list_windows.map { |row| row[:window] }
          failing_surface = Class.new do
            def initialize(executor)
              @real = ControlSurface.new(executor: executor)
              @executor = executor
            end

            def create_tab(*)
              @executor.tab_create(workspace_id: "w1", label: "work", cwd: "/tmp/work")
              raise StandardError, "preset materialization failed after native create"
            end

            def method_missing(name, *args, **kwargs, &block)
              return @real.public_send(name, *args, **kwargs, &block) if @real.respond_to?(name)

              super
            end

            def respond_to_missing?(name, include_private = false)
              @real.respond_to?(name, include_private) || super
            end
          end.new(@executor)
          failing = RuntimeAdapter.new(executor: @executor, env: env, sleeper: FastSleeper.new,
            surface: failing_surface, identity_dir: @identity_dir)
          error = assert_raises(StandardError) do
            failing.ensure_window(name: "work", root: "/tmp/work", preset: "main")
          end
          assert_match(/materialization failed/, error.message)
          assert_equal 1, @executor.calls_of(:tab_close).size
          remaining = @adapter.list_windows.map { |row| row[:window] }
          assert_equal manual_tabs_before.sort, (remaining & manual_tabs_before).sort
          assert_empty @adapter.list_windows.select { |row| row[:name] == "work" }
        end

        def test_adopted_tab_identity_is_recorded_for_later_instances
          @executor.tab_create(workspace_id: "w1", label: "work", cwd: "/tmp/work")
          tab = @adapter.ensure_window(name: "work", root: "/tmp/work")
          assert_equal "w1:t1", tab

          first = RuntimeAdapter.new(executor: @executor, env: env, sleeper: FastSleeper.new,
            identity_dir: @identity_dir)
          pane = first.prepare_pane(window: tab)
          third = RuntimeAdapter.new(executor: @executor, env: env, sleeper: FastSleeper.new,
            identity_dir: @identity_dir)
          assert_equal pane, third.prepare_pane(window: tab)
          assert_equal 1, @executor.calls_of(:pane_split).size
        end

        def test_identity_write_failure_rolls_back_the_created_tab
          failing = Class.new(RuntimeAdapter) do
            def write_identity(*)
              raise StandardError, "identity write failed"
            end
          end
          adapter = failing.new(executor: @executor, env: env, sleeper: FastSleeper.new,
            identity_dir: @identity_dir)
          error = assert_raises(StandardError) do
            adapter.ensure_window(name: "work", root: "/tmp/work")
          end
          assert_match(/identity write failed/, error.message)
          assert_equal 1, @executor.calls_of(:tab_close).size
          assert_empty adapter.list_windows
        end

        def test_prepared_pane_creation_is_serialized_across_instances
          tab = @adapter.ensure_window(name: "work", root: "/tmp/work")
          split_started = Queue.new
          release_split = Queue.new
          executor = Object.new
          real = @executor
          executor.define_singleton_method(:method_missing) do |name, *args, **kwargs, &block|
            if name == :pane_split
              split_started << true
              release_split.pop
            end
            real.public_send(name, *args, **kwargs)
          end
          executor.define_singleton_method(:respond_to_missing?) { |_name, *_| true }
          holder = RuntimeAdapter.new(executor: executor, env: env, sleeper: FastSleeper.new,
            identity_dir: @identity_dir)
          waiter = RuntimeAdapter.new(executor: real, env: env, sleeper: FastSleeper.new,
            identity_dir: @identity_dir)
          holder_thread = Thread.new { holder.prepare_pane(window: tab) }
          split_started.pop
          waiter_thread = Thread.new { waiter.prepare_pane(window: tab) }
          sleep 0.1
          release_split << true
          assert_equal holder_thread.value, waiter_thread.value
          assert_equal 1, real.calls_of(:pane_split).size
        ensure
          release_split << true if release_split && !holder_thread&.status.nil? && holder_thread.alive?
        end

        def test_unknown_preset_surfaces_as_contract_error
          error = assert_raises(Runtime::Error) do
            @adapter.ensure_window(name: "work", root: "/tmp/work", preset: "no-such-preset")
          end
          refute error.is_a?(Herdr::ValidationError)
          assert_match(/no-such-preset/, error.message)
        end

        def test_failed_preset_materialization_rolls_back_the_native_tab
          failing_surface = Class.new do
            def initialize(executor)
              @real = ControlSurface.new(executor: executor)
              @executor = executor
            end

            def create_tab(*)
              @executor.tab_create(workspace_id: "w1", label: "work", cwd: "/tmp/work")
              raise StandardError, "preset materialization failed after native create"
            end

            def method_missing(name, *args, **kwargs, &block)
              return @real.public_send(name, *args, **kwargs, &block) if @real.respond_to?(name)

              super
            end

            def respond_to_missing?(name, include_private = false)
              @real.respond_to?(name, include_private) || super
            end
          end.new(@executor)
          failing = RuntimeAdapter.new(executor: @executor, env: env, sleeper: FastSleeper.new,
            surface: failing_surface, identity_dir: @identity_dir)
          error = assert_raises(StandardError) do
            failing.ensure_window(name: "work", root: "/tmp/work", preset: "main")
          end
          assert_match(/materialization failed/, error.message)
          assert_equal 1, @executor.calls_of(:tab_close).size
          assert_empty @adapter.list_windows
        end

        def test_prepared_pane_is_reused_across_adapter_instances
          tab = @adapter.ensure_window(name: "work", root: "/tmp/work")
          first = @adapter.prepare_pane(window: tab)
          second = RuntimeAdapter.new(executor: @executor, env: env, sleeper: FastSleeper.new,
            identity_dir: @identity_dir)
          assert_equal first, second.prepare_pane(window: tab)
          assert_equal 1, @executor.calls_of(:pane_split).size
        end

        def test_missing_target_and_unavailable_errors
          assert_raises(Runtime::TargetNotFoundError) { @adapter.send_command(pane: "missing", command: "x") }
          assert_raises(Runtime::TargetNotFoundError) { @adapter.focus(window: "missing") }
          unavailable = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_get: ExecutorUnavailableError.new("socket unavailable")
          })
          adapter = RuntimeAdapter.new(executor: unavailable, env: env, identity_dir: @identity_dir)
          assert_raises(Runtime::RuntimeUnavailableError) { adapter.list_windows }
        end

        private

        def env
          {"HERDR_SESSION" => "s1", "HERDR_PANE" => "w1:p0"}
        end

        def prepared_pane
          tab = @adapter.ensure_window(name: "work", root: "/tmp/work")
          @adapter.prepare_pane(window: tab)
        end
      end
    end
  end
end
