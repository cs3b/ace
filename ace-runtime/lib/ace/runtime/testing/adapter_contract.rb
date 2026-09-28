# frozen_string_literal: true

module Ace
  module Runtime
    module Testing
      # THE acceptance bar for any ace-runtime adapter (shared-examples
      # pattern). Include AdapterContract in a Minitest::Test class and
      # provide two hooks:
      #
      #   def build_fixture          = Testing::ScriptedRuntime.new
      #   def build_adapter(fixture) = adapter wired to the fixture
      #
      # Then also include exactly one send matrix module matching the
      # profile the adapter declares via #send_profile:
      # AdapterContract::PlainPaneSendMatrix or
      # AdapterContract::AgentAwareSendMatrix.
      #
      # The adapter must implement the full published intent API over
      # the fixture's native ops and translate fixture signals at its
      # boundary (FixtureUnavailable -> RuntimeUnavailableError,
      # FixtureStall -> SendStalledError, FixtureTargetMissing ->
      # TargetNotFoundError).
      module AdapterContract
        WAIT_TIMEOUT = 0.05

        def setup
          super
          @contract_fixture = build_fixture
          @contract_adapter = build_adapter(@contract_fixture)
          @contract_pane = nil
          @contract_setup_op_count = nil
        end

        attr_reader :contract_fixture, :contract_adapter

        def fixture
          @contract_fixture
        end

        def adapter
          @contract_adapter
        end

        # --- identity and context ---

        def test_context_reports_scripted_environment
          fixture.set_context(in_runtime: true, session: "main", window: "work", pane: "%1")

          context = adapter.context

          assert_equal true, context[:in_runtime]
          assert_equal "main", context[:session]
          assert_equal "work", context[:window]
          assert_equal "%1", context[:pane]
        end

        def test_context_reports_absence_outside_runtime
          fixture.set_context(in_runtime: false, session: nil, window: nil, pane: nil)

          context = adapter.context

          refute context[:in_runtime]
          assert_nil context[:session]
          assert_nil context[:window]
          assert_nil context[:pane]
        end

        # --- ensure_window ---

        def test_ensure_window_creates_window_with_sanitized_name
          handle = adapter.ensure_window(name: "my work!", root: "/tmp/work")

          assert_instance_of String, handle
          refute handle.strip.empty?, "window handle must be opaque but present"
          create = fixture.calls.find { |call| call[:op] == :create_window }
          assert create, "expected a create_window transport call"
          assert_equal "my-work", create[:name]
          assert_equal "/tmp/work", create[:root]
        end

        def test_ensure_window_is_idempotent_by_name
          first = adapter.ensure_window(name: "work", root: "/tmp/work")
          second = adapter.ensure_window(name: "work", root: "/tmp/work")

          assert_equal first, second
          assert_equal 1, fixture.calls.count { |call| call[:op] == :create_window }
        end

        def test_ensure_window_conflicting_root_raises_window_conflict
          adapter.ensure_window(name: "work", root: "/tmp/work")

          error = assert_raises(WindowConflictError) do
            adapter.ensure_window(name: "work", root: "/other/root")
          end

          assert_match(/root|preset/i, error.message)
        end

        def test_ensure_window_conflicting_preset_raises_window_conflict
          adapter.ensure_window(name: "work", root: "/tmp/work", preset: "main")

          error = assert_raises(WindowConflictError) do
            adapter.ensure_window(name: "work", root: "/tmp/work", preset: "other")
          end

          assert_match(/preset/i, error.message)
        end

        # --- prepare_pane ---

        def test_prepare_pane_splits_and_retains_a_writable_pane
          adapter.ensure_window(name: "work", root: "/tmp/work")

          pane = adapter.prepare_pane(window: "work")

          assert_instance_of String, pane
          refute pane.strip.empty?, "pane handle must be opaque but present"
          assert fixture.calls.any? { |call| call[:op] == :split_window }, "expected a split"
          assert_includes fixture.calls, {op: :set_keep_alive, pane: pane, value: true}
        end

        def test_prepare_pane_reuses_retained_pane_without_splitting
          adapter.ensure_window(name: "work", root: "/tmp/work")
          first = adapter.prepare_pane(window: "work")
          fixture.calls.clear

          second = adapter.prepare_pane(window: "work")

          assert_equal first, second
          assert_empty fixture.calls.select { |call| call[:op] == :split_window }
        end

        def test_prepare_pane_splits_when_only_a_bare_pane_exists
          fixture.seed_window("work", root: "/tmp/work")
          fixture.seed_pane("work", keep_alive: false)
          bare_pane = fixture.panes.keys.first

          pane = adapter.prepare_pane(window: "work")

          assert fixture.calls.any? { |call| call[:op] == :split_window }, "bare pane must not satisfy preparation"
          refute_equal bare_pane, pane
        end

        def test_prepared_pane_stays_targetable_after_command_exit
          adapter.ensure_window(name: "work", root: "/tmp/work")
          pane = adapter.prepare_pane(window: "work")
          fixture.set_output(pane, "command ran\n")
          fixture.exit_pane(pane)

          assert adapter.wait_lifecycle(condition: "pane-exists", target: pane, timeout: WAIT_TIMEOUT)
          assert_equal "command ran\n", adapter.capture(pane: pane, lines: 10)
        end

        # --- focus / close / listing ---

        def test_focus_selects_window
          adapter.ensure_window(name: "work", root: "/tmp/work")

          adapter.focus(window: "work")

          assert fixture.calls.any? { |call| call[:op] == :focus_window && call[:name] == "work" }
          entries = adapter.list_windows
          assert entries.find { |entry| entry[:name] == "work" }[:active]
        end

        def test_close_window_removes_window
          adapter.ensure_window(name: "work", root: "/tmp/work")

          adapter.close_window(window: "work")

          refute adapter.list_windows.any? { |entry| entry[:name] == "work" }
        end

        def test_list_windows_reports_scripted_windows
          fixture.seed_window("alpha", root: "/tmp/a")
          fixture.seed_window("beta", root: "/tmp/b")

          names = adapter.list_windows.map { |entry| entry[:name] }

          assert_equal %w[alpha beta], names.sort
        end

        def test_list_panes_reports_opaque_handles
          fixture.seed_window("work", root: "/tmp/work")
          fixture.seed_pane("work")
          fixture.seed_pane("work")

          entries = adapter.list_panes(window: "work")

          assert_equal 2, entries.length
          entries.each do |entry|
            assert_instance_of String, entry[:pane]
            refute entry[:pane].strip.empty?
          end
        end

        # --- capture ---

        def test_capture_returns_scripted_output
          pane = prepare_target!
          fixture.set_output(pane, "line one\nline two\n")

          assert_equal "line one\nline two\n", adapter.capture(pane: pane, lines: 40)
        end

        def test_capture_is_bounded_by_lines
          pane = prepare_target!
          fixture.set_output(pane, "l1\nl2\nl3\n")

          assert_equal "l2\nl3\n", adapter.capture(pane: pane, lines: 2)
        end

        def test_capture_missing_pane_raises_target_not_found
          prepare_target!

          assert_raises(TargetNotFoundError) do
            adapter.capture(pane: "%999", lines: 10)
          end
        end

        # --- waits ---

        def test_wait_output_returns_when_pattern_present
          pane = prepare_target!
          fixture.set_output(pane, "build finished\n")

          assert adapter.wait_output(pane: pane, pattern: "build finished", timeout: WAIT_TIMEOUT)
        end

        def test_wait_output_times_out_with_seconds_context
          pane = prepare_target!

          error = assert_raises(WaitTimeoutError) do
            adapter.wait_output(pane: pane, pattern: "never appears", timeout: WAIT_TIMEOUT)
          end

          assert_equal WAIT_TIMEOUT, error.timeout
          assert_match(/output/, error.message)
        end

        def test_wait_agent_returns_when_state_matches
          pane = prepare_target!
          fixture.set_agent_state(pane, "working")

          assert adapter.wait_agent(pane: pane, states: ["idle", "working"], timeout: WAIT_TIMEOUT)
        end

        def test_wait_agent_times_out_when_state_never_matches
          pane = prepare_target!
          fixture.set_agent_state(pane, "working")

          error = assert_raises(WaitTimeoutError) do
            adapter.wait_agent(pane: pane, states: ["idle"], timeout: WAIT_TIMEOUT)
          end

          assert_equal WAIT_TIMEOUT, error.timeout
        end

        def test_wait_lifecycle_rejects_conditions_outside_the_observation_set
          pane = prepare_target!

          error = assert_raises(ArgumentError) do
            adapter.wait_lifecycle(condition: "subtree-complete", target: pane, timeout: WAIT_TIMEOUT)
          end

          assert_match(/window-exists|lifecycle/, error.message)
        end

        def test_lifecycle_window_conditions
          adapter.ensure_window(name: "work", root: "/tmp/work")

          assert adapter.wait_lifecycle(condition: "window-exists", target: "work", timeout: WAIT_TIMEOUT)

          adapter.focus(window: "work")

          assert adapter.wait_lifecycle(condition: "window-active", target: "work", timeout: WAIT_TIMEOUT)
        end

        def test_lifecycle_pane_conditions
          pane = prepare_target!

          assert adapter.wait_lifecycle(condition: "pane-exists", target: pane, timeout: WAIT_TIMEOUT)

          fixture.exit_pane(pane)

          assert adapter.wait_lifecycle(condition: "pane-exited", target: pane, timeout: WAIT_TIMEOUT)
        end

        def test_lifecycle_condition_times_out_when_unmet
          pane = prepare_target!

          error = assert_raises(WaitTimeoutError) do
            adapter.wait_lifecycle(condition: "pane-exited", target: pane, timeout: WAIT_TIMEOUT)
          end

          assert_equal WAIT_TIMEOUT, error.timeout
        end

        # pane-exited is an observation only: the contract never treats
        # it as assignment success, receipt confirmation, or prune
        # authorization. That boundary is enforced above the contract;
        # the suite asserts the observation itself.
        def test_pane_exited_is_observation_only
          fixture.seed_window("work", root: "/tmp/work")
          pane = fixture.seed_pane("work")
          fixture.exit_pane(pane)

          assert adapter.wait_lifecycle(condition: "pane-exited", target: pane, timeout: WAIT_TIMEOUT)
        end

        # --- error model ---

        # Targeted operations must translate native "missing target"
        # failures into the typed contract error; a leaked fixture or
        # native error class fails the acceptance bar.
        def test_missing_targets_raise_target_not_found_on_targeted_operations
          prepare_target!

          assert_raises(TargetNotFoundError) { adapter.focus(window: "no-such-window") }
          assert_raises(TargetNotFoundError) { adapter.close_window(window: "no-such-window") }
          assert_raises(TargetNotFoundError) { adapter.prepare_pane(window: "no-such-window") }
          assert_raises(TargetNotFoundError) { adapter.send(pane: "%999", command: "run", items: []) }
          assert_raises(TargetNotFoundError) { adapter.send_text(pane: "%999", text: "hi") }
          assert_raises(TargetNotFoundError) { adapter.send_keys(pane: "%999", keys: ["C-c"]) }
          assert_raises(TargetNotFoundError) { adapter.capture(pane: "%999", lines: 10) }
          assert_raises(TargetNotFoundError) { adapter.wait_output(pane: "%999", pattern: "x", timeout: WAIT_TIMEOUT) }
          assert_raises(TargetNotFoundError) { adapter.wait_agent(pane: "%999", states: ["idle"], timeout: WAIT_TIMEOUT) }
        end

        # Listing an absent window is an empty set (poll-friendly), but
        # every transport operation must fail typed when the runtime is
        # unreachable — never silently succeed or leak a native error.
        def test_unavailable_runtime_raises_runtime_unavailable_on_transport_operations
          prepare_target!
          fixture.unavailable = true

          assert_raises(RuntimeUnavailableError) { adapter.ensure_window(name: "other", root: "/tmp/other") }
          assert_raises(RuntimeUnavailableError) { adapter.prepare_pane(window: "work") }
          assert_raises(RuntimeUnavailableError) { adapter.focus(window: "work") }
          assert_raises(RuntimeUnavailableError) { adapter.send(pane: @contract_pane, command: "run", items: []) }
          assert_raises(RuntimeUnavailableError) { adapter.send_command(pane: @contract_pane, command: "run") }
          assert_raises(RuntimeUnavailableError) { adapter.capture(pane: @contract_pane, lines: 10) }
          assert_raises(RuntimeUnavailableError) { adapter.wait_output(pane: @contract_pane, pattern: "x", timeout: WAIT_TIMEOUT) }
          assert_raises(RuntimeUnavailableError) { adapter.wait_agent(pane: @contract_pane, states: ["idle"], timeout: WAIT_TIMEOUT) }
          assert_raises(RuntimeUnavailableError) { adapter.wait_lifecycle(condition: "window-exists", target: "work", timeout: WAIT_TIMEOUT) }
          assert_raises(RuntimeUnavailableError) { adapter.close_window(window: "work") }
          assert_raises(RuntimeUnavailableError) { adapter.list_windows }
          assert_raises(RuntimeUnavailableError) { adapter.list_panes(window: "work") }
        end

        def test_stalled_send_raises_send_stalled_error_and_is_never_auto_resent
          pane = prepare_target!

          fixture.stall_next_send!

          assert_raises(SendStalledError) do
            adapter.send(pane: pane, command: "run", items: [])
          end
          assert_empty transport_calls, "a stalled submission must not have delivered anything"

          # The contract never auto-resends; an explicit caller retry is
          # a new submission and may deliver.
          adapter.send(pane: pane, command: "run", items: [])
          expected_delivery = adapter.send_profile == :plain_pane ? 2 : 1
          assert_equal expected_delivery, transport_calls.length
        end

        def test_send_to_missing_pane_raises_target_not_found
          prepare_target!

          assert_raises(TargetNotFoundError) do
            adapter.send(pane: "%999", command: "run", items: [])
          end
        end

        # --- send matrix (common, both profiles) ---

        def test_empty_send_is_rejected_before_transport
          with_target do
            assert_rejected_before_transport(command: nil, items: [])
          end
        end

        def test_invalid_item_shape_is_rejected_before_transport
          with_target do
            assert_rejected_before_transport(command: nil, items: [{blob: "x"}])
          end
        end

        def test_command_with_message_item_is_rejected_before_transport
          with_target do
            assert_rejected_before_transport(command: "run", items: [{message: "hi"}])
          end
        end

        def test_send_result_reports_when_no_enter_was_dropped
          pane = prepare_target!

          result = adapter.send(pane: pane, command: "run", items: [])

          refute result.dropped_trailing_enter
        end

        # --- shared helpers ---

        private

        # Transport ops recorded after target preparation — the calls
        # the code under test actually made.
        def transport_calls
          fixture.calls.drop(@contract_setup_op_count || 0)
        end

        # Prepares a retained target and returns its opaque pane handle.
        def prepare_target!(name: "work", root: "/tmp/ace-runtime-contract")
          adapter.ensure_window(name: name, root: root)
          pane = adapter.prepare_pane(window: name)
          fixture.set_output(pane, "ready\n")
          @contract_setup_op_count = fixture.calls.length
          @contract_pane = pane
        end

        def with_target
          prepare_target! unless @contract_pane
          yield
        end

        def assert_rejected_before_transport(command:, items:)
          error = assert_raises(SendRejectedError) do
            adapter.send(pane: @contract_pane, command: command, items: items)
          end

          assert_empty transport_calls, "rejected send must not reach transport"
          error
        end
      end

      module AdapterContract
        # Normative matrix for adapters whose send_profile is
        # :plain_pane: messages are raw text (no implicit submission),
        # keys are keystrokes, each Enter submits pending text, and
        # command submits once before its trailing keys.
        module PlainPaneSendMatrix
          def test_ordered_items_deliver_distinctly
            prepare_target!

            adapter.send(
              pane: @contract_pane,
              command: nil,
              items: [{message: "one"}, {key: "Enter"}, {message: "two"}]
            )

            assert_equal [
              {op: :write_text, pane: @contract_pane, text: "one"},
              {op: :press_key, pane: @contract_pane, key: "Enter"},
              {op: :write_text, pane: @contract_pane, text: "two"}
            ], transport_calls
          end

          def test_messages_with_single_trailing_enter_submit_exactly_once
            prepare_target!

            result = adapter.send(
              pane: @contract_pane,
              command: nil,
              items: [{message: "hello"}, {key: "Enter"}]
            )

            assert_equal [
              {op: :write_text, pane: @contract_pane, text: "hello"},
              {op: :press_key, pane: @contract_pane, key: "Enter"}
            ], transport_calls
            refute result.dropped_trailing_enter
          end

          def test_command_submits_once_then_delivers_trailing_keys
            prepare_target!

            adapter.send(pane: @contract_pane, command: "run", items: [{key: "C-c"}])

            assert_equal [
              {op: :write_text, pane: @contract_pane, text: "run"},
              {op: :press_key, pane: @contract_pane, key: "Enter"},
              {op: :press_key, pane: @contract_pane, key: "C-c"}
            ], transport_calls
          end

          def test_convenience_shapes_delegate_to_send
            prepare_target!

            adapter.send_command(pane: @contract_pane, command: "run")
            adapter.send_text(pane: @contract_pane, text: "hi")
            adapter.send_keys(pane: @contract_pane, keys: %w[C-c C-r])

            assert_equal [
              {op: :write_text, pane: @contract_pane, text: "run"},
              {op: :press_key, pane: @contract_pane, key: "Enter"},
              {op: :write_text, pane: @contract_pane, text: "hi"},
              {op: :press_key, pane: @contract_pane, key: "C-c"},
              {op: :press_key, pane: @contract_pane, key: "C-r"}
            ], transport_calls
          end
        end

        # Normative matrix for adapters whose send_profile is
        # :agent_aware: command or the concatenated messages become ONE
        # self-submitting prompt, at most one trailing Enter is dropped
        # and reported, keys-only sequences go to the agent, and every
        # other interleaving is rejected before any transport call.
        module AgentAwareSendMatrix
          def test_messages_deliver_as_one_prompt_without_enter
            prepare_target!

            result = adapter.send(
              pane: @contract_pane,
              command: nil,
              items: [{message: "line one"}, {message: "line two"}]
            )

            assert_equal [{op: :write_text, pane: @contract_pane, text: "line one\nline two"}], transport_calls
            refute result.dropped_trailing_enter
          end

          def test_single_trailing_enter_after_messages_is_dropped_and_reported
            prepare_target!

            result = adapter.send(
              pane: @contract_pane,
              command: nil,
              items: [{message: "hello"}, {key: "Enter"}]
            )

            assert_equal [{op: :write_text, pane: @contract_pane, text: "hello"}], transport_calls
            assert result.dropped_trailing_enter
          end

          def test_command_with_single_trailing_enter_is_dropped_and_reported
            prepare_target!

            result = adapter.send(pane: @contract_pane, command: "run", items: [{key: "Enter"}])

            assert_equal [{op: :write_text, pane: @contract_pane, text: "run"}], transport_calls
            assert result.dropped_trailing_enter
          end

          def test_keys_only_sequences_go_to_agent_keys
            prepare_target!

            result = adapter.send(
              pane: @contract_pane,
              command: nil,
              items: [{key: "C-c"}, {key: "C-r"}]
            )

            assert_equal [
              {op: :press_key, pane: @contract_pane, key: "C-c"},
              {op: :press_key, pane: @contract_pane, key: "C-r"}
            ], transport_calls
            refute result.dropped_trailing_enter
          end

          def test_send_text_delivers_single_prompt
            prepare_target!

            adapter.send_text(pane: @contract_pane, text: "hello")

            assert_equal [{op: :write_text, pane: @contract_pane, text: "hello"}], transport_calls
          end

          def test_keys_between_messages_rejected_before_transport
            prepare_target!

            assert_rejected_before_transport(
              command: nil,
              items: [{message: "a"}, {key: "C-c"}, {message: "b"}]
            )
          end

          def test_multiple_enters_rejected_before_transport
            prepare_target!

            assert_rejected_before_transport(
              command: nil,
              items: [{message: "a"}, {key: "Enter"}, {key: "Enter"}]
            )
          end

          def test_command_with_non_enter_key_rejected_before_transport
            prepare_target!

            assert_rejected_before_transport(command: "run", items: [{key: "C-c"}])
          end
        end
      end
    end
  end
end
