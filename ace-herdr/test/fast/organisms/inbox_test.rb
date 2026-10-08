# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "json"

module Ace
  module Herdr
    module Organisms
      class InboxTest < Minitest::Test
        THREAD = "0123abcd-0000-4000-8000-000000000001"

        class FakeExecutor
          attr_accessor :pane, :prompt_error, :pane_get_error
          attr_reader :prompts, :observations

          def initialize
            @pane = {"pane_id" => "p1", "workspace_id" => "ws1", "terminal_id" => "term-1",
              "agent" => "pi", "agent_status" => "busy",
              "agent_session" => {"agent" => "pi", "kind" => "id", "value" => THREAD}}
            @prompts = []
            @observations = []
          end

          def pane_get_bounded(_id)
            @observations << _id
            raise pane_get_error if pane_get_error

            Molecules::ExecutionResult.new(stdout: JSON.generate("result" => {"pane" => pane}),
              stderr: "", success: true, exit_code: 0)
          end

          def agent_prompt(pane:, text:)
            raise prompt_error if prompt_error

            @prompts << [pane, text]
          end

          def agent_prompt_bounded(pane:, text:, timeout_ms:)
            agent_prompt(pane: pane, text: text)
            Molecules::ExecutionResult.new(stdout: "sent", stderr: "", success: true, exit_code: 0)
          end
        end

        class FakeNative
          attr_accessor :result, :session
          attr_reader :calls

          def initialize
            @result = {"accepted" => true, "stdout" => "{}"}
            @session = THREAD
            @calls = []
          end

          def pi_identity
            session
          end

          # This state-machine fixture injects the native boundary; real correlation is tested in the service composition.
          def prepare_submission(**_arguments) = nil

          def submit(**args)
            @calls << args
            result
          end

        end

        def setup
          @dir = Dir.mktmpdir
          @executor = FakeExecutor.new
          @native = FakeNative.new
          @inbox = Inbox.new(executor: @executor, native: @native, deliveries_dir: @dir)
          @event = "inb-aaaaaaaaaaaaaaaaaaaaaaaa"
          @ref = {"session" => "ws1", "pane" => "p1"}
        end

        def teardown
          FileUtils.remove_entry(@dir)
        end

        def enqueue(payload = "hello")
          @inbox.enqueue(event: @event, attempt: "att-1", ref: @ref, payload: payload)
        end

        def test_shared_typed_pair_accepts_native_ids_without_adopting_authority
          address = @inbox.send(:address_for, {"session" => "$0", "pane" => "%0"})
          assert_equal ["$0", "%0"], [address.session, address.pane]
          assert_raises(Ace::Hitl::Providers::InvalidRefError) do
            @inbox.enqueue(event: @event, attempt: "att-1", ref: {"session" => "$0", "pane" => "p1"}, payload: "hello")
          end
          assert_empty @native.calls
          refute File.exist?(File.join(@dir, "#{@event}.json"))
        end

        def test_malformed_persisted_pair_refuses_before_claim_or_native_submission
          enqueue
          record = Molecules::DeliveryRecordStore.load(@dir, @event)
          [["$0", "p1"], [" ws1 ", "p1"]].each do |session, pane|
            malformed = Models::DeliveryRecord.from_h(record.to_h.merge("session" => session, "pane" => pane))
            Molecules::DeliveryRecordStore.save(malformed, @dir)
            assert_raises(Ace::Hitl::Providers::InvalidRefError) { @inbox.deliver(event: @event) }
            assert_equal "queued", Molecules::DeliveryRecordStore.load(@dir, @event).state
            assert_empty @native.calls
          end
        end

        def test_serialized_ref_refuses_padded_components_before_native_observation
          [[" ws1 ", "p1"], ["ws1", " p1 "], [" $0 ", "%0"], ["$0", " %0 "]].each_with_index do |(session, pane), index|
            path = File.join(@dir, "ref-#{index}.json")
            File.write(path, JSON.generate("session" => session, "pane" => pane))
            assert_raises(Ace::Hitl::Providers::InvalidRefError) do
              @inbox.enqueue(event: @event, attempt: "att-1", ref: path, payload: "hello")
            end
            assert_empty @executor.observations
            assert_empty @native.calls
            refute File.exist?(File.join(@dir, "#{@event}.json"))
          end
        end

        def test_direct_ref_normalizes_while_canonical_serialized_ref_preserves_pair
          direct = @inbox.send(:address_for, {"session" => " ws1 ", "pane" => " p1 "})
          assert_equal ["ws1", "p1"], [direct.session, direct.pane]
          path = File.join(@dir, "native-ref.json")
          File.write(path, JSON.generate("session" => "$0", "pane" => "%0"))
          serialized = @inbox.send(:address_for, path)
          assert_equal ["$0", "%0"], [serialized.session, serialized.pane]
        end





        def original_target
          {"session" => @executor.pane["workspace_id"], "pane" => @executor.pane["pane_id"],
            "terminal_id" => @executor.pane["terminal_id"], "agent" => @executor.pane["agent"],
            "thread" => @executor.pane.dig("agent_session", "value"), "thread_kind" => "id"}
        end

        def managed_example
          path = Gem::Specification.find_by_name("ace-hitl-contract").full_gem_path
          JSON.parse(File.read(File.join(path, "lib/ace/hitl/contract/examples/managed-answer.json")))
        end

        def test_managed_shared_example_crosses_inbox_without_changing_scope
          value = managed_example
          @ref = value.fetch("reverse")
          @executor.pane["workspace_id"] = @ref["session"]
          @executor.pane["pane_id"] = @ref["pane"]
          @event = Ace::Hitl::Contract::ManagedEnvelope.inbox_event_id(value)
          record = @inbox.enqueue(event: @event, attempt: value.fetch("attempt_id"), ref: @ref,
            payload: value.dig("message", "answer"), managed_envelope: value,
            expected_target: original_target)
          assert_equal value, record["managed_envelope"]
          assert_equal record, @inbox.enqueue(event: @event, attempt: value.fetch("attempt_id"), ref: @ref,
            payload: value.dig("message", "answer"), managed_envelope: value,
            expected_target: original_target)
          changed = Marshal.load(Marshal.dump(value))
          changed["requester"] = "other-owner"
          assert_raises(ValidationError) do
            @inbox.enqueue(event: @event, attempt: value.fetch("attempt_id"), ref: @ref,
              payload: value.dig("message", "answer"), managed_envelope: changed)
          end
        end

        def test_managed_inbox_refuses_wrong_version_attempt_digest_correlation_and_secret
          value = managed_example
          [->(v) { v["schema"] = "ace.hitl.managed/v99" },
           ->(v) { v["attempt_id"] = "other685" },
           ->(v) { v["payload_sha256"] = "f" * 64 },
           ->(v) { v["message"]["id"] = "other-request" },
           ->(v) { v["message"]["answer"] = "otp=123456" }].each do |change|
            candidate = Marshal.load(Marshal.dump(value))
            change.call(candidate)
            assert_raises(ValidationError) do
              @inbox.enqueue(event: @event, attempt: value.fetch("attempt_id"), ref: value.fetch("reverse"),
                payload: value.dig("message", "answer"), managed_envelope: candidate)
            end
          end
          assert_empty Dir.children(@dir)
        end

        def test_codex_submits_exact_prompt_once_to_the_live_terminal
          @executor.pane["agent"] = "codex"
          @executor.pane["agent_session"]["agent"] = "codex"
          enqueue
          results = 2.times.map { Thread.new { @inbox.deliver(event: @event) } }.map(&:value)
          assert_equal ["delivered", "delivered"], results.map { |row| row.fetch("state") }
          assert_equal [["p1", "hello"]], @executor.prompts
          assert_empty @native.calls
          assert_equal "none", results.first.dig("wake", "status")
          assert_equal "delivered", @inbox.status(event: @event).fetch("state")
        end

        def test_codex_lost_terminal_reply_remains_unknown_without_resend
          @executor.pane["agent"] = "codex"
          @executor.pane["agent_session"]["agent"] = "codex"
          @executor.prompt_error = AgentNotReadyError.new("reply lost")
          enqueue
          assert_equal "uncertain", @inbox.deliver(event: @event).fetch("state")
          @executor.prompt_error = nil
          restarted = Inbox.new(executor: @executor, native: @native, deliveries_dir: @dir)
          assert_equal "uncertain", restarted.deliver(event: @event).fetch("state")
          assert_empty @executor.prompts
          assert_empty @native.calls
        end

        def test_missing_event_is_distinct_from_corrupt_retained_state
          assert_raises(Inbox::MissingEventError) { @inbox.status(event: @event) }
          assert_raises(Inbox::MissingEventError) { @inbox.retained_status(event: @event) }
          enqueue
          File.write(File.join(@dir, "#{@event}.json"), "not-json")
          error = assert_raises(JSON::ParserError) { @inbox.status(event: @event) }
          refute_kind_of Inbox::MissingEventError, error
        end

        def test_idempotent_enqueue_and_digest_conflict
          first = enqueue
          assert_equal "queued", first["state"]
          assert_equal first, enqueue
          assert_raises(ValidationError) { enqueue("different") }
          assert_raises(ValidationError) do
            @inbox.enqueue(event: @event, attempt: "att-2", ref: @ref, payload: "hello")
          end
        end

        def test_bounded_retained_inventory_refuses_busy_event_and_unwinds_inventory
          enqueue
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
          path = Molecules::DeliveryRecordStore.lock_path(@dir, @event)
          File.open(path, File::RDWR | File::CREAT, 0o600) do |held|
            held.flock(File::LOCK_EX)
            assert_raises(Molecules::DeliveryRecordStore::LockUnavailable) do
              Inbox.with_retained_records(deliveries_dir: @dir, deadline: deadline) { flunk "busy event entered" }
            end
          end
          Inbox.with_retained_records(deliveries_dir: @dir, deadline: deadline) do |records|
            assert_equal [@event], records.map(&:event_id)
          end
          assert_empty Thread.current[:ace_herdr_delivery_inventory_locks]
          assert_empty Thread.current[:ace_herdr_retained_inventory_locks]
        end

        def test_empty_retained_inventory_holds_coordination_without_creating_missing_context
          Inbox.with_retained_records(deliveries_dir: @dir) do |records|
            assert_empty records
            assert_empty Inbox.retained_records(deliveries_dir: @dir)
          end
          assert_equal [".inventory.lock"], Dir.children(@dir)
          missing = File.join(@dir, "missing")
          assert_raises(ValidationError) { Inbox.with_retained_records(deliveries_dir: missing) {} }
          refute File.exist?(missing)
        end

        def test_exhaustive_retention_refuses_symlink_and_conflicting_archive_copy
          enqueue
          archive = Molecules::DeliveryRecordStore.archive_dir(@dir)
          FileUtils.mkdir_p(archive)
          live = Molecules::DeliveryRecordStore.path_for(@dir, @event)
          archived = Molecules::DeliveryRecordStore.path_for(archive, @event)
          File.symlink(live, archived)
          assert_raises(ValidationError) { Inbox.retained_records(deliveries_dir: @dir) }
          File.unlink(archived)
          value = JSON.parse(File.read(live))
          value["state"] = "completed"
          File.write(archived, JSON.generate(value))
          assert_raises(ValidationError) { Inbox.retained_records(deliveries_dir: @dir) }
        end

        def test_expected_original_target_refuses_initial_drift_and_duplicate_conflicts
          origin = original_target
          @executor.pane["agent_session"]["value"] = "9999abcd-0000-4000-8000-000000000009"
          assert_raises(Inbox::IdentityDriftError) do
            @inbox.enqueue(event: @event, attempt: "att-1", ref: @ref, payload: "hello", expected_target: origin)
          end
          assert_nil Molecules::DeliveryRecordStore.load(@dir, @event)
          assert_empty @native.calls
          @executor.pane["agent_session"]["value"] = THREAD
          accepted = @inbox.enqueue(event: @event, attempt: "att-1", ref: @ref, payload: "hello", expected_target: origin)
          assert_equal origin, accepted["origin_target"]
          %w[terminal_id thread agent].each do |key|
            changed = origin.merge(key => key == "agent" ? "codex" : "9999abcd-0000-4000-8000-000000000009")
            assert_raises(Inbox::IdentityDriftError) do
              @inbox.enqueue(event: @event, attempt: "att-1", ref: @ref, payload: "hello", expected_target: changed)
            end
          end
          assert_equal accepted, @inbox.status(event: @event)
          assert_empty @native.calls
        end

        def test_drift_after_locked_observation_keeps_origin_and_refuses_submission
          origin = original_target
          original_save = @inbox.method(:save)
          pane = @executor.pane
          @inbox.define_singleton_method(:save) do |record|
            pane["agent_session"]["value"] = "9999abcd-0000-4000-8000-000000000009"
            original_save.call(record)
          end
          @inbox.enqueue(event: @event, attempt: "att-1", ref: @ref, payload: "hello", expected_target: origin)
          result = @inbox.deliver(event: @event)
          assert_equal "uncertain", result["state"]
          assert_equal origin, result["origin_target"]
          assert_equal THREAD, result.dig("binding", "thread")
          assert_empty @native.calls
        end

        def test_managed_target_and_secret_checks_cannot_be_bypassed_by_missing_message
          value = managed_example
          value.delete("message")
          @ref = value.fetch("reverse")
          @executor.pane["workspace_id"] = @ref["session"]
          @executor.pane["pane_id"] = @ref["pane"]
          @event = Ace::Hitl::Contract::ManagedEnvelope.inbox_event_id(value)
          payload = "ordinary answer"
          value["payload_sha256"] = Digest::SHA256.hexdigest(payload)
          [nil, false, {}, original_target.reject { |key, _| key == "thread" }].each do |target|
            assert_raises(ValidationError) do
              @inbox.enqueue(event: @event, attempt: value["attempt_id"], ref: @ref,
                payload: payload, managed_envelope: value, expected_target: target)
            end
          end
          payload = "otp=123456"
          value["payload_sha256"] = Digest::SHA256.hexdigest(payload)
          assert_raises(ValidationError) do
            @inbox.enqueue(event: @event, attempt: value["attempt_id"], ref: @ref,
              payload: payload, managed_envelope: value, expected_target: original_target)
          end
          assert_empty Dir.children(@dir)
          assert_empty @native.calls
        end

        def test_unknown_agent_status_is_a_retryable_pre_submission_rejection
          enqueue
          @executor.pane["agent_status"] = "unknown"

          result = @inbox.deliver(event: @event)

          assert_equal "queued", result["state"]
          assert_match(/unrecognized/, result["last_error"])
          assert_empty @native.calls
          @executor.pane["agent_status"] = "busy"
          assert_equal "delivered", @inbox.deliver(event: @event)["state"]
          assert_equal 1, @native.calls.length
        end

        def test_oversize_payload_is_rejected_at_enqueue_for_the_target_agent
          @executor.pane["agent"] = "pi"
          @executor.pane["agent_session"] = {"agent" => "pi", "kind" => "id", "value" => THREAD}
          @event = "inb-bbbbbbbbbbbbbbbbbbbbbbbb"

          error = assert_raises(ValidationError) do
            @inbox.enqueue(event: @event, attempt: "att-1", ref: @ref, payload: "x" * 65_537)
          end

          assert_match(/never be delivered/, error.message)
          assert_nil Molecules::DeliveryRecordStore.load(@dir, @event)
          @executor.pane["agent"] = "codex"
          @executor.pane["agent_session"] = {"agent" => "codex", "kind" => "id", "value" => THREAD}
          error = assert_raises(ValidationError) do
            @inbox.enqueue(event: @event, attempt: "att-1", ref: @ref, payload: "x" * 65_537)
          end
          assert_match(/never be delivered/, error.message)
        end

        def test_short_pi_event_id_is_rejected_by_the_shared_validator
          @executor.pane["agent"] = "pi"
          @executor.pane["agent_session"] = {"agent" => "pi", "kind" => "id", "value" => THREAD}

          error = assert_raises(ValidationError) do
            @inbox.enqueue(event: "inb-1", attempt: "att-1", ref: @ref, payload: "hello")
          end

          assert_match(/8 id characters/, error.message)
          assert_nil Molecules::DeliveryRecordStore.load(@dir, "inb-1")
        end

        def test_probe_launch_failure_keeps_event_retryable
          enqueue
          @executor.pane_get_error = ExecutorUnavailableError.new("herdr not executable")

          result = @inbox.deliver(event: @event)

          assert_equal "queued", result["state"]
          assert_equal "queued", Molecules::DeliveryRecordStore.load(@dir, @event).state
          assert_empty @native.calls
        end

        def test_non_object_ref_file_is_a_validation_error
          ref_path = File.join(@dir, "ref.json")
          File.write(ref_path, JSON.generate(["ws1", "p1"]))

          error = assert_raises(ValidationError) do
            @inbox.enqueue(event: @event, attempt: "att-1", ref: ref_path, payload: "hello")
          end

          assert_match(/expected a JSON object/, error.message)
        end

        def test_stalled_pane_probe_times_out_as_retryable_pre_submission
          Dir.mktmpdir do |dir|
            script = File.join(dir, "stalled-herdr")
            File.write(script, "#!/bin/sh\necho $$ > '#{dir}/child.pid'\nexec sleep 30\n")
            File.chmod(0o755, script)
            executor = Molecules::HerdrExecutor.new(binary: script)

            error = assert_raises(AgentNotReadyError) do
              executor.pane_get_bounded("p1", timeout_s: 1.0)
            end

            assert_match(/timed out/, error.message)
            assert_predicate error, :retryable?
            child_pid = File.read(File.join(dir, "child.pid")).to_i
            assert_raises(Errno::ESRCH) { Process.kill(0, child_pid) }
          end
        end

        def test_busy_target_wake_decision_survives_a_crash_before_wake_save
          enqueue
          @inbox.deliver(event: @event)
          Molecules::DeliveryRecordStore.with_lock(@dir, @event) do
            record = Molecules::DeliveryRecordStore.load(@dir, @event)
            inbox = record.inbox.merge("wake" => nil).compact
            Molecules::DeliveryRecordStore.save(record.advance_inbox(
              state: "delivered", inbox: inbox, detail: {"action" => "accepted"},
              timestamp: "2026-10-02T00:00:00Z"), @dir)
          end

          result = @inbox.deliver(event: @event)

          assert_equal "delivered", result["state"]
          assert_equal "none", result.dig("wake", "status")
          assert_empty @executor.prompts
          assert_equal 1, @native.calls.length
        end

        def test_invalid_utf8_payload_is_a_validation_error
          error = assert_raises(ValidationError) do
            @inbox.enqueue(event: @event, attempt: "att-1", ref: @ref,
              payload: "bad \xFF byte".b)
          end

          assert_match(/not valid UTF-8/, error.message)
          assert_nil Molecules::DeliveryRecordStore.load(@dir, @event)
        end

        def test_malformed_probe_json_keeps_event_retryable
          enqueue
          @executor.pane = ["not", "an", "object"]

          result = @inbox.deliver(event: @event)

          assert_equal "queued", result["state"]
          assert_match(/unavailable|unrecognized/, result["last_error"])
          assert_empty @native.calls
          record = Molecules::DeliveryRecordStore.load(@dir, @event)
          assert_equal "queued", record.state
        end

        def test_codex_name_kind_thread_is_rejected_for_binding
          @executor.pane["agent"] = "codex"
          @executor.pane["agent_session"]["agent"] = "codex"
          enqueue
          @executor.pane["agent_session"] = {"agent" => "codex", "kind" => "name", "value" => "agent-main"}

          result = @inbox.deliver(event: @event)

          assert_equal "queued", result["state"]
          assert_match(/immutable session id/, result["last_error"])
          assert_empty @native.calls
        end



        def test_agent_change_classifies_as_drift_not_validation_error
          event = "inb-generic0000000000000002"
          @event = event
          enqueue
          @native.result = {"accepted" => false, "pre_submit" => true, "error" => "missing executable"}
          assert_equal "queued", @inbox.deliver(event: event)["state"]
          @executor.pane["agent"] = "codex"
          @executor.pane["agent_session"] = {"agent" => "codex", "kind" => "id", "value" => THREAD}

          result = @inbox.deliver(event: event)

          assert_equal "uncertain", result["state"]
          assert_match(/target identity changed/, result["last_error"])
          assert_equal 1, @native.calls.length
        end

        def test_unsupported_agent_change_classifies_as_drift
          enqueue
          @native.result = {"accepted" => false, "pre_submit" => true, "error" => "missing executable"}
          assert_equal "queued", @inbox.deliver(event: @event)["state"]
          @executor.pane["agent"] = "claude"

          result = @inbox.deliver(event: @event)

          assert_equal "uncertain", result["state"]
          assert_match(/target identity changed/, result["last_error"])
          assert_equal 1, @native.calls.length
        end

        def test_busy_agent_receives_one_native_queue_submission_even_with_concurrent_callers
          enqueue
          results = 2.times.map { Thread.new { @inbox.deliver(event: @event) } }.map(&:value)

          assert_equal ["delivered", "delivered"], results.map { |r| r["state"] }
          assert_equal 1, @native.calls.length
          assert_equal THREAD, @native.calls.first[:thread]
          assert_empty @executor.prompts
        end



        def test_idle_wake_failure_preserves_accepted_native_delivery
          @executor.pane["agent"] = "pi"
          @executor.pane["agent_session"]["agent"] = "pi"
          @executor.pane["agent_status"] = "idle"
          @executor.prompt_error = RuntimeError.new("wake process crashed")
          enqueue

          result = @inbox.deliver(event: @event)

          assert_equal "delivered", result["state"]
          assert_equal "pending", result.dig("wake", "status")
          assert_match(/wake process crashed/, result.dig("wake", "error"))
          assert_equal 1, @native.calls.length
          restarted = Inbox.new(executor: @executor, native: @native, deliveries_dir: @dir)
          assert_equal "delivered", restarted.status(event: @event)["state"]
          @executor.prompt_error = nil

          retried = restarted.deliver(event: @event)

          assert_equal "delivered", retried["state"]
          assert_equal "sent", retried.dig("wake", "status")
          assert_equal [["p1", "Check your native queued messages."]], @executor.prompts
          assert_equal 1, @native.calls.length
        end



        def test_wake_retry_with_identity_drift_requires_reconciliation
          @executor.pane["agent"] = "pi"
          @executor.pane["agent_session"]["agent"] = "pi"
          @executor.pane["agent_status"] = "idle"
          @executor.prompt_error = RuntimeError.new("wake process crashed")
          enqueue
          @inbox.deliver(event: @event)
          @executor.prompt_error = nil
          @executor.pane["workspace_id"] = "other"

          result = @inbox.deliver(event: @event)

          assert_equal "uncertain", result["state"]
          assert_match(/runtime session identity changed/, result["last_error"])
          assert_equal 1, @native.calls.length
        end

        def test_busy_target_records_no_wake_debt
          enqueue
          result = @inbox.deliver(event: @event)

          assert_equal "delivered", result["state"]
          assert_equal "none", result.dig("wake", "status")
          assert_empty @executor.prompts
        end

        def test_pi_target_rejects_non_inbox_event_ids_at_enqueue
          @executor.pane["agent"] = "pi"
          @executor.pane["agent_session"] = {"agent" => "pi", "kind" => "id", "value" => THREAD}

          error = assert_raises(ValidationError) do
            @inbox.enqueue(event: "evt-1", attempt: "att-1", ref: @ref, payload: "hello")
          end

          assert_match(/inb-.*wnk-/, error.message)
          assert_nil Molecules::DeliveryRecordStore.load(@dir, "evt-1")
        end

        def test_spoofed_or_reused_pane_identity_never_submits
          enqueue
          @executor.pane["terminal_id"] = ""
          result = @inbox.deliver(event: @event)
          assert_equal "queued", result["state"]
          assert_match(/terminal/, result["last_error"])
          assert_empty @native.calls
          @executor.pane["terminal_id"] = "term-2"
          assert_equal "uncertain", @inbox.deliver(event: @event)["state"]
          @executor.pane["workspace_id"] = "other"
          assert_equal "uncertain", @inbox.deliver(event: @event)["state"]
          assert_empty @native.calls
        end

        def test_native_thread_drift_requires_reconciliation_before_delivery
          enqueue
          @executor.pane["agent_session"]["value"] = "9999abcd-0000-4000-8000-000000000009"

          result = @inbox.deliver(event: @event)

          assert_equal "uncertain", result["state"]
          assert_match(/identity (changed|differs)/, result["last_error"])
          assert_empty @native.calls
          assert_equal "uncertain", @inbox.deliver(event: @event)["state"]
        end

        def test_workspace_drift_requires_reconciliation_before_delivery
          enqueue
          @executor.pane["workspace_id"] = "other"

          result = @inbox.deliver(event: @event)

          assert_equal "uncertain", result["state"]
          assert_match(/runtime session identity changed/, result["last_error"])
          assert_empty @native.calls
        end

        def test_orphan_claim_without_intent_requeues_and_with_intent_stays_uncertain
          enqueue
          Molecules::DeliveryRecordStore.with_lock(@dir, @event) do
            record = Molecules::DeliveryRecordStore.load(@dir, @event)
            Molecules::DeliveryRecordStore.save(record.advance_inbox(state: "claimed",
              inbox: record.inbox.merge("claim_owner" => "dead"), detail: {"action" => "claim"},
              timestamp: "2026-10-01T00:00:00Z"), @dir)
          end
          # Claim saved before any submission intent: provably pre-send.
          assert_equal "queued", @inbox.deliver(event: @event)["state"]
          @native.result = {"accepted" => true, "stdout" => "queued"}
          assert_equal "delivered", @inbox.deliver(event: @event)["state"]

          @event = "inb-bbbbbbbbbbbbbbbbbbbbbbbb"
          enqueue
          Molecules::DeliveryRecordStore.with_lock(@dir, @event) do
            record = Molecules::DeliveryRecordStore.load(@dir, @event)
            Molecules::DeliveryRecordStore.save(record.advance_inbox(state: "claimed",
              inbox: record.inbox.merge("claim_owner" => "dead", "submission_intent" => true),
              detail: {"action" => "submit-intent"},
              timestamp: "2026-10-01T00:00:00Z"), @dir)
          end
          # Claim saved after submission intent: the boundary is unknown.
          assert_equal "uncertain", @inbox.deliver(event: @event)["state"]

          @event = "inb-cccccccccccccccccccccccc"
          enqueue
          @native.result = {"accepted" => false, "error" => "agent_prompt_stalled"}
          assert_equal "uncertain", @inbox.deliver(event: @event)["state"]
          restarted = Inbox.new(executor: @executor, native: @native, deliveries_dir: @dir)
          assert_equal "uncertain", restarted.deliver(event: @event)["state"]
          assert_equal 2, @native.calls.length
        end

        def test_pre_submission_missing_executable_can_retry
          enqueue
          @native.result = {"accepted" => false, "pre_submit" => true, "error" => "missing executable"}
          assert_equal "queued", @inbox.deliver(event: @event)["state"]
          @native.result = {"accepted" => true, "stdout" => "ok"}
          assert_equal "delivered", @inbox.deliver(event: @event)["state"]
          assert_equal 2, @native.calls.length
        end

        def test_idle_native_presend_rejection_can_retry
          @executor.pane["agent_status"] = "idle"
          enqueue
          @native.result = {"accepted" => false, "pre_submit" => true, "error" => "missing executable"}
          assert_equal "queued", @inbox.deliver(event: @event)["state"]
          @native.result = {"accepted" => true, "stdout" => "queued"}
          assert_equal "delivered", @inbox.deliver(event: @event)["state"]
          assert_equal 2, @native.calls.length
          assert_equal [["p1", "Check your native queued messages."]], @executor.prompts
        end

        def test_pi_uses_live_session_identity_and_digest_bound_queue
          @executor.pane["agent"] = "pi"
          @executor.pane["agent_session"]["agent"] = "pi"
          enqueue
          @native.session = "different"
          assert_equal "uncertain", @inbox.deliver(event: @event)["state"]
          assert_empty @native.calls
          @native.session = THREAD
          assert_equal "uncertain", @inbox.deliver(event: @event)["state"]
          @event = "inb-cccccccccccccccccccccccc"
          enqueue
          assert_equal "delivered", @inbox.deliver(event: @event)["state"]
          assert_equal "pi", @native.calls.first[:agent]
          assert_equal Digest::SHA256.hexdigest("hello"), @native.calls.first[:digest]
        end

        def test_idle_pi_uses_exact_session_queue_after_restart
          @executor.pane["agent"] = "pi"
          @executor.pane["agent_session"]["agent"] = "pi"
          @executor.pane["agent_status"] = "idle"
          enqueue

          restarted = Inbox.new(executor: @executor, native: @native, deliveries_dir: @dir)
          assert_equal "delivered", restarted.deliver(event: @event)["state"]
          assert_equal "delivered", @inbox.deliver(event: @event)["state"]
          assert_equal [["p1", "Check your native queued messages."]], @executor.prompts
          assert_equal 1, @native.calls.length
          assert_equal THREAD, @native.calls.first[:thread]
        end












      end
    end
  end
end
