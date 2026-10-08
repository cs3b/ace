# frozen_string_literal: true
require "test_helper"
require_relative "../../support/inbox_context_owner_fixture"

class InboxDirectEffectsTest < Minitest::Test
  include InboxContextOwnerFixture

  class Native < NativeFixture
    attr_reader :calls
    def initialize = @calls = 0
    def submit(**arguments)
      @calls += 1
      super
    end
  end

  class IdlePane < PaneFixture
    attr_reader :wakes
    def initialize = @wakes = 0
    def pane_get_bounded(id)
      result = super
      value = JSON.parse(result.stdout)
      value.fetch("result").fetch("pane")["agent_status"] = "idle"
      Ace::Herdr::Molecules::ExecutionResult.new(stdout: JSON.generate(value), stderr: "", success: true, exit_code: 0)
    end
    def agent_prompt_bounded(**_options)
      @wakes += 1
      raise Ace::Herdr::ExecutorError, "controlled lost wake"
    end
  end

  class LostEnqueue < Ace::Herdr::Organisms::Inbox
    def enqueue(**arguments)
      super
      raise Ace::Herdr::ValidationError, "controlled interruption after durable enqueue"
    end
  end

  def source_box(executor: PaneFixture.new, type: Ace::Herdr::Organisms::Inbox)
    @native = Native.new
    @source_inbox = type.new(executor: executor, native: @native, deliveries_dir: @events, receipt_public_key: KEY.public_key)
    restart
  end

  def enqueue_arguments(operation)
    {operation_id: operation.fetch("operation_id"), key_generation: operation.fetch("key_generation"), event_id: "event1", attempt_id: "attempt1",
      reverse: {"schema" => Ace::Hitl::Providers::Ref::SCHEMA, "session" => "ws1", "pane" => "p1"}, payload_bytes: 5,
      payload_sha256: Digest::SHA256.hexdigest("hello"), payload: "hello", peer: @normal}
  end

  def enqueue_known
    admission = begin_operation
    result = @owner.enqueue_context(**enqueue_arguments(admission))
    assert_equal "idle", result.fetch("admission_state")
    [admission, result]
  end

  def delivery_arguments(admission, expected: 0)
    {operation_id: admission.fetch("operation_id"), key_generation: admission.fetch("key_generation"), event_id: "event1", attempt_id: "attempt1",
      expected_claim_generation: expected, peer: @normal}
  end

  def test_known_enqueue_reply_loss_restart_revalidates_record_before_resume_or_end
    source_box
    operation, result = enqueue_known
    restart
    assert_equal operation, begin_operation
    assert_equal result, @owner.enqueue_context(**enqueue_arguments(operation))
    before = File.binread(File.join(@state, ".context-control.json"))
    File.delete(File.join(@events, "event1.json"))
    assert_raises(ERROR) { begin_operation }
    assert_raises(ERROR) { @owner.end_context_operation(operation_id: operation.fetch("operation_id"), peer: @normal) }
    assert_equal before, File.binread(File.join(@state, ".context-control.json"))
    assert_equal 0, @native.calls
  end

  def test_unknown_enqueue_with_matching_durable_record_does_not_become_completion_after_restart
    source_box(type: LostEnqueue)
    operation = begin_operation
    assert_raises(ERROR) { @owner.enqueue_context(**enqueue_arguments(operation)) }
    assert_equal "queued", @source_inbox.retained_status(event: "event1").fetch("state")
    restart
    assert_equal "unknown", begin_operation.fetch("state")
    assert_raises(ERROR) { @owner.enqueue_context(**enqueue_arguments(operation)) }
    assert_raises(ERROR) { @owner.end_context_operation(operation_id: operation.fetch("operation_id"), peer: @normal) }
    assert_raises(ERROR) { begin_rotation }
    assert_equal 0, @native.calls
  end

  def test_delivered_pending_wake_stays_unknown_and_replay_never_retries_native_or_wake
    pane = IdlePane.new
    source_box(executor: pane)
    enqueue, = enqueue_known
    @owner.end_context_operation(operation_id: enqueue.fetch("operation_id"), peer: @normal)
    admission = begin_operation("deliver")
    first = @owner.deliver_context(**delivery_arguments(admission))
    assert_equal "delivered", first.dig("record", "state")
    assert_equal "unknown", first.fetch("admission_state")
    assert_equal "pending", first.dig("record", "wake", "status")
    assert_equal [1, 1], [@native.calls, pane.wakes]
    restart
    assert_equal first, @owner.deliver_context(**delivery_arguments(admission))
    assert_equal [1, 1], [@native.calls, pane.wakes]
    assert_raises(ERROR) { @owner.end_context_operation(operation_id: admission.fetch("operation_id"), peer: @normal) }
    assert_raises(ERROR) { begin_rotation }
  end

  def test_future_generation_refuses_before_effect_entry_and_wrong_attempt_cannot_deliver
    source_box
    enqueue, = enqueue_known
    @owner.end_context_operation(operation_id: enqueue.fetch("operation_id"), peer: @normal)
    admission = begin_operation("deliver")
    assert_raises(ERROR) { @owner.deliver_context(**delivery_arguments(admission, expected: 1)) }
    assert_equal "admitted", begin_operation("deliver").fetch("state")
    assert_raises(ERROR) { @owner.deliver_context(**delivery_arguments(admission).merge(attempt_id: "foreign")) }
    assert_equal "admitted", begin_operation("deliver").fetch("state")
    assert_equal "ended", @owner.end_context_operation(operation_id: admission.fetch("operation_id"), peer: @normal).fetch("state")
    assert_equal 0, @native.calls
  end

  def test_failed_actual_claim_admission_save_cannot_reach_native_submission
    source_box
    enqueue, = enqueue_known
    @owner.end_context_operation(operation_id: enqueue.fetch("operation_id"), peer: @normal)
    admission = begin_operation("deliver")
    @store.singleton_class.class_eval do
      define_method(:persist!) do |state|
        if state.fetch("operations").values.any? { |operation| operation["admitted_claim"] }
          raise Ace::Herdr::ValidationError, "controlled failure persisting actual claim"
        end
        super(state)
      end
    end
    assert_raises(ERROR) { @owner.deliver_context(**delivery_arguments(admission)) }
    assert_equal 0, @native.calls
    record = @source_inbox.retained_status(event: "event1")
    assert_equal ["claimed", 1, false], record.values_at("state", "claim_generation", "submission_intent")
    state = JSON.parse(File.binread(File.join(@state, ".context-control.json")))
    retained = state.fetch("operations").fetch(admission.fetch("operation_id"))
    assert_equal "running", retained.fetch("issuer_state")
    assert_nil retained.fetch("admitted_claim")
    assert_equal 1, retained.fetch("in_flight")
    assert_raises(ERROR) { @owner.end_context_operation(operation_id: admission.fetch("operation_id"), peer: @normal) }
  end

  def test_concurrent_same_generation_preparations_create_one_exact_event_claim
    source_box
    enqueue, = enqueue_known
    @owner.end_context_operation(operation_id: enqueue.fetch("operation_id"), peer: @normal)
    gate = Queue.new
    threads = 2.times.map do |index|
      Thread.new do
        gate.pop
        @source_inbox.prepare_direct_delivery(event: "event1", expected_claim_generation: 0,
          expected_attempt: "attempt1", claim_owner: Digest::SHA256.hexdigest("issuer#{index}"))
      rescue ERROR => error
        error
      end
    end
    2.times { gate << true }
    results = threads.map(&:value)
    assert_equal 1, results.count { |item| item.is_a?(Hash) }
    assert_equal 1, results.count(&:nil?), "the loser observes the advanced generation and creates no claim"
    record = JSON.parse(File.binread(File.join(@events, "event1.json")))
    assert_equal 1, record.fetch("inbox").fetch("claim_generation")
    assert_equal results.find { |item| item.is_a?(Hash) }.fetch("claim_owner"), record.fetch("inbox").fetch("claim_owner")
    assert_equal 1, record.fetch("history").count { |item| item["action"] == "claim" }
    assert_equal 0, @native.calls
  end
  def test_retained_signed_settlement_cannot_match_an_older_later_or_foreign_direct_claim
    source_box
    enqueue, = enqueue_known
    @owner.end_context_operation(operation_id: enqueue.fetch("operation_id"), peer: @normal)
    admission = begin_operation("deliver")
    delivered = @owner.deliver_context(**delivery_arguments(admission)).fetch("record")
    state = JSON.parse(File.binread(File.join(@state, ".context-control.json")))
    operation = state.fetch("operations").fetch(admission.fetch("operation_id"))
    receipt = delivered.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding").merge(
      "outcome" => "consumed", "observer" => {"role" => "supervisor", "id" => "controlled"},
      "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => "controlled-item", "observation" => "completed"})
    bytes = JSON.generate(receipt)
    registration = delivered.slice("event_id", "attempt_id", "payload_sha256", "receipt_key_sha256")
    settled = @source_inbox.reconcile(event: "event1", receipt: receipt, signed_bytes: bytes,
      signature: KEY.sign(OpenSSL::Digest::SHA256.new, bytes), expected_registration: registration)
    assert_equal "completed", settled.fetch("state")
    # This is the retained-record verifier's unit input, not an authenticated
    # canonical completion fixture. Actual query/CAS acceptance is tested in Assign.
    proof = {"registration" => registration, "state" => "completed", "claim_generation" => delivered.fetch("claim_generation"),
      "binding" => {"native_binding" => delivered.fetch("binding")}}
    actual = operation.fetch("admitted_claim")
    assert @source_inbox.verify_direct_canonical_settlement(binding: operation.fetch("effect_binding"), admitted_claim: actual, proof: proof)
    before = File.binread(File.join(@events, "event1.json"))
    [actual.merge("claim_generation" => 0), actual.merge("claim_generation" => 2),
      actual.merge("claim_owner" => "f" * 64)].each do |foreign|
      assert_raises(ERROR) do
        @source_inbox.verify_direct_canonical_settlement(binding: operation.fetch("effect_binding"), admitted_claim: foreign, proof: proof)
      end
    end
    assert_equal before, File.binread(File.join(@events, "event1.json"))
    assert_equal 1, @native.calls
  end

end
