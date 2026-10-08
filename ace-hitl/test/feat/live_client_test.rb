# frozen_string_literal: true
require "test_helper"
require "support/lifecycle_fixtures"
# Real Store and Inbox durable submission states. Only the actual Herdr
# terminal/process boundary is controlled; no app-server or read-proof fixture.
class LiveClientTest < AceHitlTestCase
  include LifecycleFixtures
  THREAD = "0123abcd-0000-4000-8000-000000000001"

  class Executor
    attr_reader :calls
    attr_accessor :uncertain
    def initialize
      @calls = []
    end
    def pane_get_bounded(_pane)
      Ace::Herdr::Molecules::ExecutionResult.new(stdout: JSON.generate("result" => {"pane" => {
        "pane_id" => "pane1", "workspace_id" => "workspace1", "terminal_id" => "terminal1",
        "agent" => "codex", "agent_status" => "busy",
        "agent_session" => {"agent" => "codex", "kind" => "id", "value" => THREAD}}}),
        stderr: "", success: true, exit_code: 0)
    end
    def agent_prompt_bounded(pane:, text:, timeout_ms:)
      raise Ace::Herdr::ValidationError, "wrong original terminal" unless pane == "pane1" && timeout_ms > 0
      @calls << {pane: pane, payload: text.dup}
      raise Ace::Herdr::ExecutorError, "lost terminal reply" if uncertain
      Ace::Herdr::Molecules::ExecutionResult.new(stdout: "submitted", stderr: "", success: true, exit_code: 0)
    end
  end

  class Boundary
    attr_accessor :envelope_override
    def initialize(store)
      @store = store
    end
    def read(id)
      value = @store.read(id)
      value["envelope"] = envelope_override if envelope_override
      value
    end
    def consume(id, **args); @store.consume(id, **args); end
    def pending(**args); @store.pending(**args); end
  end

  class Coordinator
    attr_accessor :binding, :bind_failure
    attr_reader :registered
    def initialize
      @binding = {"runtime" => "herdr", "session" => "workspace1", "pane" => "pane1",
        "terminal_id" => "terminal1", "agent" => "codex",
        "agent_session" => {"agent" => "codex", "kind" => "id", "value" => THREAD}}
      @registered = {}
    end
    def runtime_binding(attempt_id:, caller_pid:)
      raise Ace::Hitl::Lifecycle::BindingError, "owner unavailable" unless binding
      binding
    end
    def bind_inbox(attempt_id:, event_id:, inbox:)
      raise bind_failure if bind_failure
      @registered[event_id] = inbox.status(event: event_id).slice("event_id", "attempt_id", "payload_sha256")
    end
    def recovery_snapshot(_assignment)
      raise "delivery status must read the original Inbox, not recovery cache"
    end
  end

  def setup
    super
    @dir = Dir.mktmpdir("hitl-live")
    @reverse = {"schema" => "ace.hitl.ref/v1", "session" => "workspace1", "pane" => "pane1"}
    @store = make_store(root: File.join(@dir, "hitl"), binding: TestBinding.new(reverse: @reverse), poll_seconds: 0.01,
      vault: Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new)
    @boundary = Boundary.new(@store)
    @coordinator = Coordinator.new
    @executor = Executor.new
    @inbox = inbox
    @client = Ace::Hitl::LiveClient.new(boundary: @boundary, coordinator: @coordinator, inbox: @inbox)
  end

  def teardown
    FileUtils.remove_entry(@dir)
    super
  end

  def inbox
    Ace::Herdr::Organisms::Inbox.new(executor: @executor,
      deliveries_dir: File.join(@dir, "deliveries"))
  end

  def request(id: "live001", **args)
    @store.create(**request_args(id: id, **args))
  end

  def answer(id = "live001", text = "approved")
    @store.deliver(id, stdin_reader(text))
  end

  def test_shared_envelope_wrong_version_attempt_and_correlation_fail_before_consumption
    request
    answer
    original = @store.read("live001")["envelope"]
    [->(v) { v["schema"] = "ace.hitl.managed/v99" }, ->(v) { v["attempt_id"] = "other685" },
     ->(v) { v["correlation_id"] = "other-request" }].each do |change|
      value = Marshal.load(Marshal.dump(original))
      change.call(value)
      @boundary.envelope_override = value
      assert_raises(Ace::Hitl::Lifecycle::BindingError) { @client.deliver(request: "live001", timeout: 1) }
      assert_equal "answer-delivered", @store.read("live001")["state"]
    end
    assert_empty @executor.calls
  end

  def test_dead_or_different_native_owner_cannot_consume_or_choose_new_pane
    request
    answer
    [nil, {"session" => "workspace1", "pane" => "replacement"}].each do |owner|
      @coordinator.binding = owner
      assert_raises(Ace::Hitl::Lifecycle::BindingError) { @client.deliver(request: "live001", timeout: 1) }
      assert_equal "answer-delivered", @store.read("live001")["state"]
    end
    assert_empty @executor.calls
    assert_equal ["live001"], @client.pending.map { |value| value["id"] }
  end

  def test_incomplete_native_owner_refuses_before_answer_consumption
    request
    answer
    @coordinator.binding = @coordinator.binding.reject { |key, _| key == "agent_session" }
    assert_raises(Ace::Herdr::ValidationError) { @client.deliver(request: "live001", timeout: 1) }
    assert_equal "answer-delivered", @store.read("live001")["state"]
    assert_empty @executor.calls
  end

  def test_terminal_submission_finishes_attention_without_a_read_receipt_and_replay_is_idempotent
    request
    assert_equal "not-submitted", @client.status(request: "live001")["delivery"]["state"]
    answer
    first = @client.deliver(request: "live001", timeout: 1)
    assert_equal "delivered", first["state"]
    assert_equal [{pane: "pane1", payload: "approved"}], @executor.calls
    assert_equal "delivered", @client.status(request: "live001")["delivery"]["state"]
    assert_empty @client.pending
    restarted = Ace::Hitl::LiveClient.new(boundary: @boundary, coordinator: @coordinator, inbox: inbox)
    assert_equal "delivered", restarted.status(request: "live001")["delivery"]["state"]
    assert_equal first, restarted.deliver(request: "live001", timeout: 1)
    assert_equal 1, @executor.calls.size
    refute_respond_to @client, :reconcile
  end

  def test_restart_after_consume_and_before_registration_reuses_same_event
    request
    answer
    @coordinator.bind_failure = IOError.new("simulated stop before bind")
    assert_raises(IOError) { @client.deliver(request: "live001", timeout: 1) }
    assert_empty @executor.calls
    assert_equal "consumed", @store.read("live001")["state"]
    @coordinator.bind_failure = nil
    restarted = Ace::Hitl::LiveClient.new(boundary: @boundary, coordinator: @coordinator, inbox: inbox)
    assert_equal "delivered", restarted.deliver(request: "live001", timeout: 1)["state"]
    assert_equal 1, @executor.calls.size
  end

  def test_uncertain_terminal_reply_is_visible_from_source_and_never_automatically_repeated
    request
    answer
    @executor.uncertain = true
    record = @client.deliver(request: "live001", timeout: 1)
    assert_equal "uncertain", record["state"]
    @executor.uncertain = false
    restarted = Ace::Hitl::LiveClient.new(boundary: @boundary, coordinator: @coordinator, inbox: inbox)
    assert_equal "uncertain", restarted.status(request: "live001")["delivery"]["state"]
    assert_equal "uncertain", restarted.deliver(request: "live001", timeout: 1)["state"]
    assert_equal 1, @executor.calls.size
    assert_equal ["live001"], restarted.pending.map { |value| value["id"] }
  end

  def test_otp_never_enters_native_envelope_and_pane_less_wait_remains_independent
    request(kind: "otp", otp: otp_context)
    answer("live001", "123456")
    assert_raises(Ace::Hitl::Lifecycle::StateError) { @client.deliver(request: "live001", timeout: 1) }
    assert_empty @executor.calls
    assert_empty Dir.glob(File.join(@dir, "deliveries", "**", "*"))
    envelope = @store.read("live001")["envelope"]
    refute envelope.key?("payload_sha256")
    assert_equal "123456", @client.wait(request: "live001", timeout: 1, operation: "gem-push")["answer"]
    assert_equal "not-applicable", @client.status(request: "live001")["delivery"]["state"]
  end

  def test_in_process_watch_keeps_business_effect_receipt_separate_from_terminal_submission
    marker = File.join(@dir, "callback-count")
    request(effect: {match: nil, effect_args: ["/bin/sh", "-c", "printf x >> '$MARKER'".sub('$MARKER', marker)],
      effect_cwd: @dir, effect_timeout: 5})
    answer
    callbacks = []
    watcher = @client.watch(request: "live001", timeout: 1) { |result| callbacks << result["state"] }
    record = watcher.value
    assert_equal ["delivered"], callbacks
    assert_equal "x", File.read(marker)
    assert record.dig("managed_envelope", "effect", "authorization_ref")
    assert record.dig("managed_envelope", "effect", "receipt_ref")
    assert_equal "delivered", @client.status(request: "live001")["delivery"]["state"]
    @client.deliver(request: "live001", timeout: 1)
    assert_equal "x", File.read(marker)
    assert_equal 1, @executor.calls.size
  end

  def test_local_answer_consumption_cannot_be_upgraded_to_native_claim_and_no_signer_is_required
    request
    answer
    assert_equal "approved", @client.wait(request: "live001", timeout: 1)["answer"]
    assert_raises(Ace::Hitl::Lifecycle::StateError) { @client.deliver(request: "live001", timeout: 1) }
    assert_empty @executor.calls
    request(id: "live002")
    answer("live002")
    assert_equal "delivered", @client.deliver(request: "live002", timeout: 1)["state"]
    assert_equal true, @store.read("live002")["native_delivery"]
    assert_equal 1, @executor.calls.size
  end
  def test_native_restart_between_consumption_and_enqueue_refuses_replacement
    request
    answer
    executor = @inbox.instance_variable_get(:@executor)
    original_consume = @boundary.method(:consume)
    @boundary.define_singleton_method(:consume) do |id, **args|
      result = original_consume.call(id, **args)
      original_observe = executor.method(:pane_get_bounded)
      executor.define_singleton_method(:pane_get_bounded) do |pane|
        value = original_observe.call(pane)
        Ace::Herdr::Molecules::ExecutionResult.new(stdout: value.stdout.sub(LiveClientTest::THREAD,
          "0123abcd-0000-4000-8000-000000000002"), stderr: "", success: true, exit_code: 0)
      end
      result
    end
    assert_raises(Ace::Herdr::Organisms::Inbox::IdentityDriftError) do
      @client.deliver(request: "live001", timeout: 1)
    end
    assert_equal "consumed", @store.read("live001")["state"]
    assert_empty @executor.calls
    event = Ace::Hitl::Contract::ManagedEnvelope.inbox_event_id(@store.read("live001")["envelope"])
    assert_nil Ace::Herdr::Molecules::DeliveryRecordStore.load(File.join(@dir, "deliveries"), event)
    # A fresh caller must still use the accepted owner, never the reused pane.
    restarted = Ace::Hitl::LiveClient.new(boundary: @boundary, coordinator: @coordinator, inbox: @inbox)
    assert_raises(Ace::Herdr::Organisms::Inbox::IdentityDriftError) do
      restarted.deliver(request: "live001", timeout: 1)
    end
    assert_empty @executor.calls
  end

end
