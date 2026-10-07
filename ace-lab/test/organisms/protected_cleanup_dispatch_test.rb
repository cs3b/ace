# frozen_string_literal: true
require_relative "../support/protected_service_boundary_fixture"
require "ace/lab/molecules/protected_cleanup_owner_client"
require "ace/lab/molecules/protected_cleanup_owner_admission"
require "ace/lab/organisms/protected_cleanup_owner"
require "ace/assign/molecules/canonical_read_snapshot"

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
      admission_kernel = Object.new
      executor = @executor
      authority = @service
      replacement = executor.merge("pid" => 99, "started_at" => "linux:#{executor.fetch('started_at').split(':')[1]}:9900")
      admission_kernel.define_singleton_method(:live!) { |peer| raise "foreign observed actor" unless [executor, authority, replacement].include?(peer); true }
      admission = Ace::Lab::Molecules::ProtectedCleanupOwnerAdmission.new(deployment: @deployment,
        authority_id: @deployment.mapping("mapping").fetch("authority_id"), mapping_id: "mapping", service_id: "executor", kernel: admission_kernel)
      private_view = File.join(@root, "root-read-view")
      FileUtils.mkdir_p(private_view, mode: 0o700)
      snapshot = Ace::Assign::Molecules::CanonicalReadSnapshot.new(repo_root: @journal.repo_root,
        checkout_root: @journal.checkout_root, ref: @journal.ref, private_root: private_view)
      observations = []
      alive = true
      observer = Object.new
      observer.define_singleton_method(:observe!) do |socket:, deadline:|
        raise Ace::Runtime::RuntimeUnavailableError, "controlled original root is gone" unless alive
        observations << socket
        original
      end
      observer.define_singleton_method(:observe_self!) do |deadline:|
        raise Ace::Runtime::RuntimeUnavailableError, "controlled original root is gone" unless alive
        original
      end
      transport_peer = executor
      admission_kernel.define_singleton_method(:peer) { |_| transport_peer }
      journal_factory = lambda do |selected|
        service_evidence = nil
        reader = Ace::Assign::Molecules::EvidenceJournal.new(repo_root: @journal.repo_root,
          checkout_root: @journal.checkout_root, ref: @journal.ref, read_boundary: selected, mode: :protected,
          evidence_reader: ->(*args) { service_evidence.call(*args) },
          service_authorizer: ->(*) { raise SecurityError, "root read snapshot cannot authorize journal writes" })
        service_evidence = Ace::Assign::Authority::ServiceEvidence.new(journal: reader)
        reader
      end
      installer = Object.new
      owner = client = active_client = original_request = nil
      test = self
      installer.define_singleton_method(:execute_cleanup!) do |context:, deadline:|
        test.assert_equal JSON.parse(bytes), context.fetch("input")
        test.assert_equal "dispatch_started", context.fetch("record").fetch("dispatch_phase")
        test.assert context.frozen?
        executions << context
        original_client = active_client
        record = context.fetch("record")
        original_request = record.slice("request_id", "input_digest", "claim_binding").merge(
          "request_event_digest" => context.fetch("request_event_digest"),
          "dispatch_event_digest" => context.fetch("dispatch_event_digest"), "input" => context.fetch("input"))
        test.assert_equal "uncertain", client.call("service_status", submission.slice(
          "assignment_id", "attempt_id", "candidate_generation", "head", "request_id")).data.fetch("state")
        test.assert_raises(Ace::Runtime::RuntimeUnavailableError) { owner.execute!(request: original_request, operation_owner_binding: original) }
        begin
          transport_peer = authority
          test.assert_equal original, owner.identity!
          test.assert_raises(SecurityError) { owner.execute!(request: original_request, operation_owner_binding: original) }
          transport_peer = replacement
          test.assert_raises(SecurityError) { owner.execute!(request: original_request, operation_owner_binding: original) }
        ensure
          transport_peer = executor
        end
        # Real socket loss after physical-result production but before reply;
        # the source owner must retain that result without invoking again.
        original_client.close
        {receipt_ref: ref, bytes: operation}
      end
      endpoint = Ace::Lab::Organisms::ProtectedCleanupOwner.new(observer: observer, admission: admission,
        snapshots: ->(&block) { block.call(snapshot) }, journals: journal_factory,
        kernel: admission_kernel, installer: installer, scratch_root: @root)
      server = ->(socket) { endpoint.handle(socket) }
      wire = Object.new
      wire.define_singleton_method(:deadline) { |seconds| wire_class.deadline(seconds) }
      wire.define_singleton_method(:root_path!) { |selected, directory:| raise "wrong fixed ancestor" unless directory && selected == File.dirname(client_class::PATH) }
      wire.define_singleton_method(:socket_identity) { |selected, mode:| raise "wrong fixed socket" unless selected == client_class::PATH && mode == 0o660; [1, 2, 0] }
      wire.define_singleton_method(:read) { |*args, **options| wire_class.read(*args, **options) }
      wire.define_singleton_method(:write) { |*args, **options| wire_class.write(*args, **options) }
      wire.define_singleton_method(:connect) do |selected, deadline:, &block|
        raise "wrong fixed endpoint" unless selected == client_class::PATH
        local, remote = UNIXSocket.pair
        active_client = local
        worker = Thread.new { server.call(remote) }
        worker.report_on_exception = false
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
        # Fixture-only diagnostics identify swallowed typed boundary failures;
        # production responses retain their value-free uncertain projection.
        failures = []
        diagnostic = TracePoint.new(:raise) do |event|
          next unless %w[ace-lab ace-assign ace-runtime].any? { |package| event.path.include?("/#{package}/lib/") }
          error = event.raised_exception
          next unless [Ace::Assign::Error, Ace::Runtime::RuntimeUnavailableError, Ace::Lab::InvalidConfigurationError,
            SecurityError, ArgumentError, KeyError, SystemCallError, Timeout::Error].any? { |type| error.is_a?(type) }
          failures << "#{File.basename(event.path)}:#{event.lineno} #{error.class}: #{error.message.byteslice(0, 160)}"
          failures.shift while failures.size > 16
        end
        begin
          diagnostic.enable
          result = receiver.execute(submission: submission, peer: @worker, input_bytes: bytes, mutation_id: "receiver-cleanup")
        ensure
          diagnostic.disable
        end
        assert_equal "uncertain", result.fetch("state"), "lost root reply cannot become completed"
        record = @journal.service_request(submission.fetch("request_id"))
        assert_equal 1, executions.size, "result=#{result.slice('state', 'reason').inspect}; canonical=#{record&.slice('state', 'dispatch_phase').inspect}; boundary=#{failures.inspect}"
        retained = owner.execute!(request: original_request, operation_owner_binding: original)
        assert_equal operation, retained.fetch(:bytes)
        assert_equal 1, executions.size, "original result reread cannot reinvoke Installer"
        claim = client.call("request_service", submission.merge("service_id" => "executor", "worker_process_binding" => @worker),
          mutation_id: "receiver-cleanup", upload_parts: [bytes], purpose: :service_input)
        assert_equal "retained", claim.data.fetch("claim")
        completed = cleanup_completion(client, submission, claim, operation, path)
        assert_equal "succeeded", completed.data.fetch("state")
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

  def test_actual_receiver_original_inspection_pair_import_and_storage_free_replay
    fixture do
      costs = Hash.new { |hash, key| hash[key] = [0, 0.0] }
      %i[git service_request verify_service_record! service_request_records event_commits! read_events verify_canonical_prefix!].each do |name|
        original_reader = @journal.method(name)
        @journal.define_singleton_method(name) do |*arguments, **keywords, &block|
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          begin
            original_reader.call(*arguments, **keywords, &block)
          ensure
            costs[name][0] += 1
            costs[name][1] += Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
          end
        end
      end
      begin
      submission, bytes = cleanup_submission
      original = owner_binding
      selected = Object.new
      selected.define_singleton_method(:identity!) { original }
      @policy.instance_variable_set(:@cleanup_owner, selected)
      client = start_service_server
      _, params = request_and_begin(client, submission, bytes)
      client.call("begin_dispatch", params, mutation_id: "cleanup-begin", upload_parts: [bytes], purpose: :service_input, timeout: 30)
      @launch.close_execution_scope!(params: {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt,
        "mutation_id" => "inspection-import-seal", "expected_generation" => generation}, peer: @launcher, role: :launcher)
      path = File.join(@root, "root-inspection.json")
      install_result_reader(path)
      executor = @executor
      kernel = Object.new
      kernel.define_singleton_method(:peer) { |_| executor }
      kernel.define_singleton_method(:live!) { |_| true }
      admission = Ace::Lab::Molecules::ProtectedCleanupOwnerAdmission.new(deployment: @deployment,
        authority_id: @deployment.mapping("mapping").fetch("authority_id"), mapping_id: "mapping", service_id: "executor", kernel: kernel)
      alive = true
      observer = Object.new
      observer.define_singleton_method(:observe!) { |socket:, deadline:| raise Ace::Runtime::RuntimeUnavailableError, "controlled root gone" unless alive; original }
      observer.define_singleton_method(:observe_self!) { |deadline:| raise Ace::Runtime::RuntimeUnavailableError, "controlled root gone" unless alive; original }
      inspections = []
      absent = false
      installer = Object.new
      installer.define_singleton_method(:execute_cleanup!) { |**_| raise "recovery cannot execute physical cleanup" }
      installer.define_singleton_method(:inspect_cleanup!) do |context:, deadline:|
        inspections << context
        # Controlled physical facts exercise import plumbing only. The actual
        # same Installer baseline/exclusion producer remains a delivery gap.
        inspection = context.fetch("challenge").fetch("payload").slice("request_id", "input_digest", "claim_binding",
          "no_effect_challenge", "challenge_generation", "failure_event_digest", "failure_generation")
          .merge("version" => 1, "challenge_event_digest" => context.dig("challenge", "digest"),
            "target" => context.dig("record", "target"), "dispatch_phase" => "dispatch_started",
            "effect_absent" => absent, "handler_terminated" => true, "writers_absent" => true)
        output = JSON.generate(inspection)
        File.write(path, output)
        File.chmod(0o640, path)
        {bytes: output, receipt_ref: {"path" => path, "bytes" => output.bytesize, "sha256" => Digest::SHA256.hexdigest(output)}}
      end
      endpoint = Ace::Lab::Organisms::ProtectedCleanupOwner.new(observer: observer, admission: admission,
        snapshots: ->(&block) { block.call(Object.new.tap { |view| view.define_singleton_method(:with) { |deadline:, &consume| consume.call(:original) } }) },
        journals: ->(view) { raise "wrong source snapshot" unless view == :original; @journal }, kernel: kernel, installer: installer, scratch_root: @root)
      wire_class = Ace::Runtime::Molecules::ProtectedSocket
      client_class = Ace::Lab::Molecules::ProtectedCleanupOwnerClient
      wire = Object.new
      wire.define_singleton_method(:deadline) { |seconds| wire_class.deadline(seconds) }
      wire.define_singleton_method(:root_path!) { |selected, directory:| raise "wrong fixed parent" unless directory && selected == File.dirname(client_class::PATH) }
      wire.define_singleton_method(:socket_identity) { |selected, mode:| raise "wrong fixed endpoint" unless selected == client_class::PATH && mode == 0o660; [1, 2, 0] }
      wire.define_singleton_method(:read) { |*args, **options| wire_class.read(*args, **options) }
      wire.define_singleton_method(:write) { |*args, **options| wire_class.write(*args, **options) }
      wire.define_singleton_method(:connect) do |selected_path, deadline:, &consume|
        raise "wrong fixed endpoint" unless selected_path == client_class::PATH
        local, remote = UNIXSocket.pair
        worker = Thread.new { endpoint.handle(remote) }
        begin
          consume.call(local)
        ensure
          local.close unless local.closed?
          raise "inspection endpoint did not finish" unless worker.join(2)
          worker.value
        end
      end
      root_client = client_class.new(observer: observer, scratch_root: @root, wire: wire)
      receiver = cleanup_receiver(client, root_client)
      binding = submission.slice("assignment_id", "attempt_id", "candidate_generation", "head", "request_id")
      expected = generation
      rpc_timings = []
      original_call = client.method(:call)
      client.define_singleton_method(:call) do |operation, *args, **options|
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        previous = costs.transform_values(&:dup)
        begin
          original_call.call(operation, *args, **options)
        ensure
          delta = costs.to_h { |name, (count, duration)| [name, [count - previous.fetch(name, [0, 0.0]).first,
            (duration - previous.fetch(name, [0, 0.0]).last).round(3)]] }
          rpc_timings << [operation, (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at).round(3), delta]
        end
      end
      Ace::Lab::Molecules::GrantResolver.stub(:trusted_document, @document) do
        rejected = receiver.recover_no_effect(binding: binding, input_bytes: bytes, mutation_id: "root-inspection-recovery", expected_generation: expected)
        assert_equal "uncertain", rejected.fetch("state")
        assert_equal "uncertain", @journal.service_request(submission.fetch("request_id")).fetch("state")
        publications = Queue.new
        original_cas = @journal.method(:update_ref_cas)
        @journal.define_singleton_method(:update_ref_cas) do |*arguments|
          accepted = original_cas.call(*arguments)
          publications << arguments.first if accepted
          accepted
        end
        absent = true
        failures = []
        diagnostic = TracePoint.new(:raise) do |event|
          next unless %w[ace-lab ace-assign ace-runtime].any? { |package| event.path.include?("/#{package}/lib/") }
          error = event.raised_exception
          failures << "#{File.basename(event.path)}:#{event.lineno} #{error.class}: #{error.message.byteslice(0, 160)}; #{Array(error.backtrace).first(8).map { |frame| File.basename(frame) }.inspect}"
          failures.shift while failures.size > 16
        end
        begin
          diagnostic.enable
          settled = receiver.recover_no_effect(binding: binding, input_bytes: bytes, mutation_id: "root-inspection-recovery", expected_generation: expected)
        ensure
          diagnostic.disable
        end
        assert_includes %w[uncertain failed-settled], settled.fetch("state")
        terminal_record = Timeout.timeout(45) do
          loop do
            selected_commit = publications.pop
            observed = @journal.service_request(submission.fetch("request_id"), commit: selected_commit)
            break observed if observed.fetch("state") == "failed-settled"
          end
        end
        assert_equal "failed-settled", terminal_record.fetch("state"),
          "CAS timing barrier is not proof; the maintained terminal reader must authenticate the imported pair"
        recovered = receiver.recover_no_effect(binding: binding, input_bytes: bytes, mutation_id: "root-inspection-recovery", expected_generation: expected)
        assert_equal "failed-settled", recovered.fetch("state"), "inspections=#{inspections.size}; rpc=#{rpc_timings.inspect}; boundary=#{failures.inspect}"
        record = @journal.service_request(submission.fetch("request_id"))
        assert_equal 2, record.fetch("receipt").fetch("evidence").size
        assert_equal 2, inspections.size
        File.unlink(path)
        alive = false
        before = @journal.ref_value
        replay = receiver.recover_no_effect(binding: binding, input_bytes: bytes, mutation_id: "root-inspection-recovery", expected_generation: expected)
        assert_equal "failed-settled", replay.fetch("state")
        assert_equal before, @journal.ref_value
        assert_equal 2, inspections.size, "retained terminal receipt cannot reacquire root or mutable result storage"
        view = @journal.service_settlement_read(submission.fetch("request_id"), commit: before)
        assert_equal "failed-settled", view.fetch(:record).fetch("state")
        assert_raises(FrozenError) { view.fetch(:record).fetch("operation").replace("changed") }
        assert_raises(FrozenError) { view.fetch(:read_view).inventory.fetch("events").fetch("assignment").first.fetch("digest").replace("changed") }
        assert_raises(FrozenError) { view.fetch(:read_view).commit = "a" * 40 }
        assert rpc_timings.select { |entry| entry.first == "service_status" }.all? { |entry| entry.last.fetch(:event_commits!, [0]).first == 1 },
          "each actual public status must use one complete operation-owned history walk: #{rpc_timings.inspect}"
        # A new selected head must authenticate history afresh. Changing only
        # original raw event whitespace leaves decoded digests intact, so this
        # specifically targets immutable file OID provenance, not JSON parsing.
        checkout = @journal.send(:checkout_dir)
        event = @journal.read_events("assignment", commit: before).first
        event_path = File.join(checkout, "execution", "assignment", "events", @journal.send(:event_filename, event))
        File.binwrite(event_path, File.binread(event_path) + " ")
        git(checkout, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-am", "changed original event bytes")
        changed = git(checkout, "rev-parse", "HEAD").strip
        assert @journal.update_ref_cas(changed, before)
        assert_equal before, view.fetch(:read_view).commit, "retained read is immutable observation only"
        assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { @journal.service_settlement_read(submission.fetch("request_id")) }
        refused = receiver.recover_no_effect(binding: binding, input_bytes: bytes, mutation_id: "root-inspection-recovery", expected_generation: expected)
        assert_equal "uncertain", refused.fetch("state")
        assert_equal 2, inspections.size, "corrupt current history cannot reacquire root or execute another inspection"
        puts "CLEANUP_RECOVERY_RPC #{rpc_timings.inspect}"
      end
      ensure
        warn "CLEANUP_OWNER_COST #{costs.transform_values { |count, duration| [count, duration.round(3)] }.inspect}; RPC=#{defined?(rpc_timings) && rpc_timings.inspect}"
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

  def test_original_root_inspection_authenticates_actual_challenge_and_supplied_input
    fixture do
      submission, bytes = cleanup_submission
      original = owner_binding
      selected = Object.new
      selected.define_singleton_method(:identity!) { original }
      @policy.instance_variable_set(:@cleanup_owner, selected)
      client = start_service_server
      claim, params = request_and_begin(client, submission, bytes)
      begun = client.call("begin_dispatch", params, mutation_id: "cleanup-begin", upload_parts: [bytes], purpose: :service_input)
      @launch.close_execution_scope!(params: {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt,
        "mutation_id" => "inspection-seal", "expected_generation" => generation}, peer: @launcher, role: :launcher)
      challenged = client.call("claim_service_settlement", submission.slice("assignment_id", "attempt_id", "candidate_generation", "head", "request_id")
        .merge("expected_generation" => generation), mutation_id: "inspection-challenge")
      request_event = @journal.read_events("assignment").find { |event| event.dig("payload", "mutation_id") == "cleanup-request" }
      dispatch_event = @journal.read_events("assignment").find { |event| event.dig("payload", "mutation_id") == "cleanup-begin" }
      selected_status = client.call("service_status", submission.slice("assignment_id", "attempt_id", "candidate_generation", "head", "request_id"))
      execution = selected_status.data.fetch("settlement_context").fetch("execution")
      assert_equal request_event.fetch("digest"), execution.fetch("request_event_digest")
      assert_equal dispatch_event.fetch("digest"), execution.fetch("dispatch_event_digest")
      assert_equal original, execution.fetch("operation_owner_binding")
      assert_equal @executor, execution.fetch("executor_process_binding")
      frame = {"schema" => Ace::Lab::Molecules::ProtectedCleanupOwnerClient::SCHEMA, "kind" => "inspect",
        "request_id" => submission.fetch("request_id"), "input_digest" => submission.fetch("input_digest"), "claim_binding" => claim.data.fetch("claim_binding"),
        "request_event_digest" => request_event.fetch("digest"), "dispatch_event_digest" => dispatch_event.fetch("digest"),
        "operation_owner_binding_digest" => Ace::Assign::Atoms::EvidenceDigest.digest(original), "input" => JSON.parse(bytes),
        "challenge_ref" => challenged.data.fetch("reconciliation_challenge").slice("challenge_event_digest")}
      kernel = Object.new
      executor = @executor
      kernel.define_singleton_method(:peer) { |_| executor }
      kernel.define_singleton_method(:live!) { |_| true }
      admission = Ace::Lab::Molecules::ProtectedCleanupOwnerAdmission.new(deployment: @deployment,
        authority_id: @deployment.mapping("mapping").fetch("authority_id"), mapping_id: "mapping", service_id: "executor", kernel: kernel)
      context = admission.inspect!(frame: frame, peer: executor, operation_owner_binding: original, journal: @journal)
      assert_equal frame.fetch("input"), context.fetch("input")
      assert_equal frame.dig("challenge_ref", "challenge_event_digest"), context.dig("challenge", "digest")
      before = @journal.ref_value
      assert_raises(SecurityError) { admission.inspect!(frame: frame.merge("input" => frame.fetch("input").merge("unknown" => true)), peer: executor, operation_owner_binding: original, journal: @journal) }
      assert_raises(SecurityError) { admission.inspect!(frame: frame.merge("challenge_ref" => {"challenge_event_digest" => "0" * 64}), peer: executor, operation_owner_binding: original, journal: @journal) }
      assert_raises(Ace::Assign::Error) { admission.inspect!(frame: frame.merge("dispatch_event_digest" => "0" * 64), peer: executor, operation_owner_binding: original, journal: @journal) }
      observer = Object.new
      observer.define_singleton_method(:observe_self!) { |deadline:| original }
      inspected = []
      output = "Controlled inspection transport, not physical absence."
      installer = Object.new
      installer.define_singleton_method(:execute_cleanup!) { |**_| raise "inspection cannot execute cleanup" }
      installer.define_singleton_method(:inspect_cleanup!) do |context:, deadline:|
        inspected << context
        {bytes: output, receipt_ref: {"path" => "/fixed/inspection.json", "bytes" => output.bytesize, "sha256" => Digest::SHA256.hexdigest(output)}}
      end
      owner = Ace::Lab::Organisms::ProtectedCleanupOwner.new(observer: observer, admission: admission,
        snapshots: ->(&block) { block.call(Object.new.tap { |view| view.define_singleton_method(:with) { |deadline:, &consume| consume.call(:original) } }) },
        journals: ->(view) { raise "wrong source view" unless view == :original; @journal }, kernel: kernel, installer: installer, scratch_root: @root)
      local, remote = UNIXSocket.pair
      worker = Thread.new { owner.handle(remote) }
      wire = Ace::Runtime::Molecules::ProtectedSocket
      wire.write(local, frame, deadline: wire.deadline(5), limit: 65_536)
      local.shutdown(Socket::SHUT_WR)
      reply = wire.read(local, deadline: wire.deadline(5))
      assert_equal "inspection", reply.fetch("kind")
      ref = reply.fetch("inspection_ref")
      descriptor = {"version" => 1, "bytes" => ref.fetch("bytes"), "sha256" => ref.fetch("sha256"), "parts" => [ref.slice("bytes", "sha256")]}
      Ace::Assign::Authority::TransferCodec.new(root: @root).receive(local, descriptor: descriptor, purpose: :artifacts, deadline: wire.deadline(5)) { |input| assert_equal output, input.bytes }
      worker.value
      assert_equal 1, inspected.size
      assert_equal "inhibited", inspected.first.dig("input_inhibition", "state")
      assert_equal 0, inspected.first.dig("input_inhibition", "pending_effects")
      assert_equal before, @journal.ref_value, "inspection transport cannot mutate canonical state or settle physical absence"
    ensure
      local&.close unless local&.closed?
      remote&.close unless remote&.closed?
      worker&.join(5)
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
