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

      def fixture(**options, &block)
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

      def configure_result_owner_fixture
        @project.merge!("journal_repository" => @journal.repo_root, "evidence_git_ref" => @journal.ref,
          "evidence_checkout_root" => @journal.checkout_root)
        producer_path = File.join(File.realpath(@root), "retained-installer")
        producer_bytes = "controlled original installer artifact"
        File.binwrite(producer_path, producer_bytes)
        producer = {"path" => producer_path, "sha256" => Digest::SHA256.hexdigest(producer_bytes), "bytes" => producer_bytes.bytesize}
        @retained_network = ExecutionScopeObservationFixtures::NETWORK_SELECTION.merge("installer_artifact" => producer)
        @retained_boot = retained_boot_baseline_artifact(root: File.realpath(@root), name: "retained-boot.json", map: @map, installer: producer)
        map = @map
        @deployment.define_singleton_method(:mapping_digest) { |_| Atoms::EvidenceDigest.digest(map) }
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
        start_context_pipeline(@root)
        service = @service
        @deployment.define_singleton_method(:authority) { |_| service }
        @launch = Authority::LaunchLifecycle.new(deployment: @deployment, kernel: @kernel, journals: {"project" => @journal},
          scope_observer_factory: ->(_id) { ExecutionScopeNativeOwnerFixture.new(@map, @journal, @kernel, owner: @launch) })
        @endcap = Authority::Endcap.new(deployment: @deployment, launch: @launch, kernel: @kernel,
          service_policy: @policy, inbox_context_clients: @context_clients)
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
        client_kernel = Kernel.new
        client_kernel.peer_identity = @service.slice("uid", "gid", "groups")
        @client = Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: client_kernel)
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
            first = @client.call("bind_inbox", params, mutation_id: "bind-inbox", timeout: 30)
            assert_equal @registration, first.data.fetch("registration")
            assert_equal 1, @journal.read_events("assignment").count { |event| event["type"] == "inbox_binding" }
            accepted = @journal.ref_value
            replay = @client.call("bind_inbox", params, mutation_id: "bind-inbox", timeout: 30)
            assert replay.replayed
            assert_equal first.data, replay.data
            assert_equal accepted, @journal.ref_value
            @kernel.dead << @worker.fetch("pid")
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              @client.call("bind_inbox", params, mutation_id: "bind-inbox", timeout: 30)
            end
            assert_equal accepted, @journal.ref_value
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
          @launch = Authority::LaunchLifecycle.new(deployment: @deployment, deployment_history: @history,
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
          result = submit(verdict: "failed", parts: []).fetch(:data)
          start_public_server
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
        fixture do
          result = submit.fetch(:data)
          start_public_server
          @kernel.peer_identity = @launcher
          review = @client.call("assign_review", {"assignment_id" => "assignment", "attempt_id" => @attempt,
            "head" => @head, "candidate_generation" => 1, "expected_generation" => generation,
            "reviewer_uid" => @reviewer.fetch("uid"), "reviewer_process_binding" => @reviewer}, mutation_id: "finish-review", timeout: 30).data
          selectors = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}
          @launch.close_execution_scope!(params: selectors.merge("mutation_id" => "success-seal", "expected_generation" => generation),
            peer: @supervisor, role: :supervisor)
          @launch.close_execution_scope!(params: selectors.merge("mutation_id" => "success-proof", "expected_generation" => generation),
            peer: @supervisor, role: :supervisor)
          @kernel.peer_identity = @supervisor
          params = {"assignment_id" => "assignment", "attempt_id" => @attempt, "expected_generation" => generation,
            "candidate_generation" => 1, "head" => @head, "result_id" => result.fetch("result_id")}
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
            "assignment_id" => "assignment", "attempt_id" => @attempt, "purpose_id" => review.fetch("review_id")),
            mutation_id: "finish-review-accept", timeout: 30, upload_parts: input.parts, purpose: :receipt_artifacts).data
          refute_nil accepted_review.fetch("receipt_digest")
          @kernel.dead << @worker.fetch("pid")
          @kernel.peer_identity = @supervisor
          params["expected_generation"] = generation
          first = @client.call("finish", params, mutation_id: "success-finish", timeout: 30)
          assert_equal "succeeded", first.data.fetch("state")
          accepted = @journal.ref_value
          assert_equal "succeeded", terminal_projection!(params, accepted).fetch("canonical_state")
          replay = @client.call("finish", params, mutation_id: "success-finish", timeout: 30)
          assert replay.replayed
          assert_equal first.data, replay.data
          assert_equal accepted, @journal.ref_value
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
              blobs: {}, data: first.data.except("generation", "journal_commit")}
          end
          assert_equal "succeeded", forged.fetch("state")
          error = assert_raises(AttemptErrors::ReceiptRejected) do
            @launch.completion_terminal!(journal: @journal, commit: @journal.ref_value,
              params: params.merge("mapping_id" => "mapping"), map: @map)
          end
          assert_match(/exact independent review/, error.message)
        end
      end
    end
  end
end
