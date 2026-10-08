# frozen_string_literal: true
require "test_helper"
require "support/lifecycle_fixtures"
require "openssl"

# Real Store, Inbox durable states and signed verifier. Coordinator/native
# observer fixtures name the already independently tested authority boundary;
# this suite never claims installed native consumption from the fake adapter.
class LiveClientTest < AceHitlTestCase
  include LifecycleFixtures
  THREAD = "0123abcd-0000-4000-8000-000000000001"
  KEY = OpenSSL::PKey::RSA.generate(2048)

  class Native
    attr_reader :calls, :prepared
    attr_accessor :uncertain
    def initialize
      @calls = []
      @prepared = []
    end

    # Named producer seam: models the current Codex queue correlation, never
    # installed endpoint authentication or actual native consumption.
    def prepare_submission(agent:, thread:, event_id:, attempt_id:, claim_generation:, digest:)
      raise Ace::Herdr::ValidationError, "fixture requires original Codex thread" unless agent == "codex" && thread == THREAD
      submission = {"schema" => "ace.herdr.codex-submission/v1", "provider_version" => "rust-v0.159.3",
        "endpoint_reference_sha256" => "a" * 64, "thread_id" => thread,
        "server_process_binding" => {"pid" => 42, "parent_pid" => 1, "uid" => 1001, "gid" => 1001,
          "groups" => [1001], "host" => "fixture", "started_at" => "linux:0123abcd-0000-4000-8000-000000000001:42"},
        "event_id" => event_id, "attempt_id" => attempt_id, "claim_generation" => claim_generation,
        "payload_sha256" => digest, "client_user_message_id" => "ace-#{SecureRandom.hex(16)}"}
      @prepared << submission
      submission
    end

    def submit(agent:, thread:, event_id:, digest:, payload:, submission:)
      unless agent == "codex" && @prepared.include?(submission) &&
          submission.values_at("thread_id", "event_id", "payload_sha256") == [thread, event_id, digest] &&
          Digest::SHA256.hexdigest(payload) == digest
        raise Ace::Herdr::ValidationError, "fixture submission correlation differs"
      end
      @calls << {agent: agent, thread: thread, event_id: event_id, digest: digest, payload: payload.dup, submission: submission}
      return {"accepted" => false, "error" => "lost response"} if uncertain

      submission.slice("provider_version", "endpoint_reference_sha256", "thread_id",
        "client_user_message_id", "payload_sha256", "server_process_binding").merge(
          "accepted" => true, "queued_submission_id" => SecureRandom.uuid)
    end
  end

  class Executor
    def pane_get_bounded(_pane)
      Ace::Herdr::Molecules::ExecutionResult.new(stdout: JSON.generate("result" => {"pane" => {
        "pane_id" => "pane1", "workspace_id" => "workspace1", "terminal_id" => "terminal1",
        "agent" => "codex", "agent_status" => "busy",
        "agent_session" => {"agent" => "codex", "kind" => "id", "value" => THREAD}}}),
        stderr: "", success: true, exit_code: 0)
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
    attr_reader :registered, :observed
    def initialize
      @binding = {"runtime" => "herdr", "session" => "workspace1", "pane" => "pane1",
        "terminal_id" => "terminal1", "agent" => "codex",
        "agent_session" => {"agent" => "codex", "kind" => "id", "value" => THREAD}}
      @registered = {}
      @observed = {}
    end
    def runtime_binding(attempt_id:, caller_pid:)
      raise Ace::Hitl::Lifecycle::BindingError, "owner unavailable" unless binding
      binding
    end
    def bind_inbox(attempt_id:, event_id:, inbox:)
      raise bind_failure if bind_failure
      @registered[event_id] = inbox.status(event: event_id).slice("event_id", "attempt_id", "payload_sha256", "receipt_key_sha256")
    end
    def reconcile_inbox(attempt_id:, event_id:, receipt_path:, inbox:)
      raise Ace::Hitl::Lifecycle::BindingError, "registration missing" unless registered[event_id]
      bytes = File.binread(receipt_path)
      value = inbox.reconcile(event: event_id, receipt: JSON.parse(bytes), signed_bytes: bytes,
        signature: File.binread("#{receipt_path}.sig"), expected_registration: registered.fetch(event_id))
      @observed[event_id] = value unless value["reconciliation_refusal"]
      value
    end
    def recovery_snapshot(_assignment)
      {"inbox_events" => observed.values}
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
    @native = Native.new
    @inbox = inbox
    @client = Ace::Hitl::LiveClient.new(boundary: @boundary, coordinator: @coordinator, inbox: @inbox)
  end

  def teardown
    FileUtils.remove_entry(@dir)
    super
  end

  def inbox(key: KEY.public_key)
    Ace::Herdr::Organisms::Inbox.new(executor: Executor.new, native: @native,
      deliveries_dir: File.join(@dir, "deliveries"), receipt_public_key: key)
  end

  def request(id: "live001", **args)
    @store.create(**request_args(id: id, **args))
  end

  def answer(id = "live001", text = "approved")
    @store.deliver(id, stdin_reader(text))
  end

  def proof(record, outcome: "consumed", key: KEY)
    value = record.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding")
      .merge("outcome" => outcome, "observer" => {"role" => "supervisor", "id" => "ops1"},
        "evidence" => {"kind" => outcome == "consumed" ? "consumed_acknowledged" : "queue_evicted",
          "native_reference" => "codex-client-message:#{@native.calls.last.fetch(:submission).fetch("client_user_message_id")}",
          "observation" => "fixture observer outcome for the retained Codex submission"})
    yield value if block_given?
    path = File.join(@dir, "receipt.json")
    bytes = JSON.generate(value)
    File.binwrite(path, bytes)
    File.binwrite("#{path}.sig", key.sign(OpenSSL::Digest::SHA256.new, bytes))
    path
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
    assert_empty @native.calls
  end

  def test_dead_or_different_native_owner_cannot_consume_or_choose_new_pane
    request
    answer
    [nil, {"session" => "workspace1", "pane" => "replacement"}].each do |owner|
      @coordinator.binding = owner
      assert_raises(Ace::Hitl::Lifecycle::BindingError) { @client.deliver(request: "live001", timeout: 1) }
      assert_equal "answer-delivered", @store.read("live001")["state"]
    end
    assert_empty @native.calls
    assert_equal ["live001"], @client.pending.map { |value| value["id"] }
  end

  def test_incomplete_native_owner_refuses_before_answer_consumption
    request
    answer
    @coordinator.binding = @coordinator.binding.reject { |key, _| key == "agent_session" }
    assert_raises(Ace::Herdr::ValidationError) { @client.deliver(request: "live001", timeout: 1) }
    assert_equal "answer-delivered", @store.read("live001")["state"]
    assert_empty @native.calls
  end

  def test_queue_acceptance_stays_pending_until_signed_consumption_and_replay_is_idempotent
    request
    answer
    first = @client.deliver(request: "live001", timeout: 1)
    assert_equal "delivered", first["state"]
    assert_equal "approved", @native.calls.first[:payload]
    assert_equal 1, @native.calls.size
    submission = @native.prepared.fetch(0)
    assert_equal first.values_at("event_id", "attempt_id", "claim_generation", "payload_sha256"),
      submission.values_at("event_id", "attempt_id", "claim_generation", "payload_sha256")
    durable = Ace::Herdr::Molecules::DeliveryRecordStore.load(File.join(@dir, "deliveries"), first.fetch("event_id"))
    accepted = durable.inbox.fetch("receipt").fetch("codex_submission")
    assert_equal submission.fetch("client_user_message_id"), accepted.fetch("client_user_message_id")
    assert_equal THREAD, accepted.fetch("thread_id")
    assert_match(Ace::Herdr::Molecules::CodexAppServerTransport::UUID, accepted.fetch("queued_submission_id"))
    assert_equal "unknown", @client.status(request: "live001")["delivery"]["state"]
    assert_equal ["live001"], @client.pending.map { |v| v["id"] }
    assert_equal first, @client.deliver(request: "live001", timeout: 1)
    assert_equal 1, @native.calls.size
    path = proof(first)
    assert_equal "completed", @client.reconcile(request: "live001", receipt_path: path)["state"]
    assert_equal "completed", @client.reconcile(request: "live001", receipt_path: path)["state"]
    assert_empty @client.pending
  end

  def test_restart_after_consume_and_before_registration_reuses_same_event
    request
    answer
    @coordinator.bind_failure = IOError.new("simulated stop before bind")
    assert_raises(IOError) { @client.deliver(request: "live001", timeout: 1) }
    assert_empty @native.calls
    assert_equal "consumed", @store.read("live001")["state"]
    @coordinator.bind_failure = nil
    restarted = Ace::Hitl::LiveClient.new(boundary: @boundary, coordinator: @coordinator, inbox: inbox)
    assert_equal "delivered", restarted.deliver(request: "live001", timeout: 1)["state"]
    assert_equal 1, @native.calls.size
  end

  def test_bad_signature_digest_generation_and_rotated_key_cannot_settle
    request
    answer
    record = @client.deliver(request: "live001", timeout: 1)
    [->(v) { v["payload_sha256"] = "f" * 64 }, ->(v) { v["claim_generation"] += 1 }].each do |change|
      result = @client.reconcile(request: "live001", receipt_path: proof(record, &change))
      assert result["reconciliation_refusal"]
      assert_empty @coordinator.observed
    end
    other = OpenSSL::PKey::RSA.generate(2048)
    assert @client.reconcile(request: "live001", receipt_path: proof(record, key: other))["reconciliation_refusal"]
    rotated = Ace::Hitl::LiveClient.new(boundary: @boundary, coordinator: @coordinator, inbox: inbox(key: other.public_key))
    assert rotated.reconcile(request: "live001", receipt_path: proof(record))["reconciliation_refusal"]
    assert_equal 1, @native.calls.size
  end

  def test_uncertain_delivery_never_retries_on_elapsed_time_and_supersession_requires_explicit_retry
    request
    answer
    @native.uncertain = true
    record = @client.deliver(request: "live001", timeout: 1)
    assert_equal "uncertain", record["state"]
    assert_equal "uncertain", @client.deliver(request: "live001", timeout: 1)["state"]
    assert_equal 1, @native.calls.size
    path = proof(record, outcome: "superseded")
    assert_equal "queued", @client.reconcile(request: "live001", receipt_path: path)["state"]
    assert_equal 1, @native.calls.size
    assert_equal "queued", @client.deliver(request: "live001", timeout: 1)["state"]
    assert_equal 1, @native.calls.size
    @native.uncertain = false
    assert_equal "delivered", @client.reconcile(request: "live001", receipt_path: path, retry_delivery: true)["state"]
    assert_equal 2, @native.calls.size
    original, replacement = @native.calls.map { |call| call.fetch(:submission) }
    assert_equal original.fetch("event_id"), replacement.fetch("event_id")
    assert_operator replacement.fetch("claim_generation"), :>, original.fetch("claim_generation")
    refute_equal original.fetch("client_user_message_id"), replacement.fetch("client_user_message_id")
  end

  def test_otp_never_enters_native_envelope_and_pane_less_wait_remains_independent
    request(kind: "otp", otp: otp_context)
    answer("live001", "123456")
    assert_raises(Ace::Hitl::Lifecycle::StateError) { @client.deliver(request: "live001", timeout: 1) }
    assert_empty @native.calls
    assert_empty Dir.glob(File.join(@dir, "deliveries", "**", "*"))
    envelope = @store.read("live001")["envelope"]
    refute envelope.key?("payload_sha256")
    assert_equal "123456", @client.wait(request: "live001", timeout: 1, operation: "gem-push")["answer"]
    assert_equal "not-applicable", @client.status(request: "live001")["delivery"]["state"]
  end

  def test_in_process_watch_keeps_business_effect_receipt_separate_from_native_proof
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
    assert_equal "unknown", @client.status(request: "live001")["delivery"]["state"]
    @client.deliver(request: "live001", timeout: 1)
    @client.reconcile(request: "live001", receipt_path: proof(record))
    assert_equal "x", File.read(marker)
    assert_equal 1, @native.calls.size
  end

  def test_local_consumption_cannot_be_upgraded_to_native_claim_and_missing_signer_fails_closed
    request
    answer
    assert_equal "approved", @client.wait(request: "live001", timeout: 1)["answer"]
    assert_raises(Ace::Hitl::Lifecycle::StateError) { @client.deliver(request: "live001", timeout: 1) }
    assert_empty @native.calls
    request(id: "live002")
    answer("live002")
    unavailable = Ace::Hitl::LiveClient.new(boundary: @boundary, coordinator: @coordinator, inbox: inbox(key: nil))
    assert_raises(Ace::Herdr::ValidationError) { unavailable.deliver(request: "live002", timeout: 1) }
    assert_equal true, @store.read("live002")["native_delivery"]
    assert_empty @native.calls
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
    assert_empty @native.calls
    event = Ace::Hitl::Contract::ManagedEnvelope.inbox_event_id(@store.read("live001")["envelope"])
    assert_nil Ace::Herdr::Molecules::DeliveryRecordStore.load(File.join(@dir, "deliveries"), event)
    # A fresh caller must still use the accepted owner, never the reused pane.
    restarted = Ace::Hitl::LiveClient.new(boundary: @boundary, coordinator: @coordinator, inbox: @inbox)
    assert_raises(Ace::Herdr::Organisms::Inbox::IdentityDriftError) do
      restarted.deliver(request: "live001", timeout: 1)
    end
    assert_empty @native.calls
  end

end
