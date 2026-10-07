# frozen_string_literal: true
require_relative "../../test_helper"
require_relative "../../support/endcap_result_owner_fixture"
require_relative "../../support/service_no_effect_owner_fixture"
require_relative "../../support/execution_boot_baseline_owner_fixture"
require_relative "../../support/protected_inbox_context_pipeline_fixture"
require "ace/assign/authority/deployment_history"
require "ace/herdr/organisms/inbox"
require "ace/assign/cli/commands/authority/launch"
require_relative "../../support/original_launch_driver_owner_fixture"

module Ace
  module Assign
    # Canonical owners and protected held-byte loaders are real. Installed UID,
    # filesystem installation checks and native observation are controlled seams.
    class HistoricalRotationTest < AceAssignTestCase
      include OriginalLaunchDriverOwnerFixture
      include EndcapResultOwnerFixture
      include ServiceNoEffectOwnerFixture
      include ProtectedInboxContextPipelineFixture
      include ExecutionBootBaselineOwnerFixture

      class Protection
        def root_path!(_); true; end
        def verify!(_, handle, directory:)
          raise "wrong fixture artifact type" unless directory ? handle.stat.directory? : handle.stat.file?
        end
      end
      Parts = Struct.new(:parts) do
        def count; parts.size; end
        def bytes(index: 0); parts.fetch(index); end
      end
      class Scope < ExecutionScopeNativeOwnerFixture
        attr_reader :retirements
        def initialize(*args, **kwargs)
          super(*args, **kwargs)
          @retirements = 0
        end
        def activate_parent!(context)
          binding = super
          selected = Ace::Runtime::Molecules::ExecutionBootBaseline.new.select!(expected:
            binding.slice("slot_id", "boot_id", "deployment_digest").merge(
              "installer_artifact" => binding.fetch("network_installation_selection").fetch("installer_artifact")))
          binding.merge("boot_baseline_selection" => selected.fetch("selection"))
        end
        def verify_maintenance_closed!(lineages)
          lineages.each { |lineage| verify_closed!(lineage) }
          true
        end
        def retire_released_parent!(lineages)
          verify_maintenance_closed!(lineages)
          @retirements += 1
          {"state" => "retired"}
        end
      end

      def with_installed_boundaries
        methods = {
          verify!: ->(id, **) { mapping(id) },
          verify_composition!: ->(*, **) { true },
          verify_receiver_paths!: ->(*) { true },
          verify_inbox_context!: ->(mapping_id, context_id) { inbox_context(mapping_id, context_id) },
          verify_inbox_acl!: ->(*, **) { true }
        }
        originals = methods.to_h { |name, _| [name, Authority::Deployment.instance_method(name)] }
        private_methods = methods.keys.select { |name| Authority::Deployment.private_method_defined?(name) }
        methods.each { |name, body| Authority::Deployment.define_method(name, body) }
        private_methods.each { |name| Authority::Deployment.send(:private, name) }
        baseline_factory = -> { fixture_boot_baseline_reader(protection: Protection.new,
          pointers: {"/etc/ace/execution-slots/slot/boot-baseline-selection.json" => @boot_pointer}) }
        Ace::Runtime::Molecules::ExecutionBootBaseline.stub(:new, baseline_factory) { fixture { yield } }
      ensure
        stop_context_pipeline
        originals&.each { |name, body| Authority::Deployment.define_method(name, body) }
        private_methods&.each { |name| Authority::Deployment.send(:private, name) }
        @launch&.close
      end

      def artifact(name, bytes)
        path = File.join(@root, name)
        File.binwrite(path, bytes)
        {"path" => path, "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}
      end

      def load_fixed
        factory = lambda do
          reader = Ace::Runtime::Molecules::ProtectedArtifactSet.allocate
          reader.send(:initialize, protection: Protection.new)
          held_read = reader.method(:read_path!)
          selected = @fixed_selections
          reader.define_singleton_method(:read_path!) do |path, limit:|
            bytes, reference = held_read.call(selected.fetch(path), limit: limit)
            [bytes, reference.merge("path" => path.dup.freeze).freeze]
          end
          reader
        end
        Ace::Runtime::Molecules::ProtectedArtifactSet.stub(:new, factory) do
          [Authority::Deployment.load, Authority::DeploymentHistory.load]
        end
      end

      def configure_result_owner_fixture
        repo = @journal.repo_root
        @socket_root = File.realpath(Dir.mktmpdir("inbox-h-", @foreground_socket_root ? Etc.getpwuid(Process.uid).dir : "/tmp"))
        @context_clients = {}
        @authority_peer = @kernel.capture(Process.pid)
        @context_peer = @kernel.capture(23007).merge("uid" => 13007, "gid" => 13007, "groups" => [13007])
        @service = @service.merge("socket_path" => File.join(@socket_root, "query.sock"))
        @service = @service.merge("state_root" => File.join(@root, "authority-state"))
        Dir.mkdir(@service.fetch("state_root"), 0700)
        @key = OpenSSL::PKey::RSA.new(2048)
        key_ref = artifact("original-public.pem", @key.public_to_pem)
        @next_key = OpenSSL::PKey::RSA.new(2048)
        next_key_ref = artifact("candidate-public.pem", @next_key.public_to_pem)
        @published_key = File.join(@root, "current-public.pem")
        File.binwrite(@published_key, @key.public_to_pem)
        deliveries = File.join(@root, "deliveries")
        Dir.mkdir(deliveries, 0700)
        @context = {"deliveries_dir" => deliveries, "receipt_public_key" => @published_key,
          "control_socket_path" => File.join(@socket_root, "context.sock"), "owner_credentials" => {"uid" => 13007, "gid" => 13007, "groups" => [13007]},
          "native_mapping_id" => "mapping", "supervisor_uids" => [13004],
          "pi_queue_client" => "/fixture/pi", "pi_queue_client_sha256" => "a" * 64}
        @map = @map.merge("worker_argv" => ["/usr/bin/true", "authority", "worker"], "worker_env" => {"PATH" => "/usr/bin"},
          "execution_scope" => @map.fetch("execution_scope").merge("backend" => "linux_systemd_cgroup_v2",
            "slice_unit" => "ace-slot.slice", "unit_manifest_sha256" => "b" * 64,
            "boundary_manifest_sha256" => "c" * 64, "root_directory" => "/var/lib/ace-slot/root", "runtime_directory" => "/run/ace-slot"),
          "native" => @map.fetch("native").merge("socket_path" => "/fixture/herdr.sock", "executable" => "/fixture/herdr",
            "version" => "0.9.3", "protocol" => 22, "executable_sha256" => "e" * 64))
        @project = @project.merge("journal_repository" => repo, "evidence_git_ref" => @journal.ref,
          "evidence_checkout_root" => @journal.checkout_root, "candidate_root" => File.join(@root, "candidates"),
          "launcher_uids" => [13002], "worker_uids" => [13001],
          "service_receivers" => {"executor" => {"executor_uid" => 13005, "socket_path" => "/fixture/service.sock", "staging_root" => "/fixture/staging"}},
          "inbox_contexts" => {"inbox" => @context})
        @project["peer_credentials"] = [@worker, @launcher, @reviewer, @executor, @supervisor].to_h do |peer|
          [peer.fetch("uid").to_s, peer.slice("gid", "groups").merge("scratch_root" => File.join(@root, "scratch-#{peer.fetch('uid')}"))]
        end
        @project.fetch("peer_credentials").each_value { |entry| FileUtils.mkdir_p(entry.fetch("scratch_root"), mode: 0700) }
        value = {"schema" => "ace.assign.authorities/v2", "authorities" => {"authority" => @service.slice("uid", "gid", "groups", "socket_path", "state_root").merge("composition" => "services")},
          "projects" => {"project" => @project}, "launch_mappings" => {"mapping" => @map}}
        if @inventory_mapping
          other = JSON.parse(JSON.generate(@map))
          other.merge!("worker_uid" => 13006, "worker_gid" => 13006, "worker_groups" => [13006], "worker_cwd" => "/home/other", "worker_actor" => "other-worker")
          other.fetch("execution_scope").merge!("slot_id" => "other-slot", "service_unit" => "ace-other.service", "slice_unit" => "ace-other.slice",
            "root_directory" => "/var/lib/ace-other/root", "runtime_directory" => "/run/ace-other", "network_namespace_path" => "/run/netns/other")
          other.fetch("native").merge!("workspace_id" => "w2", "socket_path" => "/fixture/herdr-other.sock")
          value.fetch("launch_mappings")["mapping-other"] = other
          @project.fetch("worker_uids") << 13006
          @project.fetch("peer_credentials")["13006"] = {"gid" => 13006, "groups" => [13006], "scratch_root" => File.join(@root, "scratch-13006")}
        end
        @original_ref = artifact("original.json", JSON.generate(value))
        rotated = JSON.parse(JSON.generate(value))
        rotated["launch_mappings"]["mapping"]["worker_actor"] = "rotated-worker"
        @candidate_ref = artifact("candidate.json", JSON.generate(rotated))
        @manifest_ref = artifact("history.json", JSON.generate("schema" => "ace.assign.deployment-history/v1",
          "original_descriptor" => @original_ref, "candidate_descriptor" => @candidate_ref,
          "descriptors" => [@original_ref, @candidate_ref], "public_keys" => [{"ref" => key_ref,
            "public_key_sha256" => Digest::SHA256.hexdigest(@key.public_key.to_der)},
            {"ref" => next_key_ref, "public_key_sha256" => Digest::SHA256.hexdigest(@next_key.public_key.to_der)}]))
        @published = File.join(@root, "published.json")
        File.binwrite(@published, File.binread(@original_ref.fetch("path")))
        @fixed_selections = {Authority::Deployment::PATH => @published, Authority::DeploymentHistory::PATH => @manifest_ref.fetch("path")}
        @deployment, @history = load_fixed
        @map = @deployment.mapping("mapping")
        installer = artifact("original-installer", "controlled original installer bytes")
        @network_selection = ExecutionScopeObservationFixtures::NETWORK_SELECTION.merge("installer_artifact" => installer)
        @network_installation = ExecutionScopeObservationFixtures::NETWORK_OUTPUT.merge("installer_artifact_sha256" => installer.fetch("sha256"))
        @boot_ref = retained_boot_baseline_artifact(root: @root, name: "original-boot.json", map: @map, installer: installer)
        @candidate_boot_ref = retained_boot_baseline_artifact(root: @root, name: "candidate-boot.json", map: @history.candidate.mapping("mapping"), installer: installer)
        @boot_pointer = artifact("boot-pointer.json", JSON.generate("schema" => "ace.execution-boot-selection/v1", "slot_id" => "slot", "baseline" => @boot_ref)).fetch("path")
        owner = nil
        @journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: @journal.ref, checkout_root: @journal.checkout_root,
          mode: :protected, evidence_reader: ->(*args) { owner.call(*args) },
          service_authorizer: ->(existing, replacement, pending) {
            @endcap.authorize_service_update!(journal: @journal, existing: existing, replacement: replacement, pending: pending) })
        owner = Authority::ServiceEvidence.new(journal: @journal)
      end

      def restart
        @scope = nil
        @launch = Authority::LaunchLifecycle.new(deployment: @deployment, deployment_history: @history,
          kernel: @kernel, journals: {"project" => @journal}, scope_observer_factory: ->(_) {
            @scope ||= Scope.new(@map, @journal, @kernel, owner: @launch, network_selection: @network_selection,
              boot_baseline_selection: @boot_ref, network_installation: @network_installation) })
        @launch.define_singleton_method(:verify_maintenance_root!) { |*| true }
        @endcap = Authority::Endcap.new(deployment: @deployment, launch: @launch, kernel: @kernel,
          service_policy: @policy, inbox_context_clients: @context_clients, deployment_history: @history)
        @router = Authority::Router.new(launch: @launch, handlers: [@endcap])
      end

      def refresh_candidate_boot!
        File.binwrite(@boot_pointer, JSON.generate("schema" => "ace.execution-boot-selection/v1", "slot_id" => "slot", "baseline" => @candidate_boot_ref))
        expected = {"slot_id" => "slot", "boot_id" => ExecutionScopeObservationFixtures::BOOT,
          "deployment_digest" => Digest::SHA256.hexdigest(JSON.generate(Authority::LaunchLifecycle.allocate.send(:canonical, @map))),
          "installer_artifact" => @network_selection.fetch("installer_artifact")}
        assert_equal @candidate_boot_ref, Ace::Runtime::Molecules::ExecutionBootBaseline.new.select!(expected: expected).fetch("selection")
        @boot_ref = @candidate_boot_ref
      end

      def test_candidate_boot_refresh_selects_actual_published_candidate_mapping
        with_installed_boundaries do
          original = @boot_ref
          File.binwrite(@published, File.binread(@candidate_ref.fetch("path")))
          @deployment, @history = load_fixed
          @map = @deployment.mapping("mapping")
          expected = {"slot_id" => "slot", "boot_id" => ExecutionScopeObservationFixtures::BOOT,
            "deployment_digest" => Digest::SHA256.hexdigest(JSON.generate(Authority::LaunchLifecycle.allocate.send(:canonical, @map))),
            "installer_artifact" => @network_selection.fetch("installer_artifact")}
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { Ace::Runtime::Molecules::ExecutionBootBaseline.new.select!(expected: expected) }
          refresh_candidate_boot!
          refute_equal original, @boot_ref
          assert_equal @candidate_ref.fetch("sha256"), @deployment.artifact_reference.fetch("sha256")
        end
      end

      def current_events
        @journal.read_events("assignment").select { |event| event["attempt_id"] == @attempt }
      end

      def settle_service(no_effect: false)
        review = call("assign_review", {"head" => @head, "candidate_generation" => 1, "expected_generation" => generation,
          "reviewer_uid" => @reviewer.fetch("uid"), "reviewer_process_binding" => @reviewer},
          id: "review", peer: @launcher, role: :launcher).fetch(:data)
        _, _, receipt = upload(parts: ["review report"])
        receipt.merge!("operation" => "review", "review" => {"head" => @head, "verdict" => "approved", "reviewer" => {"actor" => review.fetch("reviewer_actor")}})
        params, input, = upload(parts: ["review report"], receipt: receipt)
        call("accept_review", params.merge("purpose_id" => review.fetch("review_id")), id: "accept-review", peer: @reviewer, role: :reviewer, transfer: input)
        body = "exact service input"
        input_digest = Digest::SHA256.hexdigest(body)
        @policy.define_singleton_method(:input_binding) do |bytes, expected_digest:, expected_target:, operation:|
          raise "wrong original operation" unless operation == "publish"
          raise "wrong policy input" unless bytes == body && expected_digest == input_digest && expected_target == {"resource" => "fixture"}
        end
        @policy.define_singleton_method(:prepare!) do |binding, input_bytes:|
          raise "wrong policy input" unless input_bytes == body && binding.fetch("input_digest") == input_digest
          {binding: binding.merge("executor_uid" => 13005, "transport" => "unix"), policy_digest: "f" * 64}
        end
        transfer = Authority::TransferCodec.new(root: @root).descriptor([body], purpose: :service_input)
        params = {"head" => @head, "candidate_generation" => 1, "expected_generation" => generation, "request_id" => "service-request",
          "operation" => "publish", "input_digest" => input_digest, "target" => {"resource" => "fixture"}, "authorization" => "review",
          "service_id" => "executor", "worker_process_binding" => @worker, "transfer" => transfer}
        claim = call("request_service", params, id: "service-claim", peer: @executor, role: :executor, transfer: Parts.new([body])).fetch(:data)
        begin_params = params.slice("head", "candidate_generation", "request_id", "transfer").merge("expected_generation" => generation, "claim_binding" => claim.fetch("claim_binding"))
        call("begin_dispatch", begin_params, id: "service-begin", peer: @executor, role: :executor, transfer: Parts.new([body]))
        record = @journal.service_request("service-request")
        return record if no_effect
        evidence = "ace-service-attestation request:service-request input:#{input_digest} outcome:succeeded\nactual executor source receipt"
        receipt = record.slice(*Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS).merge("outcome" => "succeeded",
          "evidence" => [{"ref" => "private-executor-evidence", "sha256" => Digest::SHA256.hexdigest(evidence)}])
        bytes = JSON.generate(receipt)
        parts = [bytes, evidence]
        params = begin_params.except("expected_generation").merge("receipt_sha256" => Digest::SHA256.hexdigest(bytes),
          "transfer" => Authority::TransferCodec.new(root: @root).descriptor(parts, purpose: :receipt_artifacts))
        call("complete_service", params, id: "service-complete", peer: @executor, role: :executor, transfer: Parts.new(parts))
        assert_equal "succeeded", @journal.service_request("service-request").fetch("state")
      end

      def settle_inbox
        terminal_id = @binding.fetch("terminal_id")
        executor = Object.new
        executor.define_singleton_method(:pane_get_bounded) do |*|
          Ace::Herdr::Molecules::ExecutionResult.new(stdout: JSON.generate("result" => {"pane" => {
            "pane_id" => "p1", "workspace_id" => "w1", "terminal_id" => terminal_id, "agent" => "codex", "agent_status" => "busy",
            "agent_session" => {"agent" => "codex", "kind" => "id", "value" => "0123abcd-0000-4000-8000-000000000001"}}}), stderr: "", success: true, exit_code: 0)
        end
        native = Object.new
        native.define_singleton_method(:submit) { |**| {"accepted" => true} }
        @box = Ace::Herdr::Organisms::Inbox.new(executor: executor, native: native,
          deliveries_dir: @context.fetch("deliveries_dir"), receipt_public_key: @key.public_key)
        @box.enqueue(event: "event", attempt: @attempt, ref: {"session" => "w1", "pane" => "p1"}, payload: "message")
        record = @box.deliver(event: "event")
        registration = record.slice(*Authority::Endcap::INBOX_REGISTRATION_FIELDS)
        @journal.mutate(assignment_id: "assignment", attempt_id: @attempt, mutation_id: "register-inbox", operation: "fixture_registration",
          parameters_digest: "a" * 64, expected_generation: generation) do
          {data: {}, events: [{type: "inbox_binding", payload: {"event_id" => "event", "attempt_id" => @attempt,
            "inbox_context_id" => "inbox", "registration" => registration}}]}
        end
        receipt = record.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding").merge("outcome" => "consumed",
          "observer" => {"role" => "supervisor", "id" => "observer"},
          "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => "native:1", "observation" => "consumed"})
        bytes = JSON.generate(receipt)
        signature = @key.sign(OpenSSL::Digest::SHA256.new, bytes)
        parts = [bytes, signature]
        start_context_pipeline(@root, context_id: "inbox", installed: true)
        @router = Authority::Router.new(launch: @launch, handlers: [@endcap, @query_owner])
        params = {"event_id" => "event", "inbox_context_id" => "inbox", "expected_registration" => registration, "expected_generation" => generation,
          "receipt_sha256" => Digest::SHA256.hexdigest(bytes), "signature_sha256" => Digest::SHA256.hexdigest(signature),
          "transfer" => Authority::TransferCodec.new(root: @root).descriptor(parts, purpose: :inbox_proof)}
        yield if block_given?
        assert_equal "completed", call("reconcile_inbox", params, id: "consume", peer: @supervisor, role: :supervisor, transfer: Parts.new(parts)).dig(:data, "state")
      end

      def accept_terminal_and_release
        submit
        submitted = current_events.find { |event| event["type"] == "result_submitted" }.fetch("payload")
        params = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}
        @launch.close_execution_scope!(params: params.merge("mutation_id" => "seal", "expected_generation" => generation), peer: @launcher, role: :launcher)
        @launch.close_execution_scope!(params: params.merge("mutation_id" => "proof", "expected_generation" => generation), peer: @launcher, role: :launcher)
        binding = submitted.fetch("binding")
        canonical = Molecules::CanonicalEvidence.new(journal: @journal)
        reader = ->(_, artifact) { canonical.read({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
          kind: "result", project_id: "project", assignment_id: "assignment", attempt_id: @attempt, peer_uid: 13001,
          binding: binding, request_id_or_event_id: binding.fetch("result_id"), generation: binding.fetch("candidate_generation")) }
        coordinator = Organisms::AttemptCoordinator.new(cache_base: File.join(@root, "terminal-cache"), repo_root: @journal.repo_root,
          journal: @journal, verifier: Molecules::ReceiptVerifier.new(artifact_reader: reader), lifecycle_exclusion: @launch.send(:exclusion_for, @map, @journal))
        path = File.join(@root, "terminal-receipt.json")
        File.write(path, JSON.generate(submitted.fetch("receipt")))
        identity = Molecules::ExecutionIdentityResolver::Identity.new(actor: "fixture-operator", role: "coordinator", runtime: "local")
        assert_equal "succeeded", coordinator.finish(attempt_id: @attempt, receipt_path: path, identity: identity).state
        release = @launch.release_scope_reservation!(params: params.merge("mutation_id" => "release", "expected_generation" => generation), peer: @launcher, role: :launcher)
        terminal = current_events.find { |event| event["type"] == "receipt_accepted" }
        assert_equal terminal.fetch("digest"), release.dig(:data, "terminal_event_id")
      end

      def with_original_control
        server_socket, driver_socket = UNIXSocket.pair
        wire = Ace::Runtime::Molecules::ProtectedSocket
        codec = Authority::TransferCodec.new(root: @root)
        selection = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}
        server = Thread.new do
          @launch.serve_launch_control!(request: {"mutation_id" => nil, "params" => selection}, peer: @launcher,
            socket: server_socket, codec: codec, deadline: wire.deadline(5))
        rescue Ace::Runtime::RuntimeUnavailableError, AttemptErrors::EvidenceUnavailable, IOError
          nil
        end
        ready = wire.read(driver_socket, deadline: wire.deadline(5))
        assert_equal "launch_control_ready", ready.fetch("type")
        origin = current_events.find { |event| event["type"] == "authority_mutation" &&
          event.dig("payload", "operation") == "record_launch" }.dig("payload", "data", "guarded_origin")
        yield driver_socket, codec, ready, origin
      ensure
        driver_socket&.close
        server_socket&.close
        server&.join
      end

      def read_original_control_frame(socket, deadline:)
        wire = Ace::Runtime::Molecules::ProtectedSocket
        loop do
          frame = wire.read(socket, deadline: deadline)
          return frame unless frame["type"] == "launch_control_idle"
          wire.write(socket, {"version" => 1, "type" => "launch_control_idle_ack", "nonce" => frame.fetch("nonce")}, deadline: deadline)
        end
      end

      def test_unknown_context_preserves_original_containment_and_recovery_prerequisites
        with_installed_boundaries do
          selection = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}
          wire = Ace::Runtime::Molecules::ProtectedSocket
          body = +"controlled original input"
          state = @launch.send(:origin, current_events, mapping_id: "mapping", assignment_id: "assignment", attempt_id: @attempt)
          gate_server, gate_worker = UNIXSocket.pair
          begin
            gate = Thread.new do
              @launch.gate_ready(request: {"params" => {"mapping_id" => "mapping", "launch_ticket" => state.fetch("launch_ticket")}},
                peer: @worker, socket: gate_server, deadline: wire.deadline(10))
            end
            assert_equal "ready", wire.read(gate_worker, deadline: wire.deadline(10)).dig("data", "phase")
            call("release_launch", {"launch_ticket" => state.fetch("launch_ticket"), "process_binding" => @binding,
              "expected_generation" => generation}, id: "issued-for-recovery", peer: @launcher, role: :launcher)
            assert_equal "release", wire.read(gate_worker, deadline: wire.deadline(10)).fetch("operation")
            gate.value
          ensure
            gate_server.close; gate_worker.close
            gate&.join
          end
          with_original_control do |socket, codec, ready, original|
            reporter = Thread.new do
              frame = read_original_control_frame(socket, deadline: wire.deadline(30))
              codec.receive_launch_prompt(socket, descriptor: frame.fetch("text_descriptor"), transfer_id: frame.fetch("transfer_id"),
                deadline: wire.deadline(10)) { |input| assert_equal body, input.bytes }
              wire.write(socket, frame.slice("mutation_id", "intent_event_id", "original_binding_digest").merge(
                "version" => 1, "type" => "prompt_dispatch_outcome", "guarded_evidence" => {"outcome" => "uncertain", "origin" => original}),
                deadline: wire.deadline(10))
              wire.read(socket, deadline: wire.deadline(10))
            end
            prompt = @launch.prompt_attempt!(request: {"mutation_id" => "prior-prompt", "params" => selection.merge(
              "expected_generation" => generation, "transfer" => codec.descriptor([body], purpose: :prompt_text))},
              peer: @launcher, role: :launcher, transfer: Struct.new(:bytes).new(body))
            assert_equal "uncertain", prompt.dig(:data, "outcome")
            reporter.value
          end
          lost_completion = false
          error = assert_raises(AttemptErrors::EvidenceUnavailable) do
            settle_inbox do
              read = @context_query_wire.method(:read)
              @context_query_wire.define_singleton_method(:read) do |*args, **options|
                read.call(*args, **options)
                lost_completion = true
                raise Ace::Herdr::ValidationError, "fixture lost original canonical completion ACK"
              end
            end
          end
          causes = []; cause = error
          while cause && causes.size < 6
            causes << "#{cause.class}: #{cause.message}"
            cause = cause.cause
          end
          assert lost_completion, causes.join("; ")
          assert_equal 1, @context_owner.status(peer: @authority_peer).fetch("active_operations")
          before = current_events
          failure = assert_raises(AttemptErrors::InboxContextPending) do
            @launch.prompt_attempt!(request: {"mutation_id" => "blocked-prompt", "params" => selection.merge(
              "expected_generation" => generation, "transfer" => Authority::TransferCodec.new(root: @root).descriptor([body], purpose: :prompt_text))},
              peer: @launcher, role: :launcher, transfer: Struct.new(:bytes).new(body))
          end
          assert_match(/pending context effect/, failure.message)
          assert_equal before, current_events
          with_original_control do |socket, _codec, ready, original|
            drainer = Thread.new do
              frame = read_original_control_frame(socket, deadline: wire.deadline(30))
              selected = @launch.launch_input_inhibit_selection!(request: {"mutation_id" => nil, "params" => selection.merge(
                frame.slice("original_binding_digest", "seal_event_id", "journal_commit"))}, peer: @launcher, role: :launcher)
              assert_equal frame.fetch("seal_event_id"), selected.dig(:data, "seal_event_id")
              wire.write(socket, frame.slice("original_binding_digest", "seal_event_id").merge("version" => 1,
                "type" => "launch_input_inhibit_outcome", "guarded_evidence" => {"outcome" => "inhibited", "origin" => original,
                  "input_state" => "inhibited", "pending_input" => 0}), deadline: wire.deadline(30))
              recorded = wire.read(socket, deadline: wire.deadline(30))
              assert_equal "launch_input_inhibit_recorded", recorded.fetch("type")
            end
            intent = @journal.prompt_intent("prior-prompt")
            completion = @launch.launch_prompt_completion!(request: {"mutation_id" => nil, "params" => selection.merge(
              "mutation_id" => "prior-prompt", "intent_event_id" => intent.fetch("digest"),
              "original_binding_digest" => ready.fetch("original_binding_digest"), "guarded_evidence" => {
                "outcome" => "not_issued", "origin" => original, "phase" => "not_issued", "code" => "agent_blocked"})},
              peer: @launcher, role: :launcher)
            assert_equal "not_issued", completion.dig(:data, "outcome")
            assert_equal "uncertain", @journal.mutation_result("prior-prompt").dig("data", "outcome")
            @launch.close_execution_scope!(params: selection.merge("mutation_id" => "unknown-seal", "expected_generation" => generation),
              peer: @launcher, role: :launcher)
            drainer.value
            assert current_events.any? { |event| event["type"] == "input_inhibited" }
          end
          closed = @launch.close_execution_scope!(params: selection.merge("mutation_id" => "unknown-proof", "expected_generation" => generation),
            peer: @launcher, role: :launcher)
          assert_equal "closed_no_writers", closed.dig(:data, "state")
          assert_equal "closed_no_writers", @launch.observe_execution_scope!(params: selection, peer: @launcher, role: :launcher).fetch("state")
          failure = assert_raises(AttemptErrors::InboxContextPending) do
            @launch.release_scope_reservation!(params: selection.merge("mutation_id" => "unknown-release", "expected_generation" => generation),
              peer: @launcher, role: :launcher)
          end
          assert_match(/pending context effect/, failure.message)
          assert_equal 1, @context_owner.status(peer: @authority_peer).fetch("active_operations")
        end
      end

      def stop_terminal_and_release(uncertain: false)
        params = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}
        if uncertain
          coordinator = Organisms::AttemptCoordinator.new(cache_base: File.join(@root, "stopped-cache"), repo_root: @journal.repo_root,
            journal: @journal, lifecycle_exclusion: @launch.send(:exclusion_for, @map, @journal))
          observer = Object.new
          observer.define_singleton_method(:observe) { |_| {"liveness" => "unknown", "reason" => "controlled interrupted native observation"} }
          coordinator.send(:reconciler).instance_variable_set(:@observer, observer)
          assert_equal "uncertain", coordinator.reconcile(attempt_id: @attempt).state
        end
        expected_state = uncertain ? "uncertain" : "running"
        assert_equal expected_state, @journal.canonical_attempt_state(current_events)
        first_params = params.merge("expected_generation" => generation)
        first = call("stop_attempt", first_params, id: "public-stop-seal", peer: @supervisor, role: :supervisor)
        assert_equal "uncertain", first.dig(:data, "state")
        assert_equal expected_state, @journal.canonical_attempt_state(current_events)
        proof = call("stop_attempt", params.merge("expected_generation" => generation), id: "public-stop-proof", peer: @supervisor, role: :supervisor)
        assert proof.dig(:data, "proof_id")
        final_params = params.merge("expected_generation" => generation)
        stopped = call("stop_attempt", final_params, id: "public-stop-terminal", peer: @supervisor, role: :supervisor)
        assert_equal "stopped", stopped.dig(:data, "state")
        assert_nil stopped.dig(:data, "required_action")
        assert_equal "stopped", @journal.canonical_attempt_state(current_events)
        terminal = current_events.find { |event| event["type"] == "attempt_stopped" }
        assert_equal current_events.select { |event| event["type"] == "service_transition" && event.dig("payload", "state") == "succeeded" }.map { |event| event.fetch("digest") }.sort,
          terminal.dig("payload", "service_settlement_event_digests")
        assert_equal current_events.select { |event| event["type"] == "inbox_reconciliation" && event.dig("payload", "state") == "completed" }.map { |event| event.fetch("digest") }.sort,
          terminal.dig("payload", "inbox_settlement_event_digests")
        prior = @journal.ref_value
        restarted_peer = @supervisor.merge("pid" => 98, "started_at" => "linux:#{ExecutionScopeObservationFixtures::BOOT}:98")
        assert_equal stopped.fetch(:data), call("stop_attempt", final_params, id: "public-stop-terminal", peer: restarted_peer, role: :supervisor).fetch(:data)
        assert_equal prior, @journal.ref_value
        assert_equal first.fetch(:data), call("stop_attempt", first_params, id: "public-stop-seal", peer: @supervisor, role: :supervisor).fetch(:data)
        release = @launch.release_scope_reservation!(params: params.merge("mutation_id" => "stopped-release", "expected_generation" => generation), peer: @launcher, role: :launcher)
        assert_equal terminal.fetch("digest"), release.dig(:data, "terminal_event_id")
      end

      def test_actual_inventory_server_requires_current_permission_eof_and_a_canonical_ref
        @foreground_socket_root = true
        with_installed_boundaries do
          server_kernel = StreamKernel.new(@kernel, me: @service, peer: @launcher)
          client_kernel = StreamKernel.new(@kernel, me: @launcher, peer: @service)
          server = Authority::Server.new(authority_id: "authority", lifecycle: @router, deployment: @deployment,
            composition: "services", kernel: server_kernel)
          listener = Thread.new { server.serve }
          deadline = WIRE.deadline(3)
          until File.socket?(@service.fetch("socket_path"))
            raise "Source listener unavailable" unless listener.alive? && Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
            sleep(0.01)
          end
          client = Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: client_kernel)
          definition = JSON.generate(JSON.parse(@journal.blob(@journal.mutation_result("register").dig("data", "definition_ref"))).merge("session_id" => "assignment-page"))
          prepared = PreparedRegistrationFixture.build(root: @root, definition: JSON.parse(definition), scope: "010")
          client.call("register_assignment", prepared.header(expected_generation: 0), mutation_id: "inventory-page-register", timeout: 30,
            upload_parts: [prepared.bundle], purpose: :candidate)
          query = {"journal_commit" => nil, "after" => nil, "limit" => 1}
          first = client.call("assignment_inventory", query, timeout: 30).data
          assert first.fetch("next_after")
          selected = @journal.ref_value
          server_kernel.instance_variable_set(:@peer, @worker)
          client_kernel.instance_variable_set(:@me, @worker)
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            client.call("assignment_inventory", query.merge("journal_commit" => first.fetch("journal_commit"), "after" => first.fetch("next_after")), timeout: 30)
          end
          assert_equal selected, @journal.ref_value
          server_kernel.instance_variable_set(:@peer, @launcher)
          client_kernel.instance_variable_set(:@me, @launcher)
          final = client.call("assignment_inventory", query.merge("journal_commit" => first.fetch("journal_commit"), "after" => first.fetch("next_after")), timeout: 30).data
          assert_equal "assignment-page", final.fetch("items").first.fetch("assignment_id")
          assert_nil final.fetch("next_after")
          request = {"version" => 1, "project_id" => "project", "operation" => "assignment_inventory", "mutation_id" => nil,
            "params" => query.merge("mapping_id" => "mapping")}
          socket = nil
          [request, request.merge("project_id" => "foreign")].each_with_index do |frame, index|
            socket = UNIXSocket.new(@service.fetch("socket_path"))
            WIRE.write(socket, frame, deadline: WIRE.deadline(5))
            socket.write("extra") if index.zero?
            socket.shutdown(Socket::SHUT_WR)
            assert_equal "error", WIRE.read(socket, deadline: WIRE.deadline(10)).fetch("status")
            socket.close
            assert_equal selected, @journal.ref_value
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("assignment_inventory", query, mutation_id: "forbidden-query-mutation", timeout: 30) }
          history, error, status = Open3.capture3("git", "-C", @journal.repo_root, "rev-list", "--first-parent", selected)
          assert status.success?, error
          empty = client.call("assignment_inventory", query.merge("journal_commit" => history.lines.last.strip), timeout: 30).data
          assert_empty empty.fetch("items")
          assert_nil empty.fetch("next_after")
          _out, error, status = Open3.capture3("git", "-C", @journal.repo_root, "update-ref", "-d", @journal.ref, selected)
          assert status.success?, error
          assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("assignment_inventory", query, timeout: 30) }
          assert_nil @journal.ref_value # Discovery never seeds a missing ref.
        ensure
          Open3.capture3("git", "-C", @journal.repo_root, "update-ref", @journal.ref, selected) if selected && @journal.ref_value.nil?
          socket&.close unless socket&.closed?
          server&.stop
          listener&.join(3)
          refute listener&.alive?, "source listener must terminate"
        end
      end

      def test_actual_original_foreground_cli_exits_only_after_authenticated_stopped_release
        @foreground_socket_root = true
        @inventory_mapping = true
        with_installed_boundaries do
          # Free the fixture seed through its actual imported receipt owner.
          seed_attempt = @attempt
          accept_terminal_and_release
          seed_terminal = current_events.find { |event| event["type"] == "receipt_accepted" }.fetch("digest")
          seed_release = current_events.find { |event| event.dig("payload", "operation") == "scope_reservation_release" }.fetch("digest")
          # A third completed row comes from the real guarded pre-release abort
          # owner, not copied terminal flags or fabricated receipt evidence.
          guarded = call("reserve_attempt", {"scope" => "010", "worker_uid" => 13001, "runtime" => "herdr", "base_head" => @head,
            "launcher_process_binding" => @launcher, "expected_generation" => 1}, id: "inventory-guarded-reserve", peer: @launcher, role: :launcher).fetch(:data)
          @attempt = guarded.fetch("attempt_id")
          guarded_attempt = @attempt
          guarded_params = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}
          @launch.close_execution_scope!(params: guarded_params.merge("mutation_id" => "inventory-guarded-seal", "expected_generation" => generation), peer: @launcher, role: :launcher)
          @launch.close_execution_scope!(params: guarded_params.merge("mutation_id" => "inventory-guarded-proof", "expected_generation" => generation), peer: @launcher, role: :launcher)
          guarded_lineage = Molecules::ExecutionScopeLineage.new(events: current_events, project_id: "project", **guarded_params.transform_keys(&:to_sym))
          failure = JSON.generate("kind" => "protected_scope_before_release", "scope_generation" => guarded_lineage.binding.fetch("scope_generation"),
            "scope_binding_event_id" => guarded_lineage.binding_event.fetch("digest"), "seal_event_id" => guarded_lineage.seal_event.fetch("digest"), "proof_id" => guarded_lineage.proof_id)
          aborted = call("abort_launch", {"launch_ticket" => guarded.fetch("launch_ticket"), "expected_generation" => generation,
            "failure_evidence" => failure, "failure_digest" => Digest::SHA256.hexdigest(failure)}, id: "inventory-guarded-abort", peer: @launcher, role: :launcher).fetch(:data)
          assert_equal "failed", aborted.fetch("phase")
          guarded_terminal = current_events.find { |event| event.dig("payload", "operation") == "abort_launch" }.fetch("digest")
          guarded_release = current_events.find { |event| event.dig("payload", "operation") == "scope_reservation_release" }.fetch("digest")
          original_assignment = @journal.mutation_result("register").fetch("data")
          definition = @journal.blob(original_assignment.fetch("definition_ref"))
          native = OriginalGuardedNative.new(mapping: @map.merge("native" => @map.fetch("native").merge(
            "server_identity" => @kernel.capture(90), "socket_identity" => [1, 2, 13001])), kernel: @kernel)
          server_kernel = StreamKernel.new(@kernel, me: @service, peer: @launcher)
          client_kernel = StreamKernel.new(@kernel, me: @launcher, peer: @service)
          server = Authority::Server.new(authority_id: "authority", lifecycle: @router, deployment: @deployment,
            composition: "services", kernel: server_kernel)
          listener = Thread.new { server.serve }
          limit = WIRE.deadline(3)
          until File.socket?(@service.fetch("socket_path"))
            raise "Source listener unavailable" unless listener.alive? && Process.clock_gettime(Process::CLOCK_MONOTONIC) < limit
            sleep(0.01)
          end
          @deployment.project("project").fetch("peer_credentials").each_value do |credential|
            FileUtils.mkdir_p(credential.fetch("scratch_root"), mode: 0700)
            File.chmod(0700, credential.fetch("scratch_root"))
          end
          client = Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: client_kernel)
          recorded, statuses, ready = Queue.new, Queue.new, Queue.new
          status_durations, inventory_durations = [], []
          original_call = client.method(:call)
          client.define_singleton_method(:call) do |operation, params, **options|
            status_started = Process.clock_gettime(Process::CLOCK_MONOTONIC) if operation == "attempt_status"
            inventory_started = Process.clock_gettime(Process::CLOCK_MONOTONIC) if operation == "assignment_inventory"
            result = original_call.call(operation, params, **options)
            inventory_durations << Process.clock_gettime(Process::CLOCK_MONOTONIC) - inventory_started if inventory_started
            status_durations << Process.clock_gettime(Process::CLOCK_MONOTONIC) - status_started if status_started
            recorded << result.data if operation == "record_launch"
            statuses << result.data if operation == "attempt_status"
            result
          end
          gate_socket, worker_socket = UNIXSocket.pair
          gate = Thread.new do
            state = recorded.pop
            @launch.gate_ready(request: {"params" => {"mapping_id" => "mapping", "launch_ticket" => state.fetch("launch_ticket")}},
              peer: @worker, socket: gate_socket, deadline: WIRE.deadline(30))
          end
          driver = Authority::LaunchDriver.new(mapping_id: "mapping", deployment: @deployment, kernel: client_kernel, client: client, native: native)
          command = CLI::Commands::Authority::Launch.new
          command.define_singleton_method(:build_driver) { |_| driver }
          definition_path = File.join(@root, "foreground-definition.json")
          bundle_path = File.join(@root, "foreground-prepared.bundle")
          File.binwrite(bundle_path, @prepared_registration.bundle)
          File.binwrite(definition_path, definition)
          output = StringIO.new
          output.define_singleton_method(:write) do |line|
            count = super(line)
            ready << JSON.parse(line)
            count
          end
          previous_stdout = $stdout
          $stdout = output
          foreground = Thread.new do
            command.call(mapping: "mapping", assignment: "assignment", definition: definition_path, prepared_bundle: bundle_path,
              step: "010", base_head: @head, mutation: "foreground-stop-owner")
          rescue StandardError => error
            ready << error
            raise
          end
          frame = Timeout.timeout(45) { ready.pop }
          raise frame if frame.is_a?(Exception)
          @attempt = frame.fetch("attempt_id")
          assert_equal "launch_ready", frame.fetch("type")
          assert_equal "ready", WIRE.read(worker_socket, deadline: WIRE.deadline(5)).dig("data", "phase")
          assert_equal "release", WIRE.read(worker_socket, deadline: WIRE.deadline(5)).fetch("operation")
          params = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}
          first = client.call("stop_attempt", params.merge("expected_generation" => generation), mutation_id: "foreground-stop-seal", timeout: 90)
          assert_equal "uncertain", first.data.fetch("state")
          proof = client.call("stop_attempt", params.merge("expected_generation" => generation), mutation_id: "foreground-stop-proof", timeout: 90)
          assert proof.data.fetch("proof_id")
          stopped = client.call("stop_attempt", params.merge("expected_generation" => generation), mutation_id: "foreground-stop-terminal", timeout: 90)
          assert_equal "stopped", stopped.data.fetch("state")
          @launch.instance_variable_get(:@control_channels).values.each(&:close)
          unreleased = Timeout.timeout(45) do
            loop do
              status = statuses.pop
              break status if status["state"] == "stopped" && status["reservation_release_event_id"].nil?
            end
          end
          assert_equal frame.fetch("original_binding_digest"), unreleased.fetch("original_binding_digest")
          assert unreleased.fetch("terminal_event_id")
          assert foreground.alive?, "terminal without release cannot terminate original driver"
          terminal_inventory = client.call("assignment_inventory", {"journal_commit" => nil, "after" => nil, "limit" => 25}, timeout: 30).data
          terminal_row = terminal_inventory.fetch("items").find { |row| row["attempt_id"] == @attempt }
          assert_equal "stopped", terminal_row.fetch("canonical_state")
          assert_equal unreleased.fetch("terminal_event_id"), terminal_row.fetch("terminal_event_id")
          assert_nil terminal_row.fetch("reservation_release_event_id")
          released = @launch.release_scope_reservation!(params: params.merge("mutation_id" => "foreground-release", "expected_generation" => generation),
            peer: @launcher, role: :launcher)
          foreground.join(45)
          refute foreground.alive?, "authenticated status under its unchanged 30s deadline must release foreground driver"
          assert_nil foreground.value
          refute_empty status_durations
          assert status_durations.all? { |elapsed| elapsed < 30 }, status_durations.inspect
          assert_equal 1, output.string.lines.length
          assert_equal 1, native.drain_calls.length
          assert_nil native.prompt_calls
          observed_release = Timeout.timeout(2) do
            loop do
              status = statuses.pop
              break status if status["reservation_release_event_id"]
            end
          end
          assert_equal released.dig(:data, "terminal_event_id"), observed_release.fetch("terminal_event_id")
          assert_equal "stopped", observed_release.fetch("state")
          inventory = client.call("assignment_inventory", {"journal_commit" => frame.fetch("journal_commit"), "after" => nil, "limit" => 25}, timeout: 30).data
          original_ready = inventory.fetch("items").find { |row| row["attempt_id"] == frame.fetch("attempt_id") }
          assert_equal frame.fetch("generation"), original_ready.fetch("generation")
          assert_equal frame.fetch("original_binding_digest"), original_ready.fetch("original_binding_digest")
          assert_nil original_ready.fetch("terminal_event_id")
          assert_nil original_ready.fetch("reservation_release_event_id")
          # A new process with the same installed launcher credentials may
          # discover canonical terminal metadata, but not use private old birth.
          restarted_peer = @launcher.merge("pid" => 33333, "started_at" => "linux:#{ExecutionScopeObservationFixtures::BOOT}:33333")
          server_kernel.instance_variable_set(:@peer, restarted_peer)
          client_kernel.instance_variable_set(:@me, restarted_peer)
          current_inventory = client.call("assignment_inventory", {"journal_commit" => nil, "after" => nil, "limit" => 25}, timeout: 30).data
          assert inventory_durations.all? { |elapsed| elapsed < 30 }, inventory_durations.inspect
          seed_row = current_inventory.fetch("items").find { |row| row["attempt_id"] == seed_attempt }
          assert_equal "succeeded", seed_row.fetch("canonical_state")
          assert_equal seed_terminal, seed_row.fetch("terminal_event_id")
          assert_equal seed_release, seed_row.fetch("reservation_release_event_id")
          guarded_row = current_inventory.fetch("items").find { |row| row["attempt_id"] == guarded_attempt }
          assert_equal "failed", guarded_row.fetch("canonical_state")
          assert_equal guarded_terminal, guarded_row.fetch("terminal_event_id")
          assert_equal guarded_release, guarded_row.fetch("reservation_release_event_id")
          stopped_row = current_inventory.fetch("items").find { |row| row["attempt_id"] == frame.fetch("attempt_id") }
          assert_equal "stopped", stopped_row.fetch("canonical_state")
          assert_equal observed_release.fetch("terminal_event_id"), stopped_row.fetch("terminal_event_id")
          assert_equal observed_release.fetch("reservation_release_event_id"), stopped_row.fetch("reservation_release_event_id")
          assert_equal frame.fetch("original_binding_digest"), stopped_row.fetch("original_binding_digest")
          assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("attempt_status", params.merge("result_candidate_generation" => nil), timeout: 30) }
          require "ace/overseer"
          other_client = Authority::Client.new(mapping_id: "mapping-other", deployment: @deployment, kernel: client_kernel)
          other_definition = JSON.generate(JSON.parse(definition).merge("session_id" => "other-assignment"))
          prepared = PreparedRegistrationFixture.build(root: @root, definition: JSON.parse(other_definition), scope: "010")
          other_client.call("register_assignment", prepared.header(expected_generation: 0), mutation_id: "other-inventory-register", timeout: 30,
            upload_parts: [prepared.bundle], purpose: :candidate)
          public_agents = %w[mapping mapping-other].map { |id| {"id" => id, "project" => "project", "role" => "coder", "capabilities" => ["coding"],
            "binding" => {"kind" => "runtime", "state" => "active", "instance_id" => "controlled-#{id}", "attested_instance_id" => "controlled-#{id}"}} }
          topology = Ace::Lab::Organisms::TopologyService.from_config("schema_version" => 1,
            "authorization" => {"principals" => {Ace::Lab::Molecules::CallerAuthorizer.local_identity.first => {"projects" => ["project"]}}},
            "topology" => {"projects" => [{"id" => "project"}], "services" => [], "agents" => public_agents})
          protected_status = Ace::Overseer::Organisms::ProtectedStatus.new(topology: topology, deployment_loader: -> { @deployment },
            client_factory: ->(id, selected) { Authority::Client.new(mapping_id: id, deployment: selected, kernel: client_kernel) })
          joined = protected_status.join_ready!(project: "project", agent: "mapping", ready: frame)
          assert_equal frame.fetch("journal_commit"), joined.fetch("journal_commit")
          assert_equal original_ready, joined.fetch("item")
          [frame.merge("generation" => frame.fetch("generation") + 1), frame.merge("original_binding_digest" => "f" * 64),
            frame.merge("attempt_id" => "foreign"), frame.merge("journal_commit" => @head)].each do |wrong|
            assert_raises(Ace::Overseer::Error) { protected_status.join_ready!(project: "project", agent: "mapping", ready: wrong) }
          end
          status_command = Ace::Overseer::CLI::Commands::Status.new(protected_status: protected_status, config: {"runtime" => "tmux"})
          status_output = capture_io { status_command.call(format: "json", project: "project") }.first
          coordinator_status = JSON.parse(status_output)
          assert_equal "complete", coordinator_status.fetch("visibility")
          assert_equal 2, coordinator_status.fetch("provisioned_capacity")
          assert_equal %w[mapping mapping-other], coordinator_status.fetch("agents").map { |agent| agent.fetch("agent_id") }
          actual_row = coordinator_status.fetch("agents").first.fetch("inventory").fetch("items").find { |row| row["attempt_id"] == @attempt }
          assert_equal stopped_row, actual_row
          registration_only = coordinator_status.fetch("agents").last.fetch("inventory").fetch("items").first
          assert_equal "other-assignment", registration_only.fetch("assignment_id")
          assert_nil registration_only.fetch("attempt_id")
          assert_nil registration_only.fetch("generation")
          original_ref = @journal.ref_value
          %w[attempt_stopped scope_reservation_release].each do |kind|
            @journal.send(:sync_checkout, original_ref)
            selected_event = current_events.find { |event| event["type"] == kind || event.dig("payload", "operation") == kind }
            checkout = @journal.send(:checkout_dir)
            path = File.join(checkout, "execution", "assignment", "events", @journal.send(:event_filename, selected_event))
            bytes = File.binread(path)
            File.unlink(path)
            git(checkout, "add", "-A", "execution/assignment")
            git(checkout, "-c", "user.name=test", "-c", "user.email=test@localhost", "commit", "-m", "controlled removed #{kind}")
            File.binwrite(path, bytes)
            git(checkout, "add", "-A", "execution/assignment")
            git(checkout, "-c", "user.name=test", "-c", "user.email=test@localhost", "commit", "-m", "controlled reintroduced #{kind}")
            altered_ref = git(checkout, "rev-parse", "HEAD")
            git(@journal.repo_root, "update-ref", @journal.ref, altered_ref, original_ref)
            assert Models::EvidenceEvent.chain_valid?(current_events), "current intact chain must not hide invalid introduction history"
            assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("assignment_inventory", {"journal_commit" => nil, "after" => nil, "limit" => 25}, timeout: 30) }
            assert_equal altered_ref, @journal.ref_value
            git(@journal.repo_root, "update-ref", @journal.ref, original_ref, altered_ref)
          end
        ensure
          $stdout = previous_stdout if previous_stdout
          driver&.request_control_cancel
          foreground&.join(3)
          server&.stop
          listener&.join(3)
          gate_socket&.close
          worker_socket&.close
          gate&.kill if gate&.alive?
        end
      end

      def test_actual_no_effect_producer_composes_pending_stop_terminal_and_original_release
        with_installed_boundaries do
          settle_service(no_effect: true)
          settle_inbox
          params = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}
          @launch.close_execution_scope!(params: params.merge("mutation_id" => "no-effect-seal", "expected_generation" => generation),
            peer: @launcher, role: :launcher)
          closed = @launch.close_execution_scope!(params: params.merge("mutation_id" => "no-effect-proof", "expected_generation" => generation),
            peer: @launcher, role: :launcher)
          assert_equal "closed_no_writers", closed.dig(:data, "state")
          pending_params = params.merge("expected_generation" => generation)
          pending = call("stop_attempt", pending_params, id: "pending-no-effect-stop", peer: @supervisor, role: :supervisor)
          assert_equal "uncertain", pending.dig(:data, "state")
          assert_equal "settle_services", pending.dig(:data, "required_action")
          assert_equal "running", @journal.canonical_attempt_state(current_events)
          assert_empty current_events.select { |event| event["type"] == "attempt_stopped" }
          challenge = call("claim_service_settlement", {"head" => @head, "candidate_generation" => 1,
            "request_id" => "service-request", "expected_generation" => generation}, id: "actual-no-effect-challenge", peer: @executor, role: :executor)
          record = @journal.service_request("service-request")
          assert_equal record.slice("no_effect_challenge", "challenge_generation", "challenge_event_digest"),
            challenge.dig(:data, "reconciliation_challenge")
          completion_params, input = no_effect_upload(record, Authority::ServiceEvidence.new(journal: @journal).challenge!(record))
          complete = call("complete_no_effect", completion_params, id: "actual-no-effect-completion", peer: @executor, role: :executor, transfer: input)
          assert_equal "failed-settled", complete.dig(:data, "state")
          final_params = params.merge("expected_generation" => generation)
          stopped = call("stop_attempt", final_params, id: "actual-no-effect-stop", peer: @supervisor, role: :supervisor)
          assert_equal "stopped", stopped.dig(:data, "state")
          assert_equal "stopped", @journal.canonical_attempt_state(current_events)
          terminal = current_events.find { |event| event["type"] == "attempt_stopped" }
          settled = current_events.select { |event| event["type"] == "service_transition" && event.dig("payload", "state") == "failed-settled" }
          assert_equal 1, settled.length
          assert_equal settled.map { |event| event.fetch("digest") }, terminal.dig("payload", "service_settlement_event_digests")
          assert_equal current_events.select { |event| event["type"] == "inbox_reconciliation" && event.dig("payload", "state") == "completed" }
            .map { |event| event.fetch("digest") }.sort, terminal.dig("payload", "inbox_settlement_event_digests")
          assert_equal pending.fetch(:data), call("stop_attempt", pending_params, id: "pending-no-effect-stop",
            peer: @supervisor, role: :supervisor).fetch(:data)
          release = @launch.release_scope_reservation!(params: params.merge("mutation_id" => "actual-no-effect-release", "expected_generation" => generation),
            peer: @launcher, role: :launcher)
          assert_equal terminal.fetch("digest"), release.dig(:data, "terminal_event_id")
          before = @journal.ref_value
          restart
          assert_equal stopped.fetch(:data), call("stop_attempt", final_params, id: "actual-no-effect-stop",
            peer: @supervisor, role: :supervisor).fetch(:data)
          assert_equal before, @journal.ref_value
          File.binwrite(@boot_pointer, "invalid current pointer")
          @launch.with_execution_slots(mapping_ids: ["mapping"], candidate_deployment: @history.candidate) do |contexts|
            assert @launch.slot_reusable!(**contexts.first)
          end
        end
      end

      def test_actual_settled_canonical_uncertain_stop_releases_and_retains_original_history_after_rotation
        with_installed_boundaries do
          settle_service
          settle_inbox
          stop_terminal_and_release(uncertain: true)
          original_events = current_events
          original_attempt = @attempt
          File.binwrite(@boot_pointer, "invalid current boot pointer")
          store = Ace::Herdr::Molecules::DeliveryRecordStore
          store.with_lock(@context.fetch("deliveries_dir"), "event") { store.archive(@context.fetch("deliveries_dir"), "event") }
          @launch.with_execution_slots(mapping_ids: ["mapping"], candidate_deployment: @history.candidate) do |contexts|
            assert @launch.slot_reusable!(**contexts.first)
            assert_equal "retired", @launch.retire_released_parent!(**contexts.first).fetch("state")
          end
          File.binwrite(@published, File.binread(@candidate_ref.fetch("path")))
          File.binwrite(@published_key, @next_key.public_to_pem)
          @launch.close
          @deployment, @history = load_fixed
          @map = @deployment.mapping("mapping")
          refresh_candidate_boot!
          restart
          state = call("reserve_attempt", {"scope" => "010", "worker_uid" => 13001, "runtime" => "herdr", "base_head" => @head,
            "launcher_process_binding" => @launcher, "expected_generation" => 1}, id: "stopped-rotated-reserve", peer: @launcher, role: :launcher).fetch(:data)
          refute_equal original_attempt, state.fetch("attempt_id")
          assert_equal "reserved", state.fetch("phase")
          assert_equal original_events, @journal.read_events("assignment").select { |event| event["attempt_id"] == original_attempt }
        end
      end

      def test_actual_terminal_service_inbox_original_history_retirement_and_rotated_normal_reuse
        with_installed_boundaries do
          assert @deployment.frozen?
          assert_equal @original_ref.fetch("sha256"), @deployment.artifact_reference.fetch("sha256")
          settle_service
          settle_inbox
          accept_terminal_and_release
          original_attempt = @attempt
          original_events = current_events
          original_deployment = @deployment
          original_map = @map
          original_commit = @journal.ref_value
          settlement_params = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => original_attempt}
          service_evidence = @endcap.service_settlement_evidence!(journal: @journal, events: original_events,
            params: settlement_params, map: original_map, commit: original_commit)
          inbox_evidence = @endcap.historical_inbox_settlement_evidence!(journal: @journal, events: original_events,
            params: settlement_params, map: original_map, commit: original_commit, deployment: original_deployment, history: @history)
          assert_equal 1, service_evidence.fetch("services").size
          assert_equal 1, inbox_evidence.fetch("inboxes").size
          reconciliation = original_events.find { |event| event["type"] == "inbox_reconciliation" }
          assert_equal reconciliation.fetch("digest"), inbox_evidence.fetch("inboxes").first.fetch("reconciliation_event_digest")
          assert_equal reconciliation.dig("payload", "receipt_ref"), inbox_evidence.fetch("inboxes").first.fetch("receipt_ref")
          assert_raises(FrozenError) { inbox_evidence.fetch("inboxes").first.fetch("signature_ref")["ref"].replace("changed") }
          assert_equal @boot_ref, original_events.find { |event| event["type"] == "scope_bound" }.dig("payload", "boot_baseline_selection")
          # Retained historical authentication must not rediscover current boot.
          File.binwrite(@boot_pointer, "invalid current boot pointer")
          # Archive is actual retained store ownership, not a synthetic absence.
          store = Ace::Herdr::Molecules::DeliveryRecordStore
          store.with_lock(@context.fetch("deliveries_dir"), "event") { store.archive(@context.fetch("deliveries_dir"), "event") }
          before = @scope.retirements
          @launch.with_execution_slots(mapping_ids: ["mapping"], candidate_deployment: @history.candidate) do |contexts|
            assert @launch.slot_reusable!(**contexts.first)
            assert_equal "retired", @launch.retire_released_parent!(**contexts.first).fetch("state")
          end
          assert_equal before + 1, @scope.retirements
          File.binwrite(@published, File.binread(@candidate_ref.fetch("path")))
          File.binwrite(@published_key, @next_key.public_to_pem)
          @launch.close
          @deployment, @history = load_fixed
          @map = @deployment.mapping("mapping")
          refresh_candidate_boot!
          restart
          assert_equal inbox_evidence, @endcap.historical_inbox_settlement_evidence!(journal: @journal, events: original_events,
            params: settlement_params, map: original_map, commit: original_commit, deployment: original_deployment, history: @history)
          state = call("reserve_attempt", {"scope" => "010", "worker_uid" => 13001, "runtime" => "herdr", "base_head" => @head,
            "launcher_process_binding" => @launcher, "expected_generation" => 1}, id: "rotated-reserve", peer: @launcher, role: :launcher).fetch(:data)
          refute_equal original_attempt, state.fetch("attempt_id")
          assert_equal "reserved", state.fetch("phase")
          assert_equal original_events, @journal.read_events("assignment").select { |event| event["attempt_id"] == original_attempt }
          provision = @journal.read_events("assignment").find { |event| event["type"] == "scope_provisioning" && event["attempt_id"] == state.fetch("attempt_id") }
          assert_equal @candidate_ref.fetch("sha256"), provision.dig("payload", "descriptor_sha256")
          selected_commit = @journal.ref_value
          read_inventory = lambda do |commit|
            @router.dispatch(request: {"version" => 1, "operation" => "assignment_inventory", "mutation_id" => nil,
              "project_id" => "project", "params" => {"mapping_id" => "mapping", "journal_commit" => commit, "after" => nil, "limit" => 25}},
              peer: @launcher, role: :launcher).fetch(:data)
          end
          inventory = read_inventory.call(nil)
          assert_equal selected_commit, inventory.fetch("journal_commit")
          retained = inventory.fetch("items").find { |item| item["attempt_id"] == original_attempt }
          assert_equal "succeeded", retained.fetch("canonical_state")
          assert_equal original_events.find { |event| event["type"] == "receipt_accepted" }.fetch("digest"), retained.fetch("terminal_event_id")
          assert_equal original_events.find { |event| event.dig("payload", "operation") == "scope_reservation_release" }.fetch("digest"), retained.fetch("reservation_release_event_id")
          fresh = inventory.fetch("items").find { |item| item["attempt_id"] == state.fetch("attempt_id") }
          assert_equal "reserved", fresh.fetch("canonical_state")
          assert_nil fresh.fetch("terminal_event_id")
          assert_nil fresh.fetch("reservation_release_event_id")
          old_inventory = read_inventory.call(original_commit)
          assert_equal [original_attempt], old_inventory.fetch("items").map { |item| item.fetch("attempt_id") }
          assert_equal retained, old_inventory.fetch("items").first
          assert_equal selected_commit, @journal.ref_value
        end
      end
    end
  end
end
