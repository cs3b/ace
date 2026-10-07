# frozen_string_literal: true
require_relative "../../test_helper"
require_relative "../../support/endcap_result_owner_fixture"
require_relative "../../support/execution_boot_baseline_owner_fixture"
require "ace/assign/authority/deployment_history"
require "ace/herdr/organisms/inbox"

module Ace
  module Assign
    # Canonical owners and protected held-byte loaders are real. Installed UID,
    # filesystem installation checks and native observation are controlled seams.
    class HistoricalRotationTest < AceAssignTestCase
      include EndcapResultOwnerFixture
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
        @service = @service.merge("state_root" => File.join(@root, "authority-state"))
        Dir.mkdir(@service.fetch("state_root"), 0700)
        @key = OpenSSL::PKey::RSA.new(1024)
        key_ref = artifact("original-public.pem", @key.public_to_pem)
        @next_key = OpenSSL::PKey::RSA.new(1024)
        next_key_ref = artifact("candidate-public.pem", @next_key.public_to_pem)
        @published_key = File.join(@root, "current-public.pem")
        File.binwrite(@published_key, @key.public_to_pem)
        deliveries = File.join(@root, "deliveries")
        Dir.mkdir(deliveries, 0700)
        @context = {"deliveries_dir" => deliveries, "receipt_public_key" => @published_key,
          "native_mapping_id" => "mapping", "supervisor_uids" => [13004],
          "pi_queue_client" => "/fixture/pi", "pi_queue_client_sha256" => "a" * 64}
        @map = @map.merge("worker_argv" => ["/usr/bin/true"], "worker_env" => {"PATH" => "/usr/bin"},
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
        value = {"schema" => "ace.assign.authorities/v2", "authorities" => {"authority" => @service.slice("uid", "gid", "groups", "socket_path", "state_root").merge("composition" => "services")},
          "projects" => {"project" => @project}, "launch_mappings" => {"mapping" => @map}}
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
        @endcap = Authority::Endcap.new(deployment: @deployment, launch: @launch, kernel: @kernel, service_policy: @policy)
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

      def settle_service
        review = call("assign_review", {"head" => @head, "candidate_generation" => 1, "expected_generation" => generation,
          "reviewer_uid" => @reviewer.fetch("uid"), "reviewer_process_binding" => @reviewer},
          id: "review", peer: @launcher, role: :launcher).fetch(:data)
        _, _, receipt = upload(parts: ["review report"])
        receipt.merge!("operation" => "review", "review" => {"head" => @head, "verdict" => "approved", "reviewer" => {"actor" => review.fetch("reviewer_actor")}})
        params, input, = upload(parts: ["review report"], receipt: receipt)
        call("accept_review", params.merge("purpose_id" => review.fetch("review_id")), id: "accept-review", peer: @reviewer, role: :reviewer, transfer: input)
        body = "exact service input"
        input_digest = Digest::SHA256.hexdigest(body)
        @policy.define_singleton_method(:input_binding) do |bytes, expected_digest:, expected_target:|
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
        executor = Object.new
        executor.define_singleton_method(:pane_get_bounded) do |*|
          Ace::Herdr::Molecules::ExecutionResult.new(stdout: JSON.generate("result" => {"pane" => {
            "pane_id" => "p1", "workspace_id" => "w1", "terminal_id" => "terminal", "agent" => "codex", "agent_status" => "busy",
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
        params = {"event_id" => "event", "inbox_context_id" => "inbox", "expected_registration" => registration, "expected_generation" => generation,
          "receipt_sha256" => Digest::SHA256.hexdigest(bytes), "signature_sha256" => Digest::SHA256.hexdigest(signature),
          "transfer" => Authority::TransferCodec.new(root: @root).descriptor(parts, purpose: :inbox_proof)}
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

      def test_actual_terminal_service_inbox_original_history_retirement_and_rotated_normal_reuse
        with_installed_boundaries do
          assert @deployment.frozen?
          assert_equal @original_ref.fetch("sha256"), @deployment.artifact_reference.fetch("sha256")
          settle_service
          settle_inbox
          accept_terminal_and_release
          original_attempt = @attempt
          original_events = current_events
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
          state = call("reserve_attempt", {"scope" => "010", "worker_uid" => 13001, "runtime" => "herdr", "base_head" => @head,
            "launcher_process_binding" => @launcher, "expected_generation" => 1}, id: "rotated-reserve", peer: @launcher, role: :launcher).fetch(:data)
          refute_equal original_attempt, state.fetch("attempt_id")
          assert_equal "reserved", state.fetch("phase")
          assert_equal original_events, @journal.read_events("assignment").select { |event| event["attempt_id"] == original_attempt }
          provision = @journal.read_events("assignment").find { |event| event["type"] == "scope_provisioning" && event["attempt_id"] == state.fetch("attempt_id") }
          assert_equal @candidate_ref.fetch("sha256"), provision.dig("payload", "descriptor_sha256")
        end
      end
    end
  end
end
