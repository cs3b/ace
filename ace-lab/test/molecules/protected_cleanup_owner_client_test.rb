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
      wire.define_singleton_method(:root_path!) { |path| raise "arbitrary path" unless path == Client::PATH }
      wire.define_singleton_method(:socket_identity) { |_| [1, 2, 0] }
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
end
