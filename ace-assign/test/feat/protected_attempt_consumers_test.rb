# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../support/endcap_result_owner_fixture"
require_relative "../support/execution_boot_baseline_owner_fixture"
require_relative "../support/protected_inbox_context_pipeline_fixture"
require "ace/assign/authority/client"
require "ace/herdr/organisms/inbox"

module Ace
  module Assign
    class ProtectedAttemptConsumersTest < AceAssignTestCase
      include EndcapResultOwnerFixture
      include ProtectedInboxContextPipelineFixture
      include ExecutionBootBaselineOwnerFixture

      class BootProtection
        def root_path!(_path); end
        def verify!(_path, handle, directory:)
          raise "wrong controlled boot artifact type" unless directory ? handle.stat.directory? : handle.stat.file?
        end
      end

      def fixture(pending_service: false, **options, &block)
        @pending_service_fixture = pending_service
        original = ExecutionScopeNativeOwnerFixture.method(:new)
        scope = ->(*args, **kwargs) do
          original.call(*args, **kwargs.merge(boot_baseline_selection: @retained_boot, network_selection: @retained_network,
            network_installation: ExecutionScopeObservationFixtures::NETWORK_OUTPUT.merge(
              "installer_artifact_sha256" => @retained_network.fetch("installer_artifact").fetch("sha256"))))
        end
        baseline = -> { fixture_boot_baseline_reader(protection: BootProtection.new) }
        ExecutionScopeNativeOwnerFixture.stub(:new, scope) do
          Ace::Runtime::Molecules::ExecutionBootBaseline.stub(:new, baseline) { super(**options, &block) }
        end
      end

      def candidate(number)
        return if @public_candidate_fixture
        super
      end

      def configure_result_owner_fixture
        @project.merge!("journal_repository" => @journal.repo_root, "evidence_git_ref" => @journal.ref,
          "evidence_checkout_root" => @journal.checkout_root)
        producer_path = File.join(File.realpath(@root), "retained-installer")
        producer_bytes = "controlled original installer artifact"
        File.binwrite(producer_path, producer_bytes)
        producer = {"path" => producer_path, "sha256" => Digest::SHA256.hexdigest(producer_bytes), "bytes" => producer_bytes.bytesize}
        @retained_network = ExecutionScopeObservationFixtures::NETWORK_SELECTION.merge("installer_artifact" => producer)
        @retained_boot = retained_boot_baseline_artifact(root: File.realpath(@root), name: "retained-boot.json", map: @map, installer: producer)
        @project.merge!("launcher_uids" => [@launcher.fetch("uid")], "worker_uids" => [@worker.fetch("uid")])
        map, project, service = @map, @project, @service
        @deployment.define_singleton_method(:data) do
          {"launch_mappings" => {"mapping" => map}, "projects" => {"project" => project}, "authorities" => {"authority" => service}}
        end
        @deployment.define_singleton_method(:mapping_digest) { |_| Atoms::EvidenceDigest.digest(map) }
        if @pending_service_fixture
          @project["service_receivers"] = {"executor" => {"executor_uid" => @executor.fetch("uid"),
            "socket_path" => "/fixture/service.sock", "staging_root" => "/fixture/staging"}}
          reader = nil
          @journal = Molecules::EvidenceJournal.new(repo_root: @journal.repo_root, ref: @journal.ref,
            checkout_root: @journal.checkout_root, mode: :protected, evidence_reader: ->(*args) { reader.call(*args) },
            service_authorizer: ->(existing, replacement, pending) {
              @endcap.authorize_service_update!(journal: @journal, existing: existing, replacement: replacement, pending: pending) })
          reader = Authority::ServiceEvidence.new(journal: @journal)
        end
      end

      def with_original_inbox
        @key = OpenSSL::PKey::RSA.new(2048)
        key_path = File.join(@root, "receipt-public.pem")
        File.write(key_path, @key.public_to_pem)
        @context = {"native_mapping_id" => "mapping", "supervisor_uids" => [13004],
          "deliveries_dir" => File.join(@root, "deliveries"), "receipt_public_key" => key_path,
          "pi_queue_client" => "/fixture/inbox-client"}
        @project["inbox_contexts"] = {"context" => @context}
        selected = @context
        @deployment.define_singleton_method(:inbox_context) do |mapping, context|
          raise AttemptErrors::EvidenceUnavailable unless mapping == "mapping" && context == "context"
          selected
        end
        @deployment.define_singleton_method(:verify_inbox_context!) { |*| true }
        map = @map
        @deployment.define_singleton_method(:mapping_digest) { |_| Atoms::EvidenceDigest.digest(map) }
        @authority_peer = @kernel.capture(Process.pid)
        @context_peer = @kernel.capture(94).merge("uid" => 13007, "gid" => 13007, "groups" => [13007])
        executor = Object.new
        executor.define_singleton_method(:pane_get_bounded) do |_pane|
          Ace::Herdr::Molecules::ExecutionResult.new(stdout: JSON.generate("result" => {"pane" => {
            "pane_id" => "p1", "workspace_id" => "w1", "terminal_id" => "term_ab", "agent" => "codex", "agent_status" => "busy",
            "agent_session" => {"agent" => "codex", "kind" => "id", "value" => "0123abcd-0000-4000-8000-000000000001"}}}),
            stderr: "", success: true, exit_code: 0)
        end
        native = Object.new
        native.define_singleton_method(:submit) { |**| {"accepted" => true} }
        @box = Ace::Herdr::Organisms::Inbox.new(executor: executor, native: native,
          deliveries_dir: selected.fetch("deliveries_dir"), receipt_public_key: @key.public_key)
        @box.enqueue(event: "event", attempt: @attempt, ref: {"session" => "w1", "pane" => "p1"}, payload: "message")
        record = @box.deliver(event: "event")
        @registration = record.slice("event_id", "attempt_id", "payload_sha256", "receipt_key_sha256")
        original, retained_key = @deployment, @key.public_key
        descriptor_sha256 = original.artifact_reference.fetch("sha256")
        @history = Object.new
        @history.define_singleton_method(:descriptor!) do |sha256:|
          raise AttemptErrors::EvidenceUnavailable unless sha256 == descriptor_sha256
          original
        end
        @history.define_singleton_method(:public_key!) do |sha256:|
          raise AttemptErrors::EvidenceUnavailable unless sha256 == Digest::SHA256.hexdigest(retained_key.public_to_der)
          retained_key
        end
        start_context_pipeline(@root)
        service = @service
        @deployment.define_singleton_method(:authority) { |_| service }
        @launch = Authority::LaunchLifecycle.new(deployment: @deployment, control_exclusion_factory: ProtectedControlFixture.factory, kernel: @kernel, journals: {"project" => @journal},
          scope_observer_factory: ->(_id) { ExecutionScopeNativeOwnerFixture.new(@map, @journal, @kernel, owner: @launch) })
        @endcap = Authority::Endcap.new(deployment: @deployment, launch: @launch, kernel: @kernel,
          service_policy: @policy, inbox_context_clients: @context_clients, deployment_history: @history)
        @router = Authority::Router.new(launch: @launch, handlers: [@endcap])
        yield
      ensure
        stop_context_pipeline
      end

      def start_public_server
        @kernel.peer_identity = @worker
        @server = Authority::Server.new(authority_id: "authority", lifecycle: @router,
          deployment: @deployment, kernel: @kernel, composition: "services")
        wire = Object.new
        wire.define_singleton_method(:root_path!) { |*_, **_| true }
        %i[socket_identity read write deadline].each do |name|
          wire.define_singleton_method(name) { |*args, **options| WIRE.public_send(name, *args, **options) }
        end
        @server.define_singleton_method(:wire) { wire }
        @owner = Thread.new { @server.serve }
        Timeout.timeout(3) { sleep 0.005 until File.socket?(@service.fetch("socket_path")) }
        @client_kernel = Kernel.new
        @client_kernel.peer_identity = @service.slice("uid", "gid", "groups")
        @client = Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: @client_kernel)
      end

      def public_cli_json(args, env: {})
        history = Object.new
        history.define_singleton_method(:descriptors) { [] }
        context = Authority::ProtectedAssignmentContext.new(deployment: @deployment, history: history,
          uid: @kernel.peer_identity.fetch("uid"), kernel: @client_kernel, env: env)
        forbidden = ->(*) { raise "local coordinator must not be constructed" }
        output, error = capture_io do
          Authority::ProtectedAssignmentContext.stub(:load, context) do
            Organisms::AttemptCoordinator.stub(:new, forbidden) do
              assert_equal 0, CLI.start(args)
            end
          end
        end
        assert_empty error
        JSON.parse(output)
      end

      def terminal_projection!(params, commit)
        @launch.completion_terminal!(journal: @journal, commit: commit,
          params: params.merge("mapping_id" => "mapping"), map: @map)
      rescue AttemptErrors::EvidenceUnavailable => error
        chain = []
        while error && chain.size < 4
          chain << "#{error.class}: #{error.message.byteslice(0, 200)}"
          error = error.cause
        end
        flunk "Controlled terminal owner refused: #{chain.join(' / ')}"
      end

      def test_public_binding_uses_original_context_registration_and_exact_replay
        fixture do
          with_original_inbox do
            start_public_server
            params = {"assignment_id" => "assignment", "attempt_id" => @attempt,
              "expected_generation" => generation, "event_id" => "event", "inbox_context_id" => "context"}
            original = @journal.ref_value
            args = ["inbox-bind", "--mapping", "mapping", "--assignment", "assignment", "--attempt", @attempt,
              "--event", "event", "--inbox-context", "context", "--mutation", "bind-inbox", "--expected-generation", generation.to_s]
            %w[ACE_ASSIGN_ASSIGNMENT_ID ACE_ASSIGN_ATTEMPT_ID].each do |hint|
              assert_raises(AttemptErrors::EvidenceUnavailable) { public_cli_json(args, env: {hint => "foreign"}) }
              assert_equal original, @journal.ref_value
            end
            malformed = args.dup
            malformed[-1] = "1.0"
            assert_raises(Ace::Support::Cli::Error) { public_cli_json(malformed) }
            assert_equal original, @journal.ref_value
            stale = args.dup
            stale[-1] = (generation + 1).to_s
            conflict = assert_raises(AttemptErrors::EvidenceUnavailable) { public_cli_json(stale) }
            assert_match(/\(conflict\)/, conflict.message)
            assert_equal original, @journal.ref_value
            foreign = args.dup
            foreign[2] = "missing-mapping"
            assert_raises(AttemptErrors::EvidenceUnavailable, AttemptErrors::UnauthorizedIdentity) { public_cli_json(foreign) }
            assert_equal original, @journal.ref_value
            @kernel.peer_identity = @supervisor
            assert_raises(AttemptErrors::EvidenceUnavailable, AttemptErrors::UnauthorizedIdentity) { public_cli_json(args) }
            assert_equal original, @journal.ref_value
            @kernel.peer_identity = @worker
            cli = public_cli_json(["inbox-bind", "--mapping", "mapping", "--assignment", "assignment", "--attempt", @attempt,
              "--event", "event", "--inbox-context", "context", "--mutation", "bind-inbox", "--expected-generation", generation.to_s])
            assert_equal @registration, cli.fetch("registration")
            first = @client.call("bind_inbox", params, mutation_id: "bind-inbox", timeout: 30)
            assert_equal @registration, first.data.fetch("registration")
            assert_equal 1, @journal.read_events("assignment").count { |event| event["type"] == "inbox_binding" }
            accepted = @journal.ref_value
            replay = @client.call("bind_inbox", params, mutation_id: "bind-inbox", timeout: 30)
            assert replay.replayed
            assert_equal first.data, replay.data
            assert_equal accepted, @journal.ref_value
            changed = args.dup
            changed[8] = "different-event"
            assert_raises(AttemptErrors::Conflict, AttemptErrors::EvidenceUnavailable) { public_cli_json(changed) }
            assert_equal accepted, @journal.ref_value
            @kernel.dead << @worker.fetch("pid")
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              @client.call("bind_inbox", params, mutation_id: "bind-inbox", timeout: 30)
            end
            assert_equal accepted, @journal.ref_value
          end
        end
      end

      def test_public_cli_fresh_inbox_binding_refuses_after_original_scope_seal
        fixture do
          with_original_inbox do
            start_public_server
            @launch.close_execution_scope!(params: {"mapping_id" => "mapping", "assignment_id" => "assignment",
              "attempt_id" => @attempt, "mutation_id" => "bind-seal", "expected_generation" => generation},
              peer: @supervisor, role: :supervisor)
            sealed = @journal.ref_value
            assert @journal.read_events("assignment").any? { |event| event["type"] == "scope_sealed" }
            assert_raises(AttemptErrors::Conflict, AttemptErrors::EvidenceUnavailable) do
              public_cli_json(["inbox-bind", "--mapping", "mapping", "--assignment", "assignment", "--attempt", @attempt,
                "--event", "event", "--inbox-context", "context", "--mutation", "sealed-binding",
                "--expected-generation", generation.to_s])
            end
            assert_equal sealed, @journal.ref_value
            refute @journal.read_events("assignment").any? { |event| event["type"] == "inbox_binding" }
          end
        end
      end

      def test_public_recovery_adopts_only_verified_live_original_prepared_owner
        fixture do
          scope_factory = lambda do |_id|
            observer = ExecutionScopeNativeOwnerFixture.new(@map, @journal, @kernel, owner: @launch)
            observer.define_singleton_method(:observe) { |_lineage| {"populated" => 1} }
            observer
          end
          @launch = Authority::LaunchLifecycle.new(deployment: @deployment, control_exclusion_factory: ProtectedControlFixture.factory, deployment_history: @history,
            kernel: @kernel, journals: {"project" => @journal}, scope_observer_factory: scope_factory)
          @endcap = Authority::Endcap.new(deployment: @deployment, launch: @launch, kernel: @kernel, service_policy: @policy)
          @router = Authority::Router.new(launch: @launch, handlers: [@endcap])
          start_public_server
          @kernel.peer_identity = @supervisor
          params = {"assignment_id" => "assignment", "attempt_id" => @attempt, "expected_generation" => generation}
          first = @client.call("recover", params, mutation_id: "recover-live-owner", timeout: 30)
          assert_equal "adopt", first.data.fetch("decision")
          assert_equal "live_owner", first.data.fetch("reason")
          assert_equal "running", first.data.fetch("state")
          accepted = @journal.ref_value
          @kernel.dead << @worker.fetch("pid")
          replay = @client.call("recover", params, mutation_id: "recover-live-owner", timeout: 30)
          assert replay.replayed
          assert_equal first.data, replay.data
          assert_equal accepted, @journal.ref_value
        end
      end

      def test_public_cli_recovery_preserves_authenticated_queued_inbox
        fixture do
          with_original_inbox do
            start_public_server
            selectors = {"assignment_id" => "assignment", "attempt_id" => @attempt}
            @client.call("bind_inbox", selectors.merge("expected_generation" => generation, "event_id" => "event",
              "inbox_context_id" => "context"), mutation_id: "pending-bind", timeout: 30)
            record = @box.retained_status(event: "event")
            receipt = record.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding").merge(
              "outcome" => "superseded", "observer" => {"role" => "supervisor", "id" => "observer"},
              "evidence" => {"kind" => "queue_evicted", "native_reference" => "native:pending", "observation" => "superseded"})
            bytes = JSON.generate(receipt)
            signature = @key.sign(OpenSSL::Digest::SHA256.new, bytes)
            @kernel.peer_identity = @supervisor
            registration_path = File.join(@root, "registration.json")
            receipt_path = File.join(@root, "inbox-receipt.json")
            signature_path = File.join(@root, "inbox-receipt.sig")
            File.binwrite(registration_path, JSON.generate(@registration))
            File.binwrite(receipt_path, bytes)
            File.binwrite(signature_path, signature)
            reconcile_args = ["inbox-reconcile", "--mapping", "mapping", "--assignment", "assignment", "--attempt", @attempt,
              "--event", "event", "--inbox-context", "context", "--expected-generation", generation.to_s,
              "--mutation", "pending-reconcile", "--registration", registration_path, "--receipt", receipt_path, "--signature", signature_path]
            reconciled = public_cli_json(reconcile_args)
            reconcile_ref = @journal.ref_value
            assert_equal reconciled, public_cli_json(reconcile_args)
            assert_equal reconcile_ref, @journal.ref_value
            assert_equal "queued", reconciled.fetch("state")
            original_generation = generation
            args = ["attempt", "reconcile", "--mapping", "mapping", "--assignment", "assignment", "--attempt", @attempt,
              "--mutation", "pending-recovery", "--expected-generation", original_generation.to_s]
            result = public_cli_json(args)
            assert_equal "reconcile-required", result.fetch("decision")
            assert_equal "unresolved_inbox", result.fetch("reason")
            assert_equal "uncertain", result.fetch("state")
            accepted = @journal.ref_value
            assert_equal result, public_cli_json(args)
            assert_equal accepted, @journal.ref_value
            assert_equal "queued", @box.retained_status(event: "event").fetch("state")
          end
        end
      end

      def test_public_cli_recovery_preserves_authenticated_started_service
        fixture(pending_service: true) do
          start_public_server
          selectors = {"assignment_id" => "assignment", "attempt_id" => @attempt}
          @kernel.peer_identity = @launcher
          review = @client.call("assign_review", selectors.merge("head" => @head, "candidate_generation" => 1,
            "expected_generation" => generation, "reviewer_uid" => @reviewer.fetch("uid"),
            "reviewer_process_binding" => @reviewer), mutation_id: "pending-review", timeout: 30).data
          _, _, receipt = upload(parts: ["review report"])
          receipt.merge!("operation" => "review", "review" => {"head" => @head, "verdict" => "approved",
            "reviewer" => {"actor" => review.fetch("reviewer_actor")}})
          params, input, = upload(parts: ["review report"], receipt: receipt)
          @kernel.peer_identity = @reviewer
          @client.call("accept_review", params.except("transfer").merge(selectors).merge("purpose_id" => review.fetch("review_id")),
            mutation_id: "pending-review-accept", timeout: 30, upload_parts: input.parts, purpose: :receipt_artifacts)
          body = "exact pending service input"
          digest = Digest::SHA256.hexdigest(body)
          @policy.define_singleton_method(:input_binding) do |bytes, expected_digest:, expected_target:, operation:|
            raise "service input changed" unless bytes == body && expected_digest == digest &&
              expected_target == {"resource" => "fixture"} && operation == "publish"
          end
          @policy.define_singleton_method(:prepare!) do |binding, input_bytes:|
            raise "service input changed" unless input_bytes == body && binding.fetch("input_digest") == digest
            {binding: binding.merge("executor_uid" => 13005, "transport" => "unix"), policy_digest: "f" * 64}
          end
          @kernel.peer_identity = @executor
          requested = selectors.merge("head" => @head, "candidate_generation" => 1, "expected_generation" => generation,
            "request_id" => "pending-service", "operation" => "publish", "input_digest" => digest,
            "target" => {"resource" => "fixture"}, "authorization" => "review", "service_id" => "executor",
            "worker_process_binding" => @worker)
          claim = @client.call("request_service", requested, mutation_id: "pending-service-claim", timeout: 30,
            upload_parts: [body], purpose: :service_input).data
          @client.call("begin_dispatch", selectors.merge("head" => @head, "candidate_generation" => 1,
            "expected_generation" => generation, "request_id" => "pending-service", "claim_binding" => claim.fetch("claim_binding")),
            mutation_id: "pending-service-begin", timeout: 30, upload_parts: [body], purpose: :service_input)
          assert_equal "dispatch_started", @journal.service_request("pending-service").fetch("dispatch_phase")
          assert_equal "uncertain", @journal.service_request("pending-service").fetch("state")
          @kernel.peer_identity = @supervisor
          args = ["attempt", "reconcile", "--mapping", "mapping", "--assignment", "assignment", "--attempt", @attempt,
            "--mutation", "pending-service-recovery", "--expected-generation", generation.to_s]
          result = public_cli_json(args)
          assert_equal "reconcile-required", result.fetch("decision")
          assert_equal "unresolved_effect", result.fetch("reason")
          assert_equal "uncertain", result.fetch("state")
          accepted = @journal.ref_value
          assert_equal result, public_cli_json(args)
          assert_equal accepted, @journal.ref_value
          assert_equal "dispatch_started", @journal.service_request("pending-service").fetch("dispatch_phase")
          assert_equal "uncertain", @journal.service_request("pending-service").fetch("state")
        end
      end

      def test_public_recovery_records_uncertainty_and_replays_without_new_observation
        fixture do
          start_public_server
          @kernel.peer_identity = @supervisor
          @kernel.dead << @worker.fetch("pid")
          params = {"assignment_id" => "assignment", "attempt_id" => @attempt, "expected_generation" => generation}
          first = @client.call("recover", params, mutation_id: "recover-dead-owner", timeout: 30)
          assert_equal "reconcile-required", first.data.fetch("decision")
          assert_equal "scope_unverifiable", first.data.fetch("reason")
          assert_equal "uncertain", first.data.fetch("state")
          accepted = @journal.ref_value
          events = @journal.read_events("assignment")
          assert_equal 1, events.count { |event| event["type"] == "recovery_observation" }
          replay = @client.call("recover", params, mutation_id: "recover-dead-owner", timeout: 30)
          assert replay.replayed
          assert_equal first.data, replay.data
          assert_equal accepted, @journal.ref_value
          error = assert_raises(AttemptErrors::EvidenceUnavailable) do
            @client.call("recover", params.merge("expected_generation" => generation), mutation_id: "recover-dead-owner", timeout: 30)
          end
          assert_match(/conflict/, error.message)
          assert_equal accepted, @journal.ref_value
          @kernel.peer_identity = @worker
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @client.call("recover", params, mutation_id: "recover-dead-owner", timeout: 30)
          end
          assert_equal accepted, @journal.ref_value
        end
      end

      def test_public_failed_finish_requires_closure_and_replays_after_worker_exit
        fixture do
          start_public_server
          missing = File.join(@root, "expected-but-missing")
          refute File.exist?(missing)
          receipt = Models::ExecutionReceipt.new(assignment_id: "assignment", attempt_id: @attempt, project_id: "project",
            scope: "010", operation: "work", producer: {"actor" => "worker", "role" => "worker", "runtime" => "herdr"},
            head: @head, verdict: "failed", checks: [{"name" => "expected artifact absent", "verdict" => "failed"}],
            artifacts: [], recorded_at: Time.now.utc)
          path = File.join(@root, "failed-receipt.json")
          File.binwrite(path, JSON.generate(receipt.to_h))
          result = public_cli_json(["submit-result", "--mapping", "mapping", "--assignment", "assignment", "--attempt", @attempt,
            "--head", @head, "--candidate-generation", "1", "--expected-generation", generation.to_s,
            "--mutation", "failed-worker-result", "--receipt", path])
          @kernel.peer_identity = @supervisor
          params = {"assignment_id" => "assignment", "attempt_id" => @attempt, "expected_generation" => generation,
            "candidate_generation" => 1, "head" => @head, "result_id" => result.fetch("result_id")}
          unclosed = @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @client.call("finish", params, mutation_id: "finish-before-proof", timeout: 30)
          end
          assert_equal unclosed, @journal.ref_value
          @kernel.dead << @worker.fetch("pid")
          selectors = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}
          @launch.close_execution_scope!(params: selectors.merge("mutation_id" => "finish-seal", "expected_generation" => generation),
            peer: @supervisor, role: :supervisor)
          @launch.close_execution_scope!(params: selectors.merge("mutation_id" => "finish-proof", "expected_generation" => generation),
            peer: @supervisor, role: :supervisor)
          params["expected_generation"] = generation
          cli = public_cli_json(["attempt", "finish", "--mapping", "mapping", "--assignment", "assignment", "--attempt", @attempt,
            "--result", result.fetch("result_id"), "--head", @head, "--candidate-generation", "1", "--mutation", "finish",
            "--expected-generation", generation.to_s])
          assert_equal "failed", cli.fetch("state")
          first = @client.call("finish", params, mutation_id: "finish", timeout: 30)
          assert_equal "failed", first.data.fetch("state")
          assert_equal result.fetch("receipt_digest"), first.data.fetch("receipt_digest")
          accepted = @journal.ref_value
          terminal = terminal_projection!(params, accepted)
          assert_equal "failed", terminal.fetch("canonical_state")
          refute_nil terminal.fetch("terminal_event_id")
          replay = @client.call("finish", params, mutation_id: "finish", timeout: 30)
          assert replay.replayed
          assert_equal first.data, replay.data
          assert_equal accepted, @journal.ref_value
          recovery_params = params.slice("assignment_id", "attempt_id").merge("expected_generation" => generation)
          recovery = @client.call("recover", recovery_params, mutation_id: "terminal-recovery", timeout: 30)
          assert_equal "restart-required", recovery.data.fetch("decision")
          assert_equal "terminal_attempt", recovery.data.fetch("reason")
          assert_equal "failed", recovery.data.fetch("state")
          assert_equal accepted, recovery.data.fetch("journal_commit")
          assert_equal accepted, @journal.ref_value
          again = @client.call("recover", recovery_params, mutation_id: "terminal-recovery-again", timeout: 30)
          assert_equal recovery.data, again.data
          assert_equal accepted, @journal.ref_value
          released = @launch.release_scope_reservation!(params: selectors.merge("mutation_id" => "finish-release",
            "expected_generation" => generation), peer: @supervisor, role: :supervisor)
          assert_equal "released", released.fetch(:data).fetch("reservation")
          accepted = @journal.ref_value
          terminal_projection!(params, accepted)
          cli_recovery = public_cli_json(["attempt", "reconcile", "--mapping", "mapping", "--assignment", "assignment", "--attempt", @attempt,
            "--mutation", "released-recovery", "--expected-generation", generation.to_s])
          assert_equal "restart-required", cli_recovery.fetch("decision")
          released_recovery = @client.call("recover", recovery_params.merge("expected_generation" => generation),
            mutation_id: "released-recovery", timeout: 30)
          assert_equal "restart-required", released_recovery.data.fetch("decision")
          assert_equal "terminal_attempt", released_recovery.data.fetch("reason")
          assert_equal accepted, released_recovery.data.fetch("journal_commit")
          assert_equal accepted, @journal.ref_value
          assert_equal 1, @journal.read_events("assignment").count { |event| event.dig("payload", "operation") == "scope_reservation_release" }
          released_replay = @client.call("finish", params, mutation_id: "finish", timeout: 30)
          assert released_replay.replayed
          assert_equal first.data, released_replay.data
          assert_equal accepted, @journal.ref_value
          error = assert_raises(AttemptErrors::EvidenceUnavailable) do
            @client.call("finish", params.merge("expected_generation" => generation), mutation_id: "finish-again", timeout: 30)
          end
          assert_includes error.message, "(conflict)"
          assert_equal accepted, @journal.ref_value
        end
      end

      def test_public_succeeded_finish_requires_actual_independent_review_acceptance
        @public_candidate_fixture = true
        fixture do
          start_public_server
          bundle_path = File.join(@root, "tested.bundle")
          git(@journal.repo_root, "bundle", "create", bundle_path, "HEAD")
          first_args = ["submit-candidate", "--mapping", "mapping", "--assignment", "assignment", "--attempt", @attempt,
            "--head", @head, "--candidate-generation", "0", "--expected-generation", generation.to_s,
            "--mutation", "worker-first-candidate", "--bundle", bundle_path]
          first_candidate = public_cli_json(first_args)
          assert_equal 1, first_candidate.fetch("candidate_generation")
          first_ref = @journal.ref_value
          assert_equal first_candidate, public_cli_json(first_args)
          assert_equal first_ref, @journal.ref_value
          candidate_args = ["submit-candidate", "--mapping", "mapping", "--assignment", "assignment", "--attempt", @attempt,
            "--head", @head, "--candidate-generation", "1", "--expected-generation", generation.to_s,
            "--mutation", "worker-candidate", "--bundle", bundle_path]
          admitted = public_cli_json(candidate_args)
          assert_equal 2, admitted.fetch("candidate_generation")
          admitted_ref = @journal.ref_value
          assert_equal admitted, public_cli_json(candidate_args)
          assert_equal admitted_ref, @journal.ref_value
          stale_args = candidate_args.dup
          stale_args[stale_args.index("worker-candidate")] = "stale-candidate"
          assert_raises(AttemptErrors::EvidenceUnavailable) { public_cli_json(stale_args) }
          assert_equal admitted_ref, @journal.ref_value
          @kernel.peer_identity = @kernel.capture(92)
          assert_raises(AttemptErrors::EvidenceUnavailable) { public_cli_json(candidate_args) }
          assert_equal admitted_ref, @journal.ref_value
          @kernel.peer_identity = @worker
          changed_bundle = File.join(@root, "changed.bundle")
          File.binwrite(changed_bundle, File.binread(bundle_path) + "changed")
          changed_args = candidate_args.dup
          changed_args[changed_args.index(bundle_path)] = changed_bundle
          assert_raises(AttemptErrors::EvidenceUnavailable) { public_cli_json(changed_args) }
          assert_equal admitted_ref, @journal.ref_value
          artifact_path = File.join(@root, "worker-check.txt")
          File.binwrite(artifact_path, "actual controlled check evidence")
          receipt = Models::ExecutionReceipt.new(assignment_id: "assignment", attempt_id: @attempt, project_id: "project",
            scope: "010", operation: "work", producer: {"actor" => "worker", "role" => "worker", "runtime" => "herdr"},
            head: @head, verdict: "succeeded", checks: [{"name" => "candidate head equality", "verdict" => "passed"}],
            artifacts: [{"path" => "worker-check.txt", "sha256" => Digest::SHA256.file(artifact_path).hexdigest}], recorded_at: Time.now.utc)
          assert_equal @head, admitted.fetch("head")
          receipt_path = File.join(@root, "worker-receipt.json")
          File.binwrite(receipt_path, JSON.generate(receipt.to_h))
          result_args = ["submit-result", "--mapping", "mapping", "--assignment", "assignment", "--attempt", @attempt,
            "--head", @head, "--candidate-generation", "2", "--expected-generation", generation.to_s,
            "--mutation", "worker-result", "--receipt", receipt_path, "--artifact", artifact_path]
          campaign_receipt = Models::ExecutionReceipt.from_h(receipt.to_h.merge("campaign" => {"id" => "campaign"}, "digest" => nil))
          campaign_path = File.join(@root, "campaign-receipt.json")
          File.binwrite(campaign_path, JSON.generate(campaign_receipt.to_h))
          campaign_args = result_args.dup
          campaign_args[campaign_args.index("worker-result")] = "campaign-result"
          campaign_args[campaign_args.index(receipt_path)] = campaign_path
          campaign_args[campaign_args.index("--expected-generation") + 1] = generation.to_s
          campaign_ref = @journal.ref_value
          campaign_owner_error = nil
          original_verifier = @endcap.method(:verify_result_receipt)
          observing_verifier = lambda do |*args|
            original_verifier.call(*args)
          rescue AttemptErrors::EvidenceUnavailable => error
            campaign_owner_error = error.message
            raise
          end
          @endcap.stub(:verify_result_receipt, observing_verifier) do
            refusal = assert_raises(AttemptErrors::EvidenceUnavailable) { public_cli_json(campaign_args) }
            assert_equal "protected authority refused (evidence_unavailable)", refusal.message
          end
          assert_equal "protected campaigns require their canonical owner", campaign_owner_error
          assert_equal campaign_ref, @journal.ref_value
          result = public_cli_json(result_args)
          result_ref = @journal.ref_value
          assert_equal result, public_cli_json(result_args)
          assert_equal result_ref, @journal.ref_value
          @kernel.peer_identity = @launcher
          review = @client.call("assign_review", {"assignment_id" => "assignment", "attempt_id" => @attempt,
            "head" => @head, "candidate_generation" => 2, "expected_generation" => generation,
            "reviewer_uid" => @reviewer.fetch("uid"), "reviewer_process_binding" => @reviewer}, mutation_id: "finish-review", timeout: 30).data
          selectors = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}
          @launch.close_execution_scope!(params: selectors.merge("mutation_id" => "success-seal", "expected_generation" => generation),
            peer: @supervisor, role: :supervisor)
          @launch.close_execution_scope!(params: selectors.merge("mutation_id" => "success-proof", "expected_generation" => generation),
            peer: @supervisor, role: :supervisor)
          @kernel.peer_identity = @supervisor
          params = {"assignment_id" => "assignment", "attempt_id" => @attempt, "expected_generation" => generation,
            "candidate_generation" => 2, "head" => @head, "result_id" => result.fetch("result_id")}
          unapproved = @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @client.call("finish", params, mutation_id: "unapproved-finish", timeout: 30)
          end
          assert_equal unapproved, @journal.ref_value
          _, _, receipt = upload(parts: ["independent review report"])
          receipt.merge!("operation" => "review", "review" => {"head" => @head, "verdict" => "approved",
            "reviewer" => {"actor" => review.fetch("reviewer_actor")}})
          receipt_params, input, = upload(parts: ["independent review report"], receipt: receipt)
          @kernel.peer_identity = @reviewer
          accepted_review = @client.call("accept_review", receipt_params.except("transfer").merge(
            "assignment_id" => "assignment", "attempt_id" => @attempt, "candidate_generation" => 2, "purpose_id" => review.fetch("review_id")),
            mutation_id: "finish-review-accept", timeout: 30, upload_parts: input.parts, purpose: :receipt_artifacts).data
          refute_nil accepted_review.fetch("receipt_digest")
          @kernel.dead << @worker.fetch("pid")
          @kernel.peer_identity = @supervisor
          params["expected_generation"] = generation
          first = public_cli_json(["attempt", "finish", "--mapping", "mapping", "--assignment", "assignment",
            "--attempt", @attempt, "--result", params.fetch("result_id"), "--head", @head,
            "--candidate-generation", "2", "--mutation", "success-finish",
            "--expected-generation", params.fetch("expected_generation").to_s])
          assert_equal "succeeded", first.fetch("state")
          accepted = @journal.ref_value
          assert_equal "succeeded", terminal_projection!(params, accepted).fetch("canonical_state")
          replay = @client.call("finish", params, mutation_id: "success-finish", timeout: 30)
          assert replay.replayed
          assert_equal first, replay.data
          assert_equal accepted, @journal.ref_value
          @kernel.peer_identity = @worker
          assert_raises(AttemptErrors::EvidenceUnavailable) { public_cli_json(candidate_args) }
          assert_raises(AttemptErrors::EvidenceUnavailable) { public_cli_json(result_args) }
          assert_equal accepted, @journal.ref_value
          @kernel.peer_identity = @supervisor
          terminal_events = @journal.read_events("assignment").select { |event| event["attempt_id"] == @attempt }
          receipt_event = terminal_events.find { |event| event["type"] == "receipt_accepted" }
          @server.stop
          @owner.value
          git(@journal.repo_root, "update-ref", @journal.ref, unapproved, accepted)
          forged = @journal.mutate(assignment_id: "assignment", attempt_id: @attempt,
            mutation_id: "forged-unapproved-finish", operation: "finish",
            parameters_digest: Atoms::EvidenceDigest.digest(params), expected_generation: generation) do
            {events: [{type: "receipt_accepted", payload: receipt_event.fetch("payload")},
              {type: "transition", payload: {"from" => "running", "to" => "succeeded", "reason" => "protected_result_accepted"}}],
              blobs: {}, data: first.except("generation", "journal_commit")}
          end
          assert_equal "succeeded", forged.fetch("state")
          error = assert_raises(AttemptErrors::ReceiptRejected) do
            @launch.completion_terminal!(journal: @journal, commit: @journal.ref_value,
              params: params.merge("mapping_id" => "mapping"), map: @map)
          end
          assert_match(/exact independent review/, error.message)
        end
      ensure
        @public_candidate_fixture = false
      end
    end
  end
end
