# frozen_string_literal: true
require "test_helper"
require_relative "../../support/inbox_context_owner_fixture"

class InboxDirectEffectsTest < Minitest::Test
  include InboxContextOwnerFixture

  class Native < NativeFixture
    attr_reader :calls
    def initialize = @calls = 0
    def pi_identity = "0123abcd-0000-4000-8000-000000000001"
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
      pane = value.fetch("result").fetch("pane")
      pane["agent_status"] = "idle"
      pane["agent"] = "pi"
      pane.fetch("agent_session")["agent"] = "pi"
      Ace::Herdr::Molecules::ExecutionResult.new(stdout: JSON.generate(value), stderr: "", success: true, exit_code: 0)
    end
    def agent_prompt_bounded(**_options)
      @wakes += 1
      raise Ace::Herdr::ExecutorError, "controlled lost wake"
    end
  end

  # This owner-phase fixture substitutes only the native transport. The real
  # control's fixed queue payload, response parser, and origin validator run.
  class GuardedControl < Ace::Herdr::Molecules::ProtectedNativeControl
    attr_reader :calls
    attr_accessor :response, :before_exchange
    def initialize
      super(mapping: {})
      @calls = []
      @response = :lost
    end
    def guarded_binding!(binding) = binding.merge("guarded_origin" => @origin)
    def origin=(value)
      @origin = value
    end
    def exchange(method, params, **_limits)
      @calls << [method, params]
      before_exchange&.call
      if response == :sent
        return {"id" => "controlled", "result" => {"type" => "agent_prompted", "submission" => "submitted", "origin" => params.fetch("expected_origin"), "agent" => {}}}
      end
      raise Ace::Runtime::RuntimeUnavailableError, "controlled lost wake" if response == :lost
      {"id" => "controlled", "error" => {"phase" => "not_issued", "code" => "agent_not_ready", "message" => "controlled refusal"}}
    end
  end

  def guarded_control
    control = GuardedControl.new
    identity = @normal
    origin = {"terminal_id" => "term_ab", "runtime_incarnation" => "00000000-0000-0000-0000-000000000001", "child" => identity}
    control.origin = origin
    query = @completion = ControlledOriginalIdentity.new
    query.define_singleton_method(:original!) do |**params|
      super(**params).merge("process_binding" => {"session" => "ws1", "pane" => "p1", "terminal_id" => "term_ab", "process_identity" => identity},
        "guarded_origin" => origin)
    end
    restart
    @owner.define_singleton_method(:direct_queue_control!) { |_original| control }
    control
  end

  class FaultedWakeInbox < Ace::Herdr::Organisms::Inbox
    attr_accessor :fail_status, :after_publication
    def with_receipt_public_key(key)
      super(key).tap do |box|
        box.fail_status = fail_status
        box.after_publication = after_publication
      end
    end
    def save(record)
      if fail_status && record.inbox.dig("wake", "status") == fail_status
        super(record) if after_publication
        raise Ace::Herdr::ValidationError, "controlled notification publication interruption"
      end
      super(record)
    end
  end

  class LostEnqueue < Ace::Herdr::Organisms::Inbox
    def enqueue(**arguments)
      super
      raise Ace::Herdr::ValidationError, "controlled interruption after durable enqueue"
    end
  end

  # Pi retains the separate terminal notification effect. Codex queue/add
  # owns progression and is covered by the real-driver service composition.
  def begin_operation(purpose = "enqueue", identity = @normal)
    super(purpose, identity, event: "inb-event001")
  end

  def source_box(executor: PaneFixture.new, type: Ace::Herdr::Organisms::Inbox)
    @native = Native.new
    @source_inbox = type.new(executor: executor, native: @native, deliveries_dir: @events)
    restart
  end

  def enqueue_arguments(operation)
    {operation_id: operation.fetch("operation_id"), key_generation: operation.fetch("key_generation"), event_id: "inb-event001", attempt_id: "attempt1",
      reverse: {"schema" => Ace::Hitl::Providers::Ref::SCHEMA, "session" => "ws1", "pane" => "p1"}, payload_bytes: 5,
      payload_sha256: Digest::SHA256.hexdigest("hello"), payload: "hello", original: direct_original, peer: @normal}
  end

  def enqueue_known
    admission = begin_operation
    result = @owner.enqueue_context(**enqueue_arguments(admission))
    assert_equal "idle", result.fetch("admission_state")
    [admission, result]
  end

  def delivery_arguments(admission, expected: 0)
    {operation_id: admission.fetch("operation_id"), key_generation: admission.fetch("key_generation"), event_id: "inb-event001", attempt_id: "attempt1",
      expected_claim_generation: expected, original: direct_original, peer: @normal}
  end

  def test_original_query_runs_outside_store_and_changed_admission_refuses_before_enqueue
    source_box
    operation = begin_operation
    changed = false
    query = @completion = ControlledOriginalIdentity.new
    test = self
    query.define_singleton_method(:original!) do |**params|
      test.instance_variable_get(:@store).transaction do |state|
        state.fetch("operations").fetch(operation.fetch("operation_id")).fetch("original")["assignment_id"] = "other"
        changed = true
      end
      super(**params)
    end
    restart
    assert_raises(ERROR) { @owner.enqueue_context(**enqueue_arguments(operation)) }
    assert changed, "query must finish its separate store transaction without nested lock"
    assert_equal 0, @native.calls
    refute File.exist?(File.join(@events, "inb-event001.json"))
    state = @store.transaction { |value| JSON.parse(JSON.generate(value)) }
    retained = state.fetch("operations").fetch(operation.fetch("operation_id"))
    assert_equal 0, retained.fetch("in_flight")
    assert_nil retained.fetch("effect_binding")
  end

  def test_changed_original_tuple_cannot_replay_or_read_an_existing_event
    source_box
    admission, = enqueue_known
    before = File.binread(File.join(@events, "inb-event001.json"))
    assert_raises(ERROR) { @owner.enqueue_context(**enqueue_arguments(admission).merge(original: direct_original.merge("assignment_id" => "other"))) }
    assert_raises(ERROR) { @owner.status_context(event_id: "inb-event001", attempt_id: "attempt1", original: direct_original.merge("mapping_id" => "other"), peer: @normal) }
    assert_equal before, File.binread(File.join(@events, "inb-event001.json"))
    assert_equal 0, @native.calls
  end

  def test_known_enqueue_reply_loss_restart_revalidates_record_before_resume_or_end
    source_box
    operation, result = enqueue_known
    restart
    assert_equal operation, begin_operation
    assert_equal result, @owner.enqueue_context(**enqueue_arguments(operation))
    before = File.binread(File.join(@state, ".context-control.json"))
    File.delete(File.join(@events, "inb-event001.json"))
    assert_raises(ERROR) { begin_operation }
    assert_raises(ERROR) { @owner.end_context_operation(operation_id: operation.fetch("operation_id"), peer: @normal) }
    assert_equal before, File.binread(File.join(@state, ".context-control.json"))
    assert_equal 0, @native.calls
  end

  def test_unknown_enqueue_with_matching_durable_record_does_not_become_completion_after_restart
    source_box(type: LostEnqueue)
    operation = begin_operation
    assert_raises(ERROR) { @owner.enqueue_context(**enqueue_arguments(operation)) }
    assert_equal "queued", @source_inbox.retained_status(event: "inb-event001").fetch("state")
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
    control = guarded_control
    admission = begin_operation("deliver")
    first = @owner.deliver_context(**delivery_arguments(admission))
    assert_equal "delivered", first.dig("record", "state")
    assert_equal "unknown", first.fetch("admission_state")
    assert_equal "uncertain", first.dig("record", "wake", "status")
    assert_equal [1, 1], [@native.calls, control.calls.size]
    restart
    assert_equal first, @owner.deliver_context(**delivery_arguments(admission))
    assert_equal [1, 1], [@native.calls, control.calls.size]
    assert_raises(ERROR) { @owner.end_context_operation(operation_id: admission.fetch("operation_id"), peer: @normal) }
    assert_raises(ERROR) { begin_rotation }
  end

  def test_positive_not_issued_requires_fresh_admission_and_retries_only_notification
    source_box(executor: IdlePane.new)
    enqueue, = enqueue_known
    @owner.end_context_operation(operation_id: enqueue.fetch("operation_id"), peer: @normal)
    control = guarded_control
    control.response = :not_issued
    original = begin_operation("deliver")
    first = @owner.deliver_context(**delivery_arguments(original))
    assert_equal "idle", first.fetch("admission_state")
    assert_equal "not_issued", first.dig("record", "wake", "status")
    retained = JSON.parse(File.binread(File.join(@events, "inb-event001.json")))
    queue_tuple = retained.fetch("inbox").slice("claim_generation", "claim_owner", "queue_issuer", "receipt")
    assert_equal first, @owner.deliver_context(**delivery_arguments(original))
    assert_equal 1, control.calls.size
    @owner.end_context_operation(operation_id: original.fetch("operation_id"), peer: @normal)
    restarted = guarded_control
    restarted.response = :not_issued
    retry_admission = begin_operation("deliver")
    second = @owner.deliver_context(**delivery_arguments(retry_admission, expected: 1))
    assert_equal "idle", second.fetch("admission_state")
    assert_equal "not_issued", second.dig("record", "wake", "status")
    assert_equal [1, 1], [@native.calls, restarted.calls.size]
    after = JSON.parse(File.binread(File.join(@events, "inb-event001.json")))
    assert_equal queue_tuple, after.fetch("inbox").slice("claim_generation", "claim_owner", "queue_issuer", "receipt")
    assert_equal retry_admission.fetch("operation_id"), after.dig("inbox", "wake", "operation_id")
    metadata = JSON.parse(File.binread(File.join(@state, ".context-control.json")))
    assert_equal "wake", metadata.dig("operations", retry_admission.fetch("operation_id"), "admitted_claim", "kind")
    assert_equal second, @owner.deliver_context(**delivery_arguments(retry_admission, expected: 1))
    assert_equal 1, restarted.calls.size
    assert restarted.calls.all? { |method, params| method == "agent.prompt" && params.fetch("text") == "Check your native queued messages." }
    @owner.end_context_operation(operation_id: retry_admission.fetch("operation_id"), peer: @normal)
  end

  def test_guarded_notification_io_releases_context_and_event_locks_and_returns_saved_sent_state
    source_box(executor: IdlePane.new)
    enqueue, = enqueue_known
    @owner.end_context_operation(operation_id: enqueue.fetch("operation_id"), peer: @normal)
    control = guarded_control
    control.response = :sent
    admission = begin_operation("deliver")
    observed = false
    control.before_exchange = lambda do
      metadata = @store.transaction { |state| JSON.parse(JSON.generate(state)) }
      assert_equal 1, metadata.dig("operations", admission.fetch("operation_id"), "in_flight")
      assert_equal "issuing", @source_inbox.retained_status(event: "inb-event001").dig("wake", "status")
      observed = true
    end
    result = @owner.deliver_context(**delivery_arguments(admission))
    assert observed, "actual notification boundary must allow separate store/event reads"
    assert_equal "sent", result.dig("record", "wake", "status")
    assert_equal "idle", result.fetch("admission_state")
    assert_equal [1, 1], [@native.calls, control.calls.size]
    restart
    assert_equal result, @owner.deliver_context(**delivery_arguments(admission))
    assert_equal [1, 1], [@native.calls, control.calls.size]
    assert_equal "ended", @owner.end_context_operation(operation_id: admission.fetch("operation_id"), peer: @normal).fetch("state")
  end

  def test_notification_retry_rejects_forged_queue_issuer_receipt_and_wake_binding_before_io
    source_box(executor: IdlePane.new)
    enqueue, = enqueue_known
    @owner.end_context_operation(operation_id: enqueue.fetch("operation_id"), peer: @normal)
    control = guarded_control
    control.response = :not_issued
    original = begin_operation("deliver")
    @owner.deliver_context(**delivery_arguments(original))
    @owner.end_context_operation(operation_id: original.fetch("operation_id"), peer: @normal)
    retry_admission = begin_operation("deliver")
    path = File.join(@events, "inb-event001.json")
    saved = File.binread(path)
    changes = [
      ->(value) { value.fetch("inbox").fetch("queue_issuer")["operation_id"] = "f" * 32 },
      ->(value) { value.fetch("inbox").fetch("queue_issuer")["input_sha256"] = "f" * 64 },
      ->(value) { value.fetch("inbox").fetch("receipt")["claim_generation"] = 2 },
      ->(value) { value.fetch("inbox").fetch("wake")["binding_digest"] = "f" * 64 }
    ]
    changes.each do |change|
      value = JSON.parse(saved)
      change.call(value)
      File.binwrite(path, JSON.generate(value))
      assert_raises(ERROR) { @owner.deliver_context(**delivery_arguments(retry_admission, expected: 1)) }
      assert_equal [1, 1], [@native.calls, control.calls.size]
      File.binwrite(path, saved)
    end
    accepted = @owner.deliver_context(**delivery_arguments(retry_admission, expected: 1))
    assert_equal "idle", accepted.fetch("admission_state")
    assert_equal [1, 2], [@native.calls, control.calls.size]
    value = JSON.parse(File.binread(path))
    value.fetch("inbox").fetch("wake")["operation_id"] = original.fetch("operation_id")
    File.binwrite(path, JSON.generate(value))
    assert_raises(ERROR) { @owner.end_context_operation(operation_id: retry_admission.fetch("operation_id"), peer: @normal) }
    assert_equal [1, 2], [@native.calls, control.calls.size]
  end

  def assert_wake_publication_interruption(status:, after:, expected_calls:, retained_status:)
    source_box(executor: IdlePane.new, type: FaultedWakeInbox)
    enqueue, = enqueue_known
    @owner.end_context_operation(operation_id: enqueue.fetch("operation_id"), peer: @normal)
    control = guarded_control
    @source_inbox.fail_status = status
    @source_inbox.after_publication = after
    admission = begin_operation("deliver")
    assert_raises(ERROR) { @owner.deliver_context(**delivery_arguments(admission)) }
    assert_equal [1, expected_calls], [@native.calls, control.calls.size]
    retained = @source_inbox.retained_status(event: "inb-event001")
    assert_equal retained_status, retained.dig("wake", "status")
    @source_inbox.fail_status = nil
    restart
    replay = @owner.deliver_context(**delivery_arguments(admission))
    assert_equal "unknown", replay.fetch("admission_state")
    assert_equal retained_status, replay.dig("record", "wake", "status")
    assert_equal [1, expected_calls], [@native.calls, control.calls.size]
    assert_raises(ERROR) { @owner.end_context_operation(operation_id: admission.fetch("operation_id"), peer: @normal) }
    assert_equal "unknown", begin_operation("deliver").fetch("state")
  end

  def test_failed_issuing_save_never_sends_and_cannot_be_adopted_after_restart
    assert_wake_publication_interruption(status: "issuing", after: false, expected_calls: 0, retained_status: "pending")
  end

  def test_crash_after_issuing_save_never_sends_or_adopts_after_restart
    assert_wake_publication_interruption(status: "issuing", after: true, expected_calls: 0, retained_status: "issuing")
  end

  def test_failed_uncertain_finish_save_never_repeats_notification_after_restart
    assert_wake_publication_interruption(status: "uncertain", after: false, expected_calls: 1, retained_status: "issuing")
  end

  def test_crash_after_uncertain_finish_save_never_repeats_notification_after_restart
    assert_wake_publication_interruption(status: "uncertain", after: true, expected_calls: 1, retained_status: "uncertain")
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
    record = @source_inbox.retained_status(event: "inb-event001")
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
        operation_id = "%032x" % (index + 1)
        binding = Ace::Herdr::Molecules::InboxDirectEffectBinding.build(purpose: "deliver", event_id: "inb-event001",
          attempt_id: "attempt1", key_generation: enqueue.fetch("key_generation"),
          selection: {"expected_claim_generation" => 0}, original: direct_original)
        @source_inbox.prepare_direct_delivery(event: "inb-event001", expected_claim_generation: 0,
          expected_attempt: "attempt1", operation_id: operation_id, key_generation: enqueue.fetch("key_generation"),
          effect_binding: binding, claim_owner: Digest::SHA256.hexdigest(JSON.generate([direct_original.fetch("inbox_context_id"), operation_id])))
      rescue ERROR => error
        error
      end
    end
    2.times { gate << true }
    results = threads.map(&:value)
    assert_equal 1, results.count { |item| item.is_a?(Hash) }
    assert_equal 1, results.count(&:nil?), "the loser observes the advanced generation and creates no claim"
    record = JSON.parse(File.binread(File.join(@events, "inb-event001.json")))
    assert_equal 1, record.fetch("inbox").fetch("claim_generation")
    assert_equal results.find { |item| item.is_a?(Hash) }.fetch("claim_owner"), record.fetch("inbox").fetch("claim_owner")
    assert_equal 1, record.fetch("history").count { |item| item["action"] == "claim" }
    assert_equal 0, @native.calls
  end




end
