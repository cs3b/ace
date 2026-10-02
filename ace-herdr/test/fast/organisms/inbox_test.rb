# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "json"
require "openssl"

module Ace
  module Herdr
    module Organisms
      class InboxTest < Minitest::Test
        THREAD = "0123abcd-0000-4000-8000-000000000001"
        RECEIPT_KEY = OpenSSL::PKey::RSA.generate(2048)

        class FakeExecutor
          attr_accessor :pane, :prompt_error
          attr_reader :prompts

          def initialize
            @pane = {"pane_id" => "p1", "workspace_id" => "ws1", "terminal_id" => "term-1",
              "agent" => "codex", "agent_status" => "busy",
              "agent_session" => {"agent" => "codex", "kind" => "id", "value" => THREAD}}
            @prompts = []
          end

          def pane_get(_id)
            Molecules::ExecutionResult.new(stdout: JSON.generate("result" => {"pane" => pane}),
              stderr: "", success: true, exit_code: 0)
          end

          def agent_prompt(pane:, text:)
            raise prompt_error if prompt_error

            @prompts << [pane, text]
          end

          def agent_prompt_bounded(pane:, text:, timeout_ms:)
            agent_prompt(pane: pane, text: text)
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

          def submit(**args)
            @calls << args
            result
          end

        end

        def setup
          @dir = Dir.mktmpdir
          @executor = FakeExecutor.new
          @native = FakeNative.new
          @inbox = Inbox.new(executor: @executor, native: @native, deliveries_dir: @dir,
            receipt_public_key: RECEIPT_KEY.public_key)
          @event = "inb-aaaaaaaaaaaaaaaaaaaaaaaa"
          @ref = {"session" => "ws1", "pane" => "p1"}
        end

        def teardown
          FileUtils.remove_entry(@dir)
        end

        def enqueue(payload = "hello")
          @inbox.enqueue(event: @event, attempt: "att-1", ref: @ref, payload: payload)
        end

        def proof(record, outcome: "consumed")
          {"event_id" => @event, "attempt_id" => "att-1",
           "claim_generation" => record["claim_generation"],
           "payload_sha256" => record["payload_sha256"], "binding" => record["binding"],
           "outcome" => outcome, "observer" => {"role" => "supervisor", "id" => "ops-1"},
           "evidence" => {"kind" => outcome == "consumed" ? "consumed_acknowledged" : "queue_evicted",
                          "native_reference" => "session-log:42",
                          "observation" => "message consumed and acknowledged"}}
        end

        def reconcile(receipt, signature: nil)
          bytes = JSON.generate(receipt)
          signature ||= RECEIPT_KEY.sign(OpenSSL::Digest::SHA256.new, bytes)
          @inbox.reconcile(event: @event, receipt: receipt, signed_bytes: bytes, signature: signature)
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

        def test_busy_agent_receives_one_native_queue_submission_even_with_concurrent_callers
          enqueue
          results = 2.times.map { Thread.new { @inbox.deliver(event: @event) } }.map(&:value)

          assert_equal ["delivered", "delivered"], results.map { |r| r["state"] }
          assert_equal 1, @native.calls.length
          assert_equal THREAD, @native.calls.first[:thread]
          assert_empty @executor.prompts
        end

        def test_idle_agent_uses_exact_session_native_queue
          @executor.pane["agent_status"] = "idle"
          enqueue
          assert_equal "delivered", @inbox.deliver(event: @event)["state"]
          assert_equal [["p1", "Check your native queued messages."]], @executor.prompts
          assert_equal 1, @native.calls.length
          assert_equal THREAD, @native.calls.first[:thread]
        end

        def test_idle_wake_failure_preserves_accepted_native_delivery
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

        def test_crash_before_wake_is_recovered_without_resubmission
          @executor.pane["agent_status"] = "idle"
          enqueue
          @inbox.deliver(event: @event)
          Molecules::DeliveryRecordStore.with_lock(@dir, @event) do
            record = Molecules::DeliveryRecordStore.load(@dir, @event)
            # Simulate a crash between the delivered save and the wake entry.
            inbox = record.inbox.reject { |key, _| key == "wake" }
            Molecules::DeliveryRecordStore.save(record.advance_inbox(
              state: "delivered", inbox: inbox, detail: {"action" => "accepted"},
              timestamp: "2026-10-02T00:00:00Z"), @dir)
          end
          @executor.prompts.clear

          result = @inbox.deliver(event: @event)

          assert_equal "delivered", result["state"]
          assert_equal "sent", result.dig("wake", "status")
          assert_equal [["p1", "Check your native queued messages."]], @executor.prompts
          assert_equal 1, @native.calls.length
        end

        def test_wake_retry_with_identity_drift_requires_reconciliation
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
          assert_match(/identity changed/, result["last_error"])
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

        def test_orphan_claim_and_native_failure_stay_uncertain_after_restart
          enqueue
          Molecules::DeliveryRecordStore.with_lock(@dir, @event) do
            record = Molecules::DeliveryRecordStore.load(@dir, @event)
            Molecules::DeliveryRecordStore.save(record.advance_inbox(state: "claimed",
              inbox: record.inbox.merge("claim_owner" => "dead"), detail: {"action" => "claim"},
              timestamp: "2026-10-01T00:00:00Z"), @dir)
          end
          assert_equal "uncertain", @inbox.deliver(event: @event)["state"]
          assert_empty @native.calls

          @event = "inb-bbbbbbbbbbbbbbbbbbbbbbbb"
          enqueue
          @native.result = {"accepted" => false, "error" => "agent_prompt_stalled"}
          assert_equal "uncertain", @inbox.deliver(event: @event)["state"]
          restarted = Inbox.new(executor: @executor, native: @native, deliveries_dir: @dir)
          assert_equal "uncertain", restarted.deliver(event: @event)["state"]
          assert_equal 1, @native.calls.length
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

        def test_delivered_event_reconciles_to_completed_on_consumption_proof
          enqueue
          delivered = @inbox.deliver(event: @event)
          assert_equal "delivered", delivered["state"]
          assert_equal 1, @native.calls.length

          assert_equal "completed", reconcile(proof(delivered))["state"]
        end

        def test_delivered_event_superseded_by_signed_observation_returns_to_queued
          enqueue
          delivered = @inbox.deliver(event: @event)
          assert_equal "delivered", delivered["state"]

          assert_equal "queued", reconcile(proof(delivered, outcome: "superseded"))["state"]
          @native.result = {"accepted" => true, "stdout" => "queued"}
          redelivered = @inbox.deliver(event: @event)

          assert_equal "delivered", redelivered["state"]
          assert_equal 2, redelivered["claim_generation"]
          assert_equal 2, @native.calls.length
        end

        def test_reconciliation_requires_matching_observed_proof
          enqueue
          @native.result = {"accepted" => false, "error" => "stalled"}
          uncertain = @inbox.deliver(event: @event)
          receipt = proof(uncertain)
          incomplete = receipt.reject { |key, _| key == "evidence" }
          assert_match(/observation/, reconcile(incomplete)["reconciliation_refusal"])
          assert_equal "uncertain", @inbox.status(event: @event)["state"]
          assert_match(/does not match/, reconcile(receipt.merge("payload_sha256" => "wrong"))["reconciliation_refusal"])
          assert_equal "uncertain", @inbox.status(event: @event)["state"]
          assert_match(/signature/, reconcile(receipt, signature: "forged")["reconciliation_refusal"])
          assert_equal "uncertain", @inbox.status(event: @event)["state"]
          signed_bytes = JSON.generate(receipt)
          signed = RECEIPT_KEY.sign(OpenSSL::Digest::SHA256.new, signed_bytes)
          altered = receipt.merge("observer" => {"role" => "supervisor", "id" => "ops-2"})
          refusal = @inbox.reconcile(event: @event, receipt: altered,
            signed_bytes: signed_bytes, signature: signed)
          assert_match(/differs/, refusal["reconciliation_refusal"])
          assert_equal "completed", reconcile(receipt)["state"]
        end

        def test_superseded_proof_keeps_original_target_binding
          enqueue
          @native.result = {"accepted" => false, "error" => "stalled"}
          uncertain = @inbox.deliver(event: @event)
          receipt = proof(uncertain, outcome: "superseded")
          rogue_key = OpenSSL::PKey::RSA.generate(2048)
          rogue = Inbox.new(executor: @executor, native: @native, deliveries_dir: @dir,
            receipt_public_key: rogue_key.public_key)
          rogue_bytes = JSON.generate(receipt)
          rogue_result = rogue.reconcile(event: @event, receipt: receipt, signed_bytes: rogue_bytes,
            signature: rogue_key.sign(OpenSSL::Digest::SHA256.new, rogue_bytes))
          assert_match(/differs from the enqueued event/, rogue_result["reconciliation_refusal"])
          assert_equal "uncertain", @inbox.status(event: @event)["state"]
          assert_match(/signature/, reconcile(receipt, signature: "forged")["reconciliation_refusal"])
          assert_equal "uncertain", @inbox.status(event: @event)["state"]
          assert_equal "queued", reconcile(receipt)["state"]
          @executor.pane["agent_session"]["value"] = "9999abcd-0000-4000-8000-000000000009"
          @native.result = {"accepted" => true, "stdout" => "queued"}

          refused = @inbox.deliver(event: @event)
          assert_equal "uncertain", refused["state"]
          assert_equal 1, @native.calls.length
          assert_match(/does not match/, reconcile(receipt)["reconciliation_refusal"])
        end

        def test_signed_replacement_target_permits_new_thread_after_supersession
          enqueue
          @native.result = {"accepted" => false, "error" => "stalled"}
          uncertain = @inbox.deliver(event: @event)
          @executor.pane["agent_session"]["value"] = "9999abcd-0000-4000-8000-000000000009"
          replacement = uncertain["target"].merge("thread" => "9999abcd-0000-4000-8000-000000000009")
          wrong = replacement.merge("terminal_id" => "unrelated-terminal")
          assert_match(/does not match the live native session/,
            reconcile(proof(uncertain, outcome: "superseded").merge("replacement_target" => wrong))["reconciliation_refusal"])
          invalid = replacement.merge("pane" => "")
          assert_match(/replacement target cannot be verified/,
            reconcile(proof(uncertain, outcome: "superseded").merge("replacement_target" => invalid))["reconciliation_refusal"])
          receipt = proof(uncertain, outcome: "superseded").merge("replacement_target" => replacement)
          assert_equal "queued", reconcile(receipt)["state"]
          @native.result = {"accepted" => true, "stdout" => "queued"}

          delivered = @inbox.deliver(event: @event)

          assert_equal "delivered", delivered["state"]
          assert_equal 2, delivered["claim_generation"]
          assert_equal "9999abcd-0000-4000-8000-000000000009", delivered.dig("binding", "thread")
          assert_equal 2, @native.calls.length
        end

        def test_signed_replacement_target_permits_new_pane_after_supersession
          enqueue
          @native.result = {"accepted" => false, "error" => "stalled"}
          uncertain = @inbox.deliver(event: @event)
          @executor.pane["pane_id"] = "p2"
          @executor.pane["workspace_id"] = "ws2"
          @executor.pane["terminal_id"] = "term-2"
          @executor.pane["agent_session"]["value"] = "9999abcd-0000-4000-8000-000000000009"
          replacement = uncertain["target"].merge("session" => "ws2", "pane" => "p2",
            "terminal_id" => "term-2", "thread" => "9999abcd-0000-4000-8000-000000000009")
          receipt = proof(uncertain, outcome: "superseded").merge("replacement_target" => replacement)

          assert_equal "queued", reconcile(receipt)["state"]
          @native.result = {"accepted" => true, "stdout" => "queued"}
          delivered = @inbox.deliver(event: @event)

          assert_equal "delivered", delivered["state"]
          assert_equal "ws2", delivered.dig("binding", "session")
          assert_equal "p2", delivered.dig("binding", "pane")
          assert_equal "ws1", delivered["session"]
          assert_equal "p1", delivered["pane"]
        end
      end
    end
  end
end
