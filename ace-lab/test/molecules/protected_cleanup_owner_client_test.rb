# frozen_string_literal: true
require_relative "../test_helper"
require "etc"
require "ace/lab/molecules/protected_cleanup_owner_client"

class ProtectedCleanupOwnerClientTest < Minitest::Test
  Client = Ace::Lab::Molecules::ProtectedCleanupOwnerClient
  Wire = Ace::Runtime::Molecules::ProtectedSocket

  def binding
    {"unit" => "cleanup.service", "invocation_id" => "a" * 32, "entry_sha256" => "b" * 64,
      "process_binding" => {"pid" => 77, "uid" => 0, "gid" => 0, "groups" => [0],
        "started_at" => "linux:boot:900", "host" => "host", "parent_pid" => 1}}
  end

  def exchange(reply: nil, trailing: nil, server: nil)
    Dir.mktmpdir("cleanup-root-client", Etc.getpwuid(Process.uid).dir) do |root|
      File.chmod(0o700, root)
      local, remote = UNIXSocket.pair
      wire = Object.new
      wire.define_singleton_method(:deadline) { |seconds| Wire.deadline(seconds) }
      wire.define_singleton_method(:root_path!) { |path, directory:| raise "arbitrary path" unless path == File.dirname(Client::PATH) && directory }
      wire.define_singleton_method(:socket_identity) { |_, mode:| raise "wrong fixed mode" unless mode == 0o660; [1, 2, 0] }
      wire.define_singleton_method(:connect) do |_, deadline:, &block|
        begin
          block.call(local)
        ensure
          local.close unless local.closed?
        end
      end
      wire.define_singleton_method(:read) { |*args, **options| Wire.read(*args, **options) }
      wire.define_singleton_method(:write) { |*args, **options| Wire.write(*args, **options) }
      original = binding
      observer = Object.new
      observer.define_singleton_method(:observe!) { |socket:, deadline:| raise "wrong socket" unless socket == local; original }
      client = Client.new(observer: observer, scratch_root: root, wire: wire)
      worker = Thread.new do
        if server
          server.call(remote, root)
          next
        end
        frame = Wire.read(remote, deadline: Wire.deadline(5), limit: Client::LIMIT)
        raise "identity request differs" unless frame == {"schema" => Client::SCHEMA, "kind" => "identity"}
        raise "missing half close" unless remote.read == ""
        Wire.write(remote, reply || {"schema" => Client::SCHEMA, "kind" => "identity", "operation_owner_binding" => original},
          deadline: Wire.deadline(5), limit: Client::LIMIT)
        remote.write(trailing) if trailing
        remote.close
      end
      yield client
      assert worker.join(2), "controlled root endpoint did not finish"
      worker.value
    ensure
      local&.close unless local&.closed?
      remote&.close unless remote&.closed?
      worker&.join(2)
    end
  end

  def test_actual_closed_identity_exchange_matches_independent_observation
    exchange { |client| assert_equal binding, client.identity! }
  end

  def test_changed_root_birth_numeric_type_and_trailing_reply_refuse
    [binding.merge("invocation_id" => "c" * 32),
      binding.merge("process_binding" => binding.fetch("process_binding").merge("pid" => 77.0))].each do |changed|
      exchange(reply: {"schema" => Client::SCHEMA, "kind" => "identity", "operation_owner_binding" => changed}) do |client|
        assert_raises(SecurityError) { client.identity! }
      end
    end
    exchange(trailing: "extra") { |client| assert_raises(SecurityError) { client.identity! } }
  end

  def input
    tuple = {"project_id" => "project", "mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt"}
    {"schema" => "ace.protected-workspace-prune/v1", "maintenance" => tuple,
      "target" => tuple.merge("resource" => "workspace:project:mapping:assignment", "artifact_digest" => "a" * 64,
        "descriptor_sha256" => "b" * 64, "binding_event_digest" => "c" * 64, "release_event_digest" => "d" * 64, "journal_commit" => "e" * 40),
      "publication" => {"descriptor_sha256" => "f" * 64, "installation_ref" => {"path" => "/etc/lab/installation.json", "bytes" => 1, "sha256" => "0" * 64}},
      "preservation" => {"head" => "1" * 40, "branch" => nil, "destinations" => [], "manifest_sha256" => "2" * 64}}
  end

  def execute_request
    {"request_id" => "request", "input_digest" => Ace::Lab::Atoms::ServiceInput.digest(input),
      "claim_binding" => "3" * 64, "request_event_digest" => "4" * 64, "dispatch_event_digest" => "5" * 64, "input" => input}
  end

  def test_inspection_actual_original_input_challenge_half_close_and_bounded_result
    %w[inspection completed-result].each do |reply_kind|
      request = execute_request.merge("challenge_ref" => {"challenge_event_digest" => "6" * 64})
      bytes = "Controlled physical inspection bytes, not an accepted no-effect verdict."
      ref = {"path" => "/fixed/inspection.json", "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
      server = lambda do |socket, root|
        frame = Wire.read(socket, deadline: Wire.deadline(5), limit: 65_536)
        assert_equal request.merge("schema" => Client::SCHEMA, "kind" => "inspect", "operation_owner_binding_digest" => Ace::Assign::Atoms::EvidenceDigest.digest(binding)), frame
        assert_equal "", socket.read
        Wire.write(socket, {"schema" => Client::SCHEMA, "kind" => reply_kind, "request_id" => "request",
          "input_digest" => request.fetch("input_digest"), (reply_kind == "inspection" ? "inspection_ref" : "receipt_ref") => ref}, deadline: Wire.deadline(5))
        codec = Ace::Assign::Authority::TransferCodec.new(root: root)
        codec.send(socket, parts: [bytes], descriptor: codec.descriptor([bytes], purpose: :artifacts), purpose: :artifacts, deadline: Wire.deadline(5))
        socket.close
      end
      exchange(server: server) do |client|
        result = client.inspect!(request: request, operation_owner_binding: binding)
        assert_equal(reply_kind == "inspection" ? "failed-no-effect" : "succeeded", result.fetch(:kind))
        assert_equal bytes, result.fetch(:bytes)
        assert_equal ref, result.fetch(:receipt_ref)
        assert result.frozen?
        assert result.fetch(:receipt_ref).frozen?
      end
    end
  end

  def test_inspection_unknown_mixed_and_oversized_results_refuse_before_body
    request = execute_request.merge("challenge_ref" => {"challenge_event_digest" => "6" * 64})
    ref = {"path" => "/fixed/result.json", "bytes" => 1, "sha256" => "a" * 64}
    base = {"schema" => Client::SCHEMA, "kind" => "completed-result", "request_id" => "request",
      "input_digest" => request.fetch("input_digest"), "receipt_ref" => ref}
    [base.merge("kind" => "unknown"), base.merge("inspection_ref" => ref),
      base.merge("receipt_ref" => ref.merge("bytes" => 65_537)),
      base.merge("receipt_ref" => ref.merge("bytes" => 0)), base.merge("input_digest" => "b" * 64)].each do |reply|
      server = lambda do |socket, _|
        Wire.read(socket, deadline: Wire.deadline(5), limit: 65_536)
        assert_equal "", socket.read
        Wire.write(socket, reply, deadline: Wire.deadline(5))
        socket.close
      end
      exchange(server: server) do |client|
        error = !reply.dig("receipt_ref", "bytes").between?(1, 65_536) ? ArgumentError : SecurityError
        assert_raises(error) { client.inspect!(request: request, operation_owner_binding: binding) }
      end
    end
  end

  def test_execute_actual_frame_half_close_and_bounded_exact_result_bytes
    bytes = "bounded controlled operation result"
    ref = {"path" => "/var/lib/lab/results/request.json", "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
    server = lambda do |socket, root|
      frame = Wire.read(socket, deadline: Wire.deadline(5))
      assert_equal execute_request.merge("schema" => Client::SCHEMA, "kind" => "execute",
        "operation_owner_binding_digest" => Ace::Assign::Atoms::EvidenceDigest.digest(binding)), frame
      assert_equal "", socket.read
      Wire.write(socket, {"schema" => Client::SCHEMA, "kind" => "result", "request_id" => "request",
        "input_digest" => execute_request.fetch("input_digest"), "receipt_ref" => ref}, deadline: Wire.deadline(5))
      codec = Ace::Assign::Authority::TransferCodec.new(root: root)
      codec.send(socket, parts: [bytes], descriptor: codec.descriptor([bytes], purpose: :artifacts), purpose: :artifacts, deadline: Wire.deadline(5))
      socket.close
    end
    exchange(server: server) do |client|
      result = client.execute!(request: execute_request, operation_owner_binding: binding)
      assert_equal ref, result.fetch(:receipt_ref)
      assert_equal bytes, result.fetch(:bytes)
      assert result.fetch(:receipt_ref).frozen?
      assert result.fetch(:bytes).frozen?
    end
  end

  def test_replaced_execute_owner_refuses_before_any_root_request
    server = ->(socket, _) { assert_equal "", socket.read; socket.close }
    exchange(server: server) do |client|
      assert_raises(SecurityError) do
        client.execute!(request: execute_request, operation_owner_binding: binding.merge("invocation_id" => "c" * 32))
      end
    end
  end

  def test_ancillary_descriptor_in_identity_or_later_result_body_refuses
    %i[identity execute].each do |kind|
      server = lambda do |socket, root|
        Wire.read(socket, deadline: Wire.deadline(5))
        assert_equal "", socket.read
        File.open(File.join(root, "sender-file"), "w+") do |held|
          if kind == :identity
            bytes = JSON.generate("schema" => Client::SCHEMA, "kind" => "identity", "operation_owner_binding" => binding) + "\n"
          else
            bytes = "bounded result"
            ref = {"path" => "/var/lib/lab/results/request.json", "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
            Wire.write(socket, {"schema" => Client::SCHEMA, "kind" => "result", "request_id" => "request",
              "input_digest" => execute_request.fetch("input_digest"), "receipt_ref" => ref}, deadline: Wire.deadline(5))
          end
          socket.sendmsg(bytes, 0, nil, Socket::AncillaryData.unix_rights(held))
          refute held.closed?, "rejecting received rights must not close sender ownership"
        end
        socket.close
      end
      exchange(server: server) do |client|
        assert_raises(SecurityError) do
          kind == :identity ? client.identity! : client.execute!(request: execute_request, operation_owner_binding: binding)
        end
      end
    end
  end

  def test_real_group_connect_socket_has_protected_parent_without_leaf_write_rejection
    Dir.mktmpdir("cleanup-root-endpoint", Etc.getpwuid(Process.uid).dir) do |root|
      File.chmod(0o700, root)
      path = File.join(root, "owner.sock")
      listener = UNIXServer.new(path)
      File.chmod(0o660, path)
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { Wire.root_path!(path, owner: Process.uid) }
      original = binding
      observer = Object.new
      observer.define_singleton_method(:observe!) { |**_| original } # Root identity/DAC is the explicit controlled boundary.
      wire = Object.new
      wire.define_singleton_method(:root_path!) do |selected, directory: false|
        actual = selected == Client::PATH ? path : root
        Wire.root_path!(actual, directory: directory, owner: Process.uid)
      end
      wire.define_singleton_method(:socket_identity) do |_, **options|
        identity = Wire.socket_identity(path, **options)
        [identity[0], identity[1], 0] # Only root UID observation is injected.
      end
      wire.define_singleton_method(:connect) { |_, deadline:, &block| Wire.connect(path, deadline: deadline, &block) }
      %i[read write deadline].each { |method| wire.define_singleton_method(method) { |*args, **options| Wire.public_send(method, *args, **options) } }
      worker = Thread.new do
        peer = listener.accept
        Wire.read(peer, deadline: Wire.deadline(5))
        assert_equal "", peer.read
        Wire.write(peer, {"schema" => Client::SCHEMA, "kind" => "identity", "operation_owner_binding" => original}, deadline: Wire.deadline(5))
        peer.close
      end
      client = Client.new(observer: observer, scratch_root: root, wire: wire)
      assert_equal original, client.identity!
      assert worker.join(2)
      worker.value
      File.chmod(0o666, path)
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { client.identity! }
    ensure
      listener&.close
      worker&.join(2)
    end
  end
end
