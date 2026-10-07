# frozen_string_literal: true

require "test_helper"
require "socket"
require_relative "../../support/inbox_context_owner_fixture"

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
    params = {"context_id" => "ctx", "purpose" => "enqueue", "event_id" => "event1", "process_binding" => @normal}
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
