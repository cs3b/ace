# frozen_string_literal: true
require_relative "../support/protected_service_boundary_fixture"
require "ace/lab/molecules/protected_cleanup_owner_client"

class ProtectedCleanupDispatchTest < Minitest::Test
  include ProtectedServiceBoundaryFixture

  # Only kernel/root ownership is injected. Content, nofollow held descriptors,
  # lengths, digests and mutation atomicity use their actual source owners.
  class ResultProtection
    def initialize(path) = @path = path
    def root_path!(path)
      raise "unexpected result selection" unless path == @path
    end
    def verify!(path, handle, directory:)
      stat = handle.stat
      raise "wrong held kind" unless directory ? stat.directory? : stat.file?
      raise "unexpected result protection" unless directory || (path == @path && stat.uid == Process.uid && (stat.mode & 0o777) == 0o640)
    end
  end

  def operation_receipt(submission, bytes)
    input = JSON.parse(bytes)
    object = {"device" => 1, "inode" => 2, "worktree_admin_id" => "original", "head" => @head, "branch" => nil}
    {"schema" => "ace.protected-workspace-prune-receipt/v1", "request_id" => submission.fetch("request_id"),
      "input_digest" => submission.fetch("input_digest"), **input.slice("maintenance", "target", "publication"),
      "canonical_snapshots" => [{"mapping_id" => "mapping", "journal_commit" => "a" * 40,
        "binding_event_digest" => "b" * 64, "release_event_digest" => "c" * 64, "proof_event_digest" => "d" * 64}],
      "preservation" => input.fetch("preservation").merge("inventory_sha256" => "e" * 64,
        "file_count" => 0, "total_bytes" => 0, "private_manifest_sha256" => "f" * 64, "archives_sha256" => "0" * 64),
      "removal" => {"original" => object, "captured" => object.dup, "outcome" => "removed", "fence_digest" => "1" * 64}}
  end

  def cleanup_completion(client, submission, claim, operation, result_path, selection_override: nil)
    record = @journal.service_request(submission.fetch("request_id"))
    ref = {"path" => result_path, "bytes" => operation.bytesize, "sha256" => Digest::SHA256.hexdigest(operation)}
    selection = JSON.generate("schema" => "ace.protected-workspace-prune-root-selection/v1",
      "request_id" => submission.fetch("request_id"), "input_digest" => submission.fetch("input_digest"),
      "operation_owner_binding_digest" => Ace::Assign::Atoms::EvidenceDigest.digest(record.fetch("operation_owner_binding")), "receipt_ref" => ref)
    artifacts = [operation, selection_override || selection]
    receipt = record.slice(*Ace::Assign::Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS).merge(
      "outcome" => "succeeded", "evidence" => artifacts.each_with_index.map { |artifact, index| {"ref" => "root-#{index}", "sha256" => Digest::SHA256.hexdigest(artifact)} })
    encoded = JSON.generate(receipt)
    client.call("complete_service", submission.slice("assignment_id", "attempt_id", "candidate_generation", "head", "request_id").merge(
      "claim_binding" => claim.data.fetch("claim_binding"), "receipt_sha256" => Digest::SHA256.hexdigest(encoded)),
      mutation_id: "cleanup-complete", upload_parts: [encoded] + artifacts, purpose: :receipt_artifacts)
  end

  def cleanup_receiver(client, owner)
    executor = @executor
    kernel = Object.new
    kernel.define_singleton_method(:capture) { |_| executor }
    kernel.define_singleton_method(:live!) { |_| true }
    handler = Object.new
    handler.define_singleton_method(:execute) { |**_| raise "cleanup cannot execute an ordinary handler" }
    Ace::Lab::Organisms::ProtectedServiceReceiver.new(mapping_id: "mapping", service_id: "executor",
      deployment: @deployment, kernel: kernel, client: client, handler: handler, cleanup_owner: owner)
  end

  def install_result_reader(path)
    artifacts = Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: ResultProtection.new(path))
    owner = Ace::Assign::Authority::ServiceEvidence.new(journal: @journal, cleanup_artifacts: artifacts)
    @journal.instance_variable_set(:@evidence_reader, ->(*args) { owner.call(*args) })
  end

  def test_actual_receiver_root_socket_result_import_and_dead_root_claim_replay
    fixture do
      submission, bytes = cleanup_submission
      operation = JSON.generate(operation_receipt(submission, bytes))
      path = File.join(@root, "root-result.json")
      File.write(path, operation)
      File.chmod(0o640, path)
      install_result_reader(path)
      original = owner_binding
      wire_class = Ace::Runtime::Molecules::ProtectedSocket
      client_class = Ace::Lab::Molecules::ProtectedCleanupOwnerClient
      ref = {"path" => path, "bytes" => operation.bytesize, "sha256" => Digest::SHA256.hexdigest(operation)}
      executions = []
      observations = []
      alive = true
      observer = Object.new
      observer.define_singleton_method(:observe!) do |socket:, deadline:|
        raise Ace::Runtime::RuntimeUnavailableError, "controlled original root is gone" unless alive
        observations << socket
        original
      end
      root = @root
      server = lambda do |socket|
        frame = wire_class.read(socket, deadline: wire_class.deadline(5), limit: 65_536)
        assert_equal "", socket.read, "root requests retain exact EOF framing"
        if frame.fetch("kind") == "identity"
          assert_equal({"schema" => client_class::SCHEMA, "kind" => "identity"}, frame)
          wire_class.write(socket, {"schema" => client_class::SCHEMA, "kind" => "identity", "operation_owner_binding" => original}, deadline: wire_class.deadline(5))
        else
          assert_equal "execute", frame.fetch("kind")
          assert_equal JSON.parse(bytes), frame.fetch("input")
          assert_equal submission.fetch("input_digest"), frame.fetch("input_digest")
          events = @journal.read_events("assignment")
          request = events.find { |event| event.dig("payload", "operation") == "request_service" }
          dispatch = events.find { |event| event.dig("payload", "operation") == "begin_dispatch" }
          assert_equal request.fetch("digest"), frame.fetch("request_event_digest")
          assert_equal dispatch.fetch("digest"), frame.fetch("dispatch_event_digest")
          assert_equal Ace::Assign::Atoms::EvidenceDigest.digest(original), frame.fetch("operation_owner_binding_digest")
          executions << frame
          wire_class.write(socket, {"schema" => client_class::SCHEMA, "kind" => "result",
            "request_id" => submission.fetch("request_id"), "input_digest" => submission.fetch("input_digest"), "receipt_ref" => ref}, deadline: wire_class.deadline(5))
          codec = Ace::Assign::Authority::TransferCodec.new(root: root)
          codec.send(socket, parts: [operation], descriptor: codec.descriptor([operation], purpose: :artifacts), purpose: :artifacts, deadline: wire_class.deadline(5))
        end
      ensure
        socket.close unless socket.closed?
      end
      wire = Object.new
      wire.define_singleton_method(:deadline) { |seconds| wire_class.deadline(seconds) }
      wire.define_singleton_method(:root_path!) { |selected, directory:| raise "wrong fixed ancestor" unless directory && selected == File.dirname(client_class::PATH) }
      wire.define_singleton_method(:socket_identity) { |selected, mode:| raise "wrong fixed socket" unless selected == client_class::PATH && mode == 0o660; [1, 2, 0] }
      wire.define_singleton_method(:read) { |*args, **options| wire_class.read(*args, **options) }
      wire.define_singleton_method(:write) { |*args, **options| wire_class.write(*args, **options) }
      wire.define_singleton_method(:connect) do |selected, deadline:, &block|
        raise "wrong fixed endpoint" unless selected == client_class::PATH
        local, remote = UNIXSocket.pair
        worker = Thread.new { server.call(remote) }
        begin
          block.call(local)
        ensure
          local.close unless local.closed?
          raise "controlled root endpoint did not finish" unless worker.join(2)
          worker.value
        end
      end
      owner = client_class.new(observer: observer, scratch_root: @root, wire: wire)
      @policy.instance_variable_set(:@cleanup_owner, owner)
      client = start_service_server
      receiver = cleanup_receiver(client, owner)
      Ace::Lab::Molecules::GrantResolver.stub(:trusted_document, @document) do
        result = receiver.execute(submission: submission, peer: @worker, input_bytes: bytes, mutation_id: "receiver-cleanup")
        assert_equal "succeeded", result.fetch("state")
        assert_equal 1, executions.size
        assert_equal 2, @journal.service_request(submission.fetch("request_id")).fetch("receipt").fetch("evidence").size
        before = observations.size
        alive = false
        replay = receiver.execute(submission: submission, peer: @worker, input_bytes: bytes, mutation_id: "receiver-cleanup")
        assert_equal "succeeded", replay.fetch("state")
        assert_equal "retained", replay.fetch("claim")
        assert_equal before, observations.size, "accepted claim replay cannot depend on a new root lifetime"
        assert_equal 1, executions.size, "accepted replay cannot execute root again"
      end
    end
  end

  def test_fresh_receiver_root_identity_failure_keeps_unexecuted_claim_without_dispatch
    fixture do
      submission, bytes = cleanup_submission
      client = start_service_server
      missing = cleanup_receiver(client, nil)
      before = @journal.ref_value
      assert_equal "refused", missing.execute(submission: submission, peer: @worker, input_bytes: bytes, mutation_id: "missing-root").fetch("state")
      assert_equal before, @journal.ref_value
      owner = Object.new
      owner.define_singleton_method(:identity!) { raise Ace::Runtime::RuntimeUnavailableError, "controlled original root unavailable" }
      owner.define_singleton_method(:execute!) { |**_| raise "no executable permission" }
      receiver = cleanup_receiver(client, owner)
      result = receiver.execute(submission: submission, peer: @worker, input_bytes: bytes, mutation_id: "unavailable-root")
      assert_equal "uncertain", result.fetch("state")
      assert_equal "issued", @journal.service_request(submission.fetch("request_id")).fetch("dispatch_phase")
      refute @journal.read_events("assignment").any? { |event| event.dig("payload", "operation") == "begin_dispatch" }
    end
  end

  def test_actual_import_requires_held_original_result_and_history_does_not_reopen_it
    fixture do
      submission, bytes = cleanup_submission
      selected = Object.new
      original = owner_binding
      selected.define_singleton_method(:identity!) { original }
      @policy.instance_variable_set(:@cleanup_owner, selected)
      client = start_service_server
      claim, params = request_and_begin(client, submission, bytes)
      client.call("begin_dispatch", params, mutation_id: "cleanup-begin", upload_parts: [bytes], purpose: :service_input)
      operation = JSON.generate(operation_receipt(submission, bytes))
      result_path = File.join(@root, "root-result.json")
      File.write(result_path, operation)
      File.chmod(0o640, result_path)
      artifacts = Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: ResultProtection.new(result_path))
      owner = Ace::Assign::Authority::ServiceEvidence.new(journal: @journal, cleanup_artifacts: artifacts)
      @journal.instance_variable_set(:@evidence_reader, ->(*args) { owner.call(*args) })
      before = @journal.ref_value
      File.write(result_path, operation.sub('"removed"', '"partial"'))
      assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { cleanup_completion(client, submission, claim, operation, result_path) }
      assert_equal before, @journal.ref_value, "a changed root result cannot partially import completion"
      assert_equal "uncertain", @journal.service_request(submission.fetch("request_id")).fetch("state")
      File.write(result_path, operation)
      owner_digest = Ace::Assign::Atoms::EvidenceDigest.digest(owner_binding)
      selection = {"schema" => "ace.protected-workspace-prune-root-selection/v1", "request_id" => submission.fetch("request_id"),
        "input_digest" => submission.fetch("input_digest"), "operation_owner_binding_digest" => owner_digest,
        "receipt_ref" => {"path" => result_path, "bytes" => operation.bytesize, "sha256" => Digest::SHA256.hexdigest(operation)}}
      malformed_selections = [JSON.generate(selection.merge("operation_owner_binding_digest" => "9" * 64)),
        JSON.generate(selection.merge("receipt_ref" => selection.fetch("receipt_ref").merge("bytes" => operation.bytesize.to_f))),
        JSON.generate(selection).sub('"request_id":', '"request_id":"duplicate","request_id":'), operation]
      malformed_selections.each do |malformed|
        assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
          cleanup_completion(client, submission, claim, operation, result_path, selection_override: malformed)
        end
        assert_equal before, @journal.ref_value, "malformed pair cannot partially accept completion"
      end
      malformed_receipt = operation_receipt(submission, bytes)
      malformed_receipt.fetch("removal").fetch("original")["device"] = 1.0
      malformed_bytes = JSON.generate(malformed_receipt)
      File.write(result_path, malformed_bytes)
      assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
        cleanup_completion(client, submission, claim, malformed_bytes, result_path)
      end
      assert_equal before, @journal.ref_value
      File.write(result_path, operation)
      completed = cleanup_completion(client, submission, claim, operation, result_path)
      assert_equal "succeeded", completed.data.fetch("state")
      record = @journal.service_request(submission.fetch("request_id"))
      assert_equal 2, record.fetch("receipt").fetch("evidence").size
      File.unlink(result_path)
      assert @journal.validate_terminal_receipt!(record, "succeeded", record.fetch("receipt"), pending: {commit: completed.data.fetch("journal_commit")}),
        "historical import provenance does not substitute a new mutable root observation"
    end
  end

  def owner_binding
    {"unit" => "cleanup.service", "invocation_id" => "a" * 32, "entry_sha256" => "b" * 64,
      "process_binding" => {"pid" => 77, "uid" => 0, "gid" => 0, "groups" => [0],
        "started_at" => "linux:boot:900", "host" => "host", "parent_pid" => 1}}
  end

  def cleanup_submission
    submission, = prepared_submission
    tuple = {"project_id" => "project", "mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}
    input = {"schema" => "ace.protected-workspace-prune/v1", "maintenance" => tuple,
      "target" => tuple.merge("resource" => "workspace:project:mapping:assignment", "artifact_digest" => "a" * 64,
        "descriptor_sha256" => "b" * 64, "binding_event_digest" => "c" * 64, "release_event_digest" => "d" * 64, "journal_commit" => "e" * 40),
      "publication" => {"descriptor_sha256" => "f" * 64, "installation_ref" => {"path" => "/etc/lab/installation.json", "bytes" => 1, "sha256" => "0" * 64}},
      "preservation" => {"head" => @head, "branch" => nil, "destinations" => [], "manifest_sha256" => "2" * 64}}
    operation = "prune-preserved-workspace"
    @document.fetch("operations")[operation] = @document.fetch("operations").fetch("publish").dup
    submission = submission.merge("operation" => operation, "input_digest" => Ace::Lab::Atoms::ServiceInput.digest(input),
      "target" => Ace::Lab::Atoms::ServiceInput.target(input))
    @document.fetch("authorizations")["decision"] = @document.fetch("authorizations").fetch("decision").merge(
      "operation" => operation, "input_digest" => submission.fetch("input_digest"), "target" => submission.fetch("target"))
    [submission, JSON.generate(input)]
  end

  def request_and_begin(client, submission, bytes)
    claim = client.call("request_service", submission.merge("service_id" => "executor", "worker_process_binding" => @worker),
      mutation_id: "cleanup-request", upload_parts: [bytes], purpose: :service_input, timeout: 30)
    params = submission.slice("assignment_id", "attempt_id", "head", "candidate_generation", "request_id").merge(
      "claim_binding" => claim.data.fetch("claim_binding"), "expected_generation" => claim.data.fetch("generation"))
    [claim, params]
  end

  def test_actual_client_journal_dispatch_retains_independent_original_owner_and_replay_cannot_issue_again
    fixture do
      submission, bytes = cleanup_submission
      reads = 0
      original = owner_binding
      selected = Object.new
      selected.define_singleton_method(:identity!) { reads += 1; original }
      @policy.instance_variable_set(:@cleanup_owner, selected) # Installed identity boundary is controlled, not the canonical owner.
      client = start_service_server
      claim, params = request_and_begin(client, submission, bytes)
      claim_events = @journal.read_events("assignment", commit: claim.data.fetch("journal_commit"))
      claim_event = claim_events.find { |event| event.dig("payload", "mutation_id") == "cleanup-request" }
      assert_equal claim_event.fetch("digest"), claim.data.fetch("request_event_digest")
      started = client.call("begin_dispatch", params, mutation_id: "cleanup-begin", upload_parts: [bytes], purpose: :service_input)
      assert_equal "permitted", started.data.fetch("invocation")
      assert_equal original, started.data.fetch("operation_owner_binding")
      assert_equal original, @journal.service_request(submission.fetch("request_id")).fetch("operation_owner_binding")
      record = @journal.service_request(submission.fetch("request_id"))
      assert_equal original, Ace::Assign::Authority::ServiceEvidence.new(journal: @journal).context(record).dig(:binding, "operation_owner_binding")
      assert_operator reads, :>=, 2
      events = @journal.read_events("assignment", commit: started.data.fetch("journal_commit"))
      accepted = events.find { |event| event.dig("payload", "operation") == "begin_dispatch" }
      assert_equal original, accepted.dig("payload", "data", "operation_owner_binding")
      assert_equal accepted.fetch("digest"), started.data.fetch("dispatch_event_digest")
      before = reads
      replay = client.call("begin_dispatch", params, mutation_id: "cleanup-begin", upload_parts: [bytes], purpose: :service_input)
      assert replay.replayed
      assert_equal "already_started", replay.data.fetch("invocation")
      assert_equal started.data.fetch("dispatch_event_digest"), replay.data.fetch("dispatch_event_digest")
      claim_replay = client.call("request_service", submission.merge("service_id" => "executor", "worker_process_binding" => @worker),
        mutation_id: "cleanup-request", upload_parts: [bytes], purpose: :service_input)
      assert_equal claim.data.fetch("request_event_digest"), claim_replay.data.fetch("request_event_digest")
      assert_equal claim.data.fetch("journal_commit"), claim_replay.data.fetch("journal_commit")
      assert_equal before, reads, "historical replay cannot reacquire a new root execution permission"
      assert_equal claim.data.fetch("claim_binding"), started.data.fetch("claim_binding")
      canonical = @journal.ref_value
      assert_raises(Ace::Assign::AttemptErrors::Conflict) do
        @journal.mutate(assignment_id: "assignment", attempt_id: @attempt, mutation_id: "changed-root",
          operation: "fixture", parameters_digest: "f" * 64, expected_generation: generation) do
          {data: {}, service_updates: [{request_id: record.fetch("request_id"), expected: record,
            replacement: record.merge("operation_owner_binding" => original.merge("invocation_id" => "c" * 32)), event_type: "service_transition"}]}
        end
      end
      assert_equal canonical, @journal.ref_value
    end
  end

  def test_root_replacement_at_lower_cas_admission_refuses_without_dispatch_event
    fixture do
      submission, bytes = cleanup_submission
      reads = 0
      original = owner_binding
      selected = Object.new
      selected.define_singleton_method(:identity!) do
        reads += 1
        reads == 1 ? original : original.merge("invocation_id" => "c" * 32)
      end
      @policy.instance_variable_set(:@cleanup_owner, selected)
      client = start_service_server
      _, params = request_and_begin(client, submission, bytes)
      before = @journal.ref_value
      error = assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
        client.call("begin_dispatch", params, mutation_id: "cleanup-begin", upload_parts: [bytes], purpose: :service_input)
      end
      assert_includes error.message, "unauthorized"
      assert_equal before, @journal.ref_value
      assert_equal "issued", @journal.service_request(submission.fetch("request_id")).fetch("dispatch_phase")
      refute @journal.service_request(submission.fetch("request_id")).key?("operation_owner_binding")
      @policy.instance_variable_set(:@cleanup_owner, nil)
      assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
        client.call("begin_dispatch", params, mutation_id: "cleanup-missing-owner", upload_parts: [bytes], purpose: :service_input)
      end
      assert_equal before, @journal.ref_value
    end
  end
end
