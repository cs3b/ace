# frozen_string_literal: true

require "test_helper"
require "socket"
require_relative "../../support/inbox_context_owner_fixture"
require_relative "../../support/codex_inbox_observation_fixture"

class InboxContextServerTest < Minitest::Test
  include InboxContextOwnerFixture
  Server = Ace::Herdr::Organisms::InboxContextServer
  Wire = Ace::Herdr::Molecules::InboxContextWire

  class PeerKernel < Kernel
    def initialize(peer) = @peer = peer
    def peer(_socket) = @peer
  end

  def exchange(bytes, identity = @normal)
    caller, owner_socket = UNIXSocket.pair
    thread = Thread.new do
      Server.new(owner: @owner, context_id: "ctx", kernel: PeerKernel.new(identity)).handle(owner_socket)
    ensure
      owner_socket.close
    end
    caller.write(bytes)
    caller.close_write
    response = Wire.read(caller, deadline: Wire.deadline)
    thread.value
    response
  ensure
    caller&.close
    owner_socket&.close unless owner_socket&.closed?
  end

  def request(operation, params, identity = @normal)
    exchange(JSON.generate({"version" => 1, "context_id" => "ctx", "operation" => operation, "params" => params}) + "\n", identity)
  end

  def prepare_native_observation
    @observation_native = CodexInboxObservationFixture::Native.new
    @source_inbox = Ace::Herdr::Organisms::Inbox.new(executor: CodexInboxObservationFixture::Pane.new,
      native: @observation_native, deliveries_dir: @events, receipt_public_key: KEY.public_key)
    @source_inbox.enqueue(event: "event1", attempt: "attempt1", ref: {"session" => "ws1", "pane" => "p1"}, payload: "private answer")
    @source_inbox.deliver(event: "event1")
    restart
    operation = begin_operation("observe_to_sign", @signer)
    {"operation_id" => operation.fetch("operation_id"), "key_generation" => 1,
      "event_id" => "event1", "attempt_id" => "attempt1", "claim_generation" => 1}
  end

  def test_native_observation_traverses_authenticated_context_socket_without_settling_or_signing
    params = prepare_native_observation
    before = File.binread(File.join(@events, "event1.json"))
    result = request("observe_context", params, @signer).fetch("result")
    assert_equal "ctx", result.fetch("context_id")
    assert_equal params.fetch("operation_id"), result.fetch("operation_id")
    assert_equal "consumed", result.dig("observation", "outcome")
    assert_equal before, File.binread(File.join(@events, "event1.json"))
    assert_equal 1, @observation_native.sends.size
    refute_includes JSON.generate(result), "private answer"
    refute result.key?("signature")
    assert_equal "ended", request("end_context_operation", params.slice("operation_id"), @signer).dig("result", "state")
  end

  def test_protected_snapshot_supplies_original_native_correlation_without_widening_public_status
    params = prepare_native_observation
    before = File.binread(File.join(@events, "event1.json"))
    snapshot = request("snapshot_context", params.slice("operation_id", "key_generation", "event_id"), @signer).fetch("result")
    retained = JSON.parse(before).fetch("inbox")
    record = snapshot.fetch("record")
    assert_equal retained.fetch("codex_submission"), record.fetch("codex_submission")
    assert_equal retained.fetch("receipt").fetch("codex_submission"), record.fetch("codex_receipt")
    refute record.key?("receipt")
    refute_includes JSON.generate(snapshot), "private answer"
    refute @source_inbox.status(event: "event1").key?("codex_submission")
    assert_equal before, File.binread(File.join(@events, "event1.json"))
    assert_empty @observation_native.reads
    assert_equal "ended", request("end_context_operation", params.slice("operation_id"), @signer).dig("result", "state")
  end

  def test_protected_snapshot_preserves_lost_add_identity_without_inventing_a_queue_receipt
    params = prepare_native_observation
    Ace::Herdr::Molecules::DeliveryRecordStore.with_lock(@events, "event1") do
      record = Ace::Herdr::Molecules::DeliveryRecordStore.load(@events, "event1")
      record = record.advance_inbox(state: "uncertain", inbox: record.inbox.reject { |key, _| key == "receipt" },
        detail: {"action" => "controlled lost add reply"}, timestamp: Time.now.utc.iso8601)
      Ace::Herdr::Molecules::DeliveryRecordStore.save(record, @events)
    end
    snapshot = request("snapshot_context", params.slice("operation_id", "key_generation", "event_id"), @signer).fetch("result")
    assert_equal "uncertain", snapshot.dig("record", "state")
    assert_equal "ace-" + "a" * 32, snapshot.dig("record", "codex_submission", "client_user_message_id")
    assert_nil snapshot.dig("record", "codex_receipt")
    assert_equal "context_blocked", request("snapshot_context", params.slice("operation_id", "key_generation", "event_id"), @normal).dig("error", "code")
    assert_empty @observation_native.reads
  end

  def test_observation_refuses_wrong_peer_generation_selection_and_extra_fields_before_query
    params = prepare_native_observation
    assert_equal "context_blocked", request("observe_context", params, @normal).dig("error", "code")
    [params.merge("key_generation" => 2), params.merge("claim_generation" => 2),
      params.merge("attempt_id" => "other"), params.merge("event_id" => "other"),
      params.merge("outcome" => "consumed")].each do |arguments|
      assert_equal "context_blocked", request("observe_context", arguments, @signer).dig("error", "code")
    end
    assert_empty @observation_native.reads
    assert_equal "delivered", @source_inbox.retained_status(event: "event1").fetch("state")
  end

  def test_retired_context_admission_discards_query_result_and_cannot_rotate_unresolved_record
    params = prepare_native_observation
    @observation_native.on_read = lambda do
      @owner.end_context_operation(operation_id: params.fetch("operation_id"), peer: @signer)
    end
    assert_equal "context_blocked", request("observe_context", params, @signer).dig("error", "code")
    assert_equal 1, @observation_native.reads.size
    assert_raises(ERROR) { begin_rotation }
    assert_equal "delivered", @source_inbox.retained_status(event: "event1").fetch("state")
  end

  def test_direct_enqueue_exact_raw_payload_framing_refuses_before_effect_entry
    @source_inbox = Ace::Herdr::Organisms::Inbox.new(executor: PaneFixture.new, native: NativeFixture.new,
      deliveries_dir: @events, receipt_public_key: KEY.public_key)
    restart
    operation = begin_operation
    payload = "hello"
    params = {"operation_id" => operation.fetch("operation_id"), "key_generation" => 1,
      "event_id" => "event1", "attempt_id" => "attempt1", "original" => direct_original, "payload_bytes" => payload.bytesize,
      "payload_sha256" => Digest::SHA256.hexdigest(payload),
      "reverse" => {"schema" => Ace::Hitl::Providers::Ref::SCHEMA, "session" => "ws1", "pane" => "p1"}}
    frame = ->(arguments) { JSON.generate("version" => 1, "context_id" => "ctx", "operation" => "enqueue_context", "params" => arguments) + "\n" }
    bad = [frame.call(params) + "hell", frame.call(params) + payload + "extra",
      frame.call(params.merge("payload_bytes" => "5")) + payload,
      frame.call(params.merge("payload_bytes" => 65_537)) + payload,
      frame.call(params.merge("payload_sha256" => "0" * 64)) + payload,
      frame.call(params.merge("payload_bytes" => 1, "payload_sha256" => Digest::SHA256.hexdigest("\xff".b))) + "\xff".b,
      frame.call(params.merge("payload_bytes" => 1, "payload_sha256" => Digest::SHA256.hexdigest("\0"))) + "\0",
      frame.call(params.merge("body" => payload)) + payload]
    bad.each do |bytes|
      assert_equal "context_blocked", exchange(bytes).dig("error", "code")
      assert_equal "admitted", begin_operation.fetch("state")
      refute File.exist?(File.join(@events, "event1.json"))
    end
    result = exchange(frame.call(params) + payload).fetch("result")
    assert_equal "ace.herdr.inbox-direct-result/v1", result.fetch("schema")
    assert_equal "idle", result.fetch("admission_state")
    assert_equal "queued", result.dig("record", "state")
  end

  def test_actual_binary_proof_frame_reconciles_only_after_complete_eof
    prepare_reconciliation
    frame = {"version" => 1, "context_id" => "ctx", "operation" => "reconcile_context",
      "params" => {"effect_binding" => @effect_binding, "proof_sizes" => [@signed_bytes.bytesize, @signature.bytesize]}}
    bytes = JSON.generate(frame) + "\n" + @signed_bytes + @signature
    assert_equal "context_blocked", exchange(bytes + "extra").dig("error", "code")
    assert_equal "delivered", @source_inbox.retained_status(event: "event1").fetch("state")
    assert_equal "context_blocked", exchange(bytes.byteslice(0...-1)).dig("error", "code")
    assert_equal "delivered", @source_inbox.retained_status(event: "event1").fetch("state")
    result = exchange(bytes).fetch("result")
    assert_equal "completed", result.fetch("state")
    assert_equal @effect_binding, result.fetch("effect_binding")
    assert_raises(ERROR) { @owner.end_context_operation(operation_id: @effect_binding.fetch("operation_id"), peer: @normal) }
  end

  def test_actual_socket_framing_uses_kernel_peer_and_retains_grant_after_response_disconnect
    params = {"context_id" => "ctx", "purpose" => "enqueue", "event_id" => "event1", "process_binding" => @normal, "original" => direct_original.merge("attempt_id" => "attempt1")}
    first = request("begin_context_operation", params).fetch("result")
    assert_equal first, request("begin_context_operation", params).fetch("result")
    assert_equal 1, @owner.status(peer: @normal).fetch("active_operations")
    assert_equal "context_blocked", request("begin_rotation", {"context_id" => "ctx", "expected_key_generation" => 1}, @maintenance).dig("error", "code")
    assert_equal "ended", request("end_context_operation", {"operation_id" => first.fetch("operation_id")}).dig("result", "state")
    assert request("begin_rotation", {"context_id" => "ctx", "expected_key_generation" => 1}, @maintenance).dig("result", "rotation_id")
  end

  def test_closed_fields_duplicate_json_invalid_utf8_and_oversized_frames_never_admit
    valid = JSON.generate({"version" => 1, "context_id" => "ctx", "operation" => "status", "params" => {}})
    frames = [valid.sub('"version":1', '"version":1,"version":1'), valid + "\xff".b,
      valid.sub('"params":{}', '"params":{"force":true}'), valid.sub('"ctx"', '"other"'),
      valid.sub('"status"', '"provision!"'), valid + "\n" + valid, " " * (Wire::LIMIT + 1)]
    frames.each do |frame|
      result = exchange(frame + "\n")
      assert_equal "context_blocked", result.dig("error", "code")
      assert_equal 0, @owner.status(peer: @normal).fetch("active_operations")
    end
  end

  def test_supplied_signer_binding_cannot_replace_actual_unmapped_peer
    params = {"context_id" => "ctx", "purpose" => "observe_to_sign", "event_id" => "event1", "process_binding" => @signer}
    assert_equal "context_blocked", request("begin_context_operation", params, @normal).dig("error", "code")
    assert_equal 0, @owner.status(peer: @normal).fetch("active_operations")
  end

  def test_real_path_client_authenticates_fixed_owner_incarnation_and_socket
    socket_root = File.realpath(Dir.mktmpdir("ctx-", "/tmp"))
    endpoint = File.join(socket_root, "context.sock")
    listener = UNIXServer.new(endpoint)
    context_peer = peer(505)
    server_kernel = PeerKernel.new(@normal)
    client_kernel = PeerKernel.new(context_peer)
    protection = Object.new
    # Root path/socket OS policy is the only injected installed observation;
    # connect/framing and actual endpoint inode selection stay real.
    protection.define_singleton_method(:root_path!) { |path, directory:, owner:| raise ERROR unless path == socket_root && directory && owner == context_peer["uid"] }
    protection.define_singleton_method(:socket_identity) do |path|
      stat = File.lstat(path)
      raise ERROR unless stat.socket?
      [stat.dev, stat.ino, context_peer["uid"]]
    end
    protection.define_singleton_method(:connect) do |path, deadline:, &block|
      Ace::Runtime::Molecules::ProtectedSocket.connect(path, deadline: deadline, &block)
    end
    worker = Thread.new do
      socket = listener.accept
      Server.new(owner: @owner, context_id: "ctx", kernel: server_kernel).handle(socket)
    ensure
      socket&.close
    end
    client = Ace::Herdr::Molecules::InboxContextClient.new(context_id: "ctx", socket_path: endpoint,
      owner_identity: context_peer, kernel: client_kernel, wire: protection)
    assert_equal "open", client.request("status", {}).fetch("state")
    worker.value
    changed = context_peer.merge("started_at" => context_peer.fetch("started_at").sub(":42", ":43"))
    client = Ace::Herdr::Molecules::InboxContextClient.new(context_id: "ctx", socket_path: endpoint,
      owner_identity: changed, kernel: client_kernel, wire: protection)
    worker = Thread.new { socket = listener.accept; socket.read; socket.close }
    assert_raises(ERROR) { client.request("status", {}) }
    worker.value
  ensure
    listener&.close
    FileUtils.remove_entry(socket_root) if socket_root && File.exist?(socket_root)
  end
end
