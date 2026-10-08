# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../support/execution_scope_observation_fixtures"
require_relative "../support/protected_inbox_context_pipeline_fixture"
require "ace/assign/authority/endcap"
require "ace/herdr/organisms/inbox"
require "ace/herdr/organisms/inbox_context_owner"
require "ace/herdr/organisms/inbox_context_server"
require "ace/assign/authority/inbox_context_completion"
require "ace/assign/authority/inbox_context_original"
require "ace/assign/authority/server"
require "ace/assign/authority/router"
require "ace/herdr/cli"
require_relative "../../../ace-herdr/test/support/inbox_context_owner_fixture"

module Ace
  module Assign
    # Actual canonical Git CAS and Inbox signature/event lock; source fixtures
    # stand in for installed identities, never an installed scope/closure claim.
    class EndcapInboxesTest < AceAssignTestCase
      include ProtectedInboxContextPipelineFixture
      BOOT = "12345678-1234-1234-1234-123456789abc"
      class Kernel
        attr_accessor :dead, :authority_peer
        def live!(identity)
          raise AttemptErrors::EvidenceUnavailable, "dead peer" if Array(dead).include?(identity["pid"])
        end
        def capture(_pid); authority_peer; end
        def same?(left, right); left == right; end
        def supported!; raise "consumed proof must not open native endpoint"; end
      end
      class Launch
        attr_reader :journals, :locked
        def initialize(journal, launcher); @journal, @launcher = journal, launcher; @journals = {"project" => journal}; end
        def with_assignment(params:, map:)
          @locked = true
          yield @journal, {}
        ensure
          @locked = false
        end
        def origin(*, **); {"launcher_identity" => @launcher}; end
      end
      Parts = Struct.new(:parts) do
        def count; parts.size; end
        def bytes(index: 0); parts.fetch(index); end
      end

      def test_historical_malformed_canonical_shapes_refuse_with_typed_unavailability
        journal = Object.new
        journal.define_singleton_method(:evidence_mode) { :protected }
        context = {"native_mapping_id" => "mapping"}
        deployment = Object.new
        deployment.define_singleton_method(:inbox_context) { |*| context }
        verifier = Authority::HistoricalInboxEvidence.new(journal: journal, deployment: deployment, history: Object.new)
        params = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt"}
        registration = {"event_id" => "event", "attempt_id" => "attempt", "payload_sha256" => "a" * 64, "receipt_key_sha256" => "b" * 64}
        payloads = [nil, "scalar", {"attempt_id" => "attempt", "event_id" => "event", "inbox_context_id" => "context", "registration" => registration}]
        payloads.each do |payload|
          event = {"type" => "inbox_binding", "payload" => payload}
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            verifier.verify!(events: [event], params: params, map: {"project_id" => "project"}, commit: "a" * 40)
          end
        end
      end

      def test_original_query_joins_accepted_guard_and_registration_without_effect_permission
        fixture(child: true, inbox: false, original_terminal: "term_aa") do
          @context["owner_credentials"] = @context_peer.slice("uid", "gid", "groups")
          child = events.find { |event| event["type"] == "scope_child_bound" }.dig("payload", "original_process_binding")
          guard = {"terminal_id" => child.fetch("terminal_id"), "runtime_incarnation" => BOOT,
            "child" => child.fetch("process_identity")}
          data = @params.merge("process_binding" => child, "guarded_origin" => guard)
          mutate("record_launch", "record-original", 5, {data: data})
          query = Authority::InboxContextOriginal.new(deployment: @deployment, history: @history,
            authority_id: "authority", journals: {"project" => @journal}, kernel: @kernel)
          params = @params.merge("event_id" => "event", "inbox_context_id" => "context", "purpose" => "enqueue",
            "payload_sha256" => Digest::SHA256.hexdigest("message"), "receipt_key_sha256" => Digest::SHA256.hexdigest(@key.public_to_der))
          request = {"version" => 1, "operation" => "inbox_context_original", "mutation_id" => nil,
            "project_id" => "project", "params" => params}
          start_context_pipeline(File.dirname(@context.fetch("deliveries_dir")))
          before = @journal.ref_value
          result = @context_completion.original!(**params.reject { |key, _| key == "mapping_id" }.transform_keys(&:to_sym))
          assert_equal child, result.fetch("process_binding")
          assert_equal guard, result.fetch("guarded_origin")
          refute result.fetch("registered")
          refute result.key?("agent_session")
          assert result.frozen?
          assert result.fetch("process_binding").frozen?
          assert_equal before, @journal.ref_value
          stop_context_pipeline
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            query.dispatch(request: request.merge("params" => params.merge("purpose" => "deliver")), peer: @context_peer, role: :context_owner)
          end
          assert_raises(AttemptErrors::UnauthorizedIdentity) { query.dispatch(request: request, peer: @peer, role: :context_owner) }
          registration = result.fetch("registration")
          mutate("fixture_registration", "original-registration", 6, {data: {}, events: [{type: "inbox_binding", payload: {
            "event_id" => "event", "attempt_id" => "attempt", "inbox_context_id" => "context", "registration" => registration}}]})
          accepted = request.merge("params" => params.merge("purpose" => "deliver"))
          assert query.dispatch(request: accepted, peer: @context_peer, role: :context_owner).fetch(:data).fetch("registered")
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            query.dispatch(request: accepted.merge("params" => accepted.fetch("params").merge("payload_sha256" => "f" * 64)), peer: @context_peer, role: :context_owner)
          end
        end
      end

      def fixture(child: false, inbox: true, direct: false, original_terminal: "terminal")
        @direct_fixture = direct
        Dir.mktmpdir do |root|
          root = File.realpath(root)
          repo = File.join(root, "repo"); FileUtils.mkdir_p(repo)
          git_in(repo, "init", "-b", "main")
          git_in(repo, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "fixture")
          @journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(root, "checkout"), mode: :protected,
            evidence_reader: ->(*) { raise "unused" }, service_authorizer: ->(*) { raise "unused" })
          @peer = process(82, 13004)
          @launcher = process(81, 13002)
          server = process(90, 13001)
          @map = {"project_id" => "project", "authority_id" => "authority", "launcher_uid" => 13002, "native" => {}, "execution_scope" => {"slot_id" => "slot"}}
          key = OpenSSL::PKey::RSA.new(2048)
          @key = key
          key_path = File.join(root, "public.pem"); File.write(key_path, key.public_to_pem)
          @context = {"native_mapping_id" => "mapping", "supervisor_uids" => [13004], "deliveries_dir" => File.join(root, "deliveries"),
            "receipt_public_key" => key_path, "pi_queue_client" => "/absent/client"}
          @unsafe = false
          @deployment = Object.new
          owner = self
          @deployment.define_singleton_method(:project) do |_|
            journal = owner.instance_variable_get(:@journal)
            {"inbox_contexts" => {"context" => owner.instance_variable_get(:@context)}, "journal_repository" => journal.repo_root,
              "evidence_git_ref" => journal.ref, "evidence_checkout_root" => journal.checkout_root}
          end
          @deployment.define_singleton_method(:mapping_digest) { |_| Atoms::EvidenceDigest.digest(owner.instance_variable_get(:@map)) }
          @deployment.define_singleton_method(:mapping) { |id| raise KeyError unless id == "mapping"; owner.instance_variable_get(:@map) }
          @deployment.define_singleton_method(:inbox_context) { |_mapping, id| raise AttemptErrors::EvidenceUnavailable unless id == "context"; owner.instance_variable_get(:@context) }
          @deployment.define_singleton_method(:verify_inbox_context!) { |*| raise Ace::Runtime::RuntimeUnavailableError if owner.instance_variable_get(:@unsafe); true }
          @kernel = Kernel.new
          @authority_peer = process(83, 13000)
          @context_peer = process(84, 13007)
          @kernel.authority_peer = @authority_peer
          @descriptor_sha256 = Digest::SHA256.hexdigest(JSON.generate(@map))
          @retained_key = key.public_key
          @history = Object.new
          @history.define_singleton_method(:descriptor!) do |sha256:|
            raise AttemptErrors::EvidenceUnavailable unless sha256 == owner.instance_variable_get(:@descriptor_sha256)
            owner.instance_variable_get(:@deployment)
          end
          @history.define_singleton_method(:public_key!) do |sha256:|
            selected = owner.instance_variable_get(:@retained_key)
            raise AttemptErrors::EvidenceUnavailable unless sha256 == Digest::SHA256.hexdigest(selected.public_to_der)
            selected
          end
          @policy = Object.new
          @policy.define_singleton_method(:visible!) { |**| true }
          restart
          mutate("reserve_attempt", "reserve", 0, {data: {"project_id" => "project", "assignment_id" => "assignment",
            "attempt_id" => "attempt", "mapping_id" => "mapping", "reservation_generation" => 1, "launch_ticket" => "ticket"},
            events: [{type: "intent", payload: {"scope" => "010"}}, {type: "scope_provisioning", payload: {
              "descriptor_sha256" => @descriptor_sha256, "deployment_digest" => @deployment.mapping_digest("mapping"),
              "reservation_generation" => 1, "slot_id" => "slot"}}]})
          parent = {"project_id" => "project", "assignment_id" => "assignment", "attempt_id" => "attempt", "mapping_id" => "mapping",
            "slot_id" => "slot", "reservation_generation" => 1, "scope_generation" => 2, "deployment_digest" => @deployment.mapping_digest("mapping"),
            "boot_id" => BOOT, "slice_invocation_id" => "b" * 32,
            "boot_baseline_selection" => ExecutionScopeObservationFixtures::BOOT_BASELINE_SELECTION, "network_installation_selection" => ExecutionScopeObservationFixtures::NETWORK_SELECTION,
            "network_namespace_identity" => {"device" => 7, "inode" => 88},
            "resource_mount_namespace_identity" => {"device" => 4, "inode" => 1111},
            "cgroup_identity" => {"path" => "/sys/fs/cgroup/slot.slice", "mount_id" => 1, "filesystem_type" => "cgroup2", "device" => 2, "inode" => 3},
            "resource_identities" => [{"host_path" => "/var/lib/slot", "view_path" => "/scratch", "mount_id" => 4,
              "filesystem_type" => "ext4", "device" => 5, "inode" => 6, "uid" => 13001, "gid" => 13001}]}
          mutate("fixture_parent", "parent", 1, {data: {}, events: [{type: "scope_bound", payload: parent}]})
          parent_event = events.find { |event| event["type"] == "scope_bound" }
          mutate("scope_service_admission", "admission", 2, {data: parent.slice("project_id", "assignment_id", "attempt_id", "mapping_id").merge(
            "scope_generation" => 2, "scope_binding_event_id" => parent_event.fetch("digest"),
            "native_admission" => "issued_uncertain", "network_installation" => ExecutionScopeObservationFixtures::NETWORK_OUTPUT)})
          admission = events.find { |event| event.dig("payload", "operation") == "scope_service_admission" }
          mutate("fixture_native", "native", 3, {data: {}, events: [{type: "scope_native_bound", payload: {
            "scope_generation" => 2, "scope_binding_event_id" => parent_event.fetch("digest"), "service_invocation_id" => "c" * 32,
            "server_identity" => server, "socket_identity" => [1, 2, 13001], "workspace_id" => "w1",
            "mount_namespace_identity" => {"device" => 4, "inode" => 2222}, "resource_observer_identity" => process(92, 13001),
            "resource_identities" => parent.fetch("resource_identities").map { |resource| resource.merge("mount_id" => 99) },
            "network_namespace_identity" => parent.fetch("network_namespace_identity"), "network_admission_event_id" => admission.fetch("digest")}}]})
          if child
            original = {"runtime" => "herdr", "session" => "w1", "pane" => "p1", "terminal_id" => original_terminal,
              "process_identity" => process(91, 13001).merge("parent_pid" => 90), "shell_identity" => process(91, 13001).merge("parent_pid" => 90),
              "native_origin" => {"workspace" => "w1", "tab" => "t1", "pane" => "p1", "server_identity" => server,
                "socket_identity" => [1, 2, 13001], "command" => ["/fixture/gate", "mapping", "ticket"], "cwd" => "/scratch"}}
            mutate("fixture_child", "child", 4, {data: {}, events: [{type: "scope_child_bound", payload: {
              "scope_generation" => 2, "scope_binding_event_id" => parent_event.fetch("digest"),
              "native_binding_event_id" => events.find { |event| event["type"] == "scope_native_bound" }.fetch("digest"),
              "original_process_binding" => original}}]})
          end
          unless inbox
            FileUtils.mkdir_p(@context.fetch("deliveries_dir"))
            @params = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt"}
            yield
            next
          end
          executor = Object.new
          executor.define_singleton_method(:pane_get_bounded) do |_pane|
            Ace::Herdr::Molecules::ExecutionResult.new(stdout: JSON.generate("result" => {"pane" => {
              "pane_id" => "p1", "workspace_id" => "w1", "terminal_id" => "terminal", "agent" => "codex", "agent_status" => "busy",
              "agent_session" => {"agent" => "codex", "kind" => "id", "value" => "0123abcd-0000-4000-8000-000000000001"}}}),
              stderr: "", success: true, exit_code: 0)
          end
          native = Object.new
          @native_calls = 0
          native.define_singleton_method(:submit) do |**|
            owner.instance_variable_set(:@native_calls, owner.instance_variable_get(:@native_calls) + 1)
            direct ? {"accepted" => false, "error" => "controlled lost native acknowledgement"} : {"accepted" => true}
          end
          @box = Ace::Herdr::Organisms::Inbox.new(executor: executor, native: native, deliveries_dir: @context.fetch("deliveries_dir"), receipt_public_key: key.public_key)
          @box.enqueue(event: "event", attempt: "attempt", ref: {"session" => "w1", "pane" => "p1"}, payload: "message")
          record = direct ? @box.retained_status(event: "event") : @box.deliver(event: "event")
          @registration = record.slice("event_id", "attempt_id", "payload_sha256", "receipt_key_sha256")
          mutate("fixture_registration", "registration", child ? 5 : 4, {data: {}, events: [{type: "inbox_binding", payload: {
            "event_id" => "event", "attempt_id" => "attempt", "inbox_context_id" => "context", "registration" => @registration}}]})
          receipt = record.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding").merge(
            "outcome" => "consumed", "observer" => {"role" => "supervisor", "id" => "observer"},
            "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => "native:1", "observation" => "consumed"})
          @bytes = JSON.generate(receipt); @signature = key.sign(OpenSSL::Digest::SHA256.new, @bytes)
          start_context_pipeline(root)
          restart
          @params = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt",
            "expected_generation" => child ? 6 : 5, "event_id" => "event", "inbox_context_id" => "context", "expected_registration" => @registration,
            "receipt_sha256" => Digest::SHA256.hexdigest(@bytes), "signature_sha256" => Digest::SHA256.hexdigest(@signature), "transfer" => {}}
          yield
        ensure
          stop_context_pipeline
        end
      end

      def process(pid, uid)
        {"pid" => pid, "uid" => uid, "gid" => uid, "groups" => [uid], "parent_pid" => 1,
          "started_at" => "linux:#{BOOT}:#{pid}", "host" => "fixture"}
      end
      def events; @journal.read_events("assignment").select { |event| event["attempt_id"] == "attempt" }; end
      def mutate(operation, id, generation, plan)
        @journal.mutate(assignment_id: "assignment", attempt_id: "attempt", mutation_id: id, operation: operation,
          parameters_digest: Digest::SHA256.hexdigest(id), expected_generation: generation) { plan }
      end
      def restart
        @launch = Launch.new(@journal, @launcher)
        @owner = Authority::Endcap.new(deployment: @deployment, launch: @launch, kernel: @kernel, service_policy: @policy,
          inbox_context_clients: @context_clients, deployment_history: @history)
      end
      def reconcile(params: @params, peer: @peer, role: :supervisor, id: "reconcile", parts: [@bytes, @signature])
        @owner.dispatch(request: {"operation" => "reconcile_inbox", "project_id" => "project", "mutation_id" => id, "params" => params},
          peer: peer, role: role, transfer: Parts.new(parts))
      end

      def test_signed_consumed_import_replay_fetch_and_corruption_after_native_stop
        fixture do
          result = reconcile
          assert_equal "completed", result.dig(:data, "state")
          assert_equal 6, result.dig(:data, "generation")
          assert_equal 2, events.count { |event| event["type"] == "evidence_import" }
          @kernel.dead = [90, 91]
          restart
          replay = reconcile
          assert replay.fetch(:replayed)
          assert_equal result.fetch(:data), replay.fetch(:data)
          ref = result.dig(:data, "receipt_ref")
          request = {"operation" => "evidence_fetch", "project_id" => "project", "mutation_id" => nil, "params" => {
            "mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt", "kind" => "inbox",
            "purpose_id" => "event", "artifact_id" => ref.fetch("artifact_id")}}
          fetched = @owner.dispatch(request: request, peer: @peer, role: :supervisor)
          assert_equal [@bytes], fetched.fetch(:transfer_parts)
          assert_equal "signer", fetched.dig(:data, "descriptor", "role")
          @journal.stub(:blob, "corrupt") do
            assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
            assert_raises(AttemptErrors::EvidenceUnavailable) { @owner.dispatch(request: request, peer: @peer, role: :supervisor) }
          end
        end
      end

      def test_returned_direct_issuer_is_retired_by_actual_canonical_confirmation_and_restarted_exact_replay
        fixture(direct: true) do
          admission = @context_owner.begin_context_operation(context_id: "context", purpose: "deliver", event_id: "event",
            process_binding: @peer, peer: @peer)
          reply = @context_owner.deliver_context(operation_id: admission.fetch("operation_id"), key_generation: 1,
            event_id: "event", attempt_id: "attempt", expected_claim_generation: 0, peer: @peer)
          assert_equal "unknown", reply.fetch("admission_state")
          assert_equal "uncertain", reply.dig("record", "state")
          assert_equal 1, @native_calls
          state = @context_store.transaction { |value| JSON.parse(JSON.generate(value)) }
          operation = state.fetch("operations").fetch(admission.fetch("operation_id"))
          assert_equal "returned", operation.fetch("issuer_state")
          assert_equal 1, operation.fetch("admitted_claim").fetch("claim_generation")
          receipt = reply.fetch("record").slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding").merge(
            "outcome" => "consumed", "observer" => {"role" => "supervisor", "id" => "observer"},
            "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => "native:1", "observation" => "consumed"})
          @bytes = JSON.generate(receipt); @signature = @key.sign(OpenSSL::Digest::SHA256.new, @bytes)
          @params = @params.merge("receipt_sha256" => Digest::SHA256.hexdigest(@bytes), "signature_sha256" => Digest::SHA256.hexdigest(@signature))
          @context_store.close
          @context_store = Ace::Herdr::Molecules::InboxContextStore.new(root: @context_state_root, uid: Process.uid, protection: InboxContextOwnerFixture::FixturePaths.new)
          @context_owner = Ace::Herdr::Organisms::InboxContextOwner.new(context_id: "context", deliveries_dir: @context.fetch("deliveries_dir"),
            grants: @context_grants, store: @context_store, keys: @context_keys, kernel: @kernel, inbox: @box, completion: @context_completion, epoch: context_owner_epoch)
          result = reconcile
          assert_equal "completed", result.dig(:data, "state")
          assert_nil @box.prepare_direct_delivery(event: "event", expected_claim_generation: 1,
            expected_attempt: "attempt", claim_owner: "b" * 64)
          assert_equal 1, @native_calls
          assert_equal 0, @context_owner.status(peer: @authority_peer).fetch("active_operations")
          assert_raises(Ace::Herdr::ValidationError) { @context_owner.end_context_operation(operation_id: admission.fetch("operation_id"), peer: @peer) }
          replay = reconcile
          assert replay.fetch(:replayed)
          assert_equal result.fetch(:data), replay.fetch(:data)
          assert_equal 1, @native_calls
          assert_equal 1, events.count { |event| event["type"] == "inbox_reconciliation" }
          assert_equal 2, events.count { |event| event["type"] == "evidence_import" }
        end
      end

      def prepare_direct_consumed_proof
        record = @box.retained_status(event: "event")
        receipt = record.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding").merge(
          "outcome" => "consumed", "observer" => {"role" => "supervisor", "id" => "observer"},
          "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => "native:1", "observation" => "consumed"})
        @bytes = JSON.generate(receipt); @signature = @key.sign(OpenSSL::Digest::SHA256.new, @bytes)
        @params = @params.merge("receipt_sha256" => Digest::SHA256.hexdigest(@bytes), "signature_sha256" => Digest::SHA256.hexdigest(@signature))
      end

      def direct_admission_and_arguments
        admission = @context_owner.begin_context_operation(context_id: "context", purpose: "deliver", event_id: "event",
          process_binding: @peer, peer: @peer)
        [admission, {operation_id: admission.fetch("operation_id"), key_generation: 1,
          event_id: "event", attempt_id: "attempt", expected_claim_generation: 0, peer: @peer}]
      end

      def test_genuine_consumed_proof_cannot_clear_crash_before_durable_issuer_return
        fixture(direct: true) do
          admission, args = direct_admission_and_arguments
          @context_store.singleton_class.class_eval do
            define_method(:persist!) do |state|
              raise Ace::Herdr::ValidationError, "controlled crash before returned commit" if state.fetch("operations").values.any? { |item| item["issuer_state"] == "returned" }
              super(state)
            end
          end
          assert_raises(Ace::Herdr::ValidationError) { @context_owner.deliver_context(**args) }
          assert_equal 1, @native_calls
          @context_store.singleton_class.send(:remove_method, :persist!)
          prepare_direct_consumed_proof
          assert_equal "completed", reconcile.dig(:data, "state")
          retained = @context_store.transaction { |state| JSON.parse(JSON.generate(state.fetch("operations").fetch(admission.fetch("operation_id")))) }
          assert_equal "running", retained.fetch("issuer_state")
          assert_equal 1, retained.fetch("in_flight")
          assert_raises(Ace::Herdr::ValidationError) { @context_owner.end_context_operation(operation_id: admission.fetch("operation_id"), peer: @peer) }
          assert reconcile.fetch(:replayed)
          assert_equal 1, @context_owner.status(peer: @authority_peer).fetch("active_operations")
          assert_equal 1, @native_calls
        end
      end

      def test_foreign_same_event_reconciliation_admitted_after_query_prevents_retirement_until_exact_replay
        fixture(direct: true) do
          admission, args = direct_admission_and_arguments
          @context_owner.deliver_context(**args)
          prepare_direct_consumed_proof
          actual_read = @context_query_wire.method(:read)
          test = self
          foreign = @authority_peer.merge("pid" => 85, "started_at" => "linux:#{BOOT}:85")
          foreign_admission = nil
          @context_query_wire.define_singleton_method(:read) do |*arguments, **options|
            proof = actual_read.call(*arguments, **options)
            foreign_admission ||= test.instance_variable_get(:@context_owner).begin_context_operation(context_id: "context", purpose: "reconcile",
              event_id: "event", process_binding: foreign, peer: foreign)
            proof
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
          state = @context_store.transaction { |value| JSON.parse(JSON.generate(value)) }
          direct = state.fetch("operations").fetch(admission.fetch("operation_id"))
          assert_equal "returned", direct.fetch("issuer_state")
          assert_equal 1, direct.fetch("in_flight")
          original = state.fetch("operations").values.find { |item| item["effect_binding"]&.fetch("schema") == "ace.herdr.inbox-context-effect/v1" }
          assert_nil original.fetch("completion"), "failed post-query admission check cannot partially confirm"
          assert_equal 1, events.count { |event| event["type"] == "inbox_reconciliation" }
          @context_query_wire.define_singleton_method(:read) { |*arguments, **options| actual_read.call(*arguments, **options) }
          @context_owner.end_context_operation(operation_id: foreign_admission.fetch("operation_id"), peer: foreign)
          assert reconcile.fetch(:replayed)
          assert_equal 0, @context_owner.status(peer: @authority_peer).fetch("active_operations")
          assert_equal 1, @native_calls
        end
      end

      def test_registered_herdr_reconciliation_uses_actual_existing_authority_upload_and_canonical_replay
        fixture do
          project_method = @deployment.method(:project)
          selected_peer = @peer
          @deployment.define_singleton_method(:project) do |id|
            project_method.call(id).merge("peer_credentials" => {selected_peer.fetch("uid").to_s => selected_peer.slice("gid", "groups")},
              "reviewer_uids" => [], "service_executor_uids" => [], "supervisor_uids" => [selected_peer.fetch("uid")])
          end
          # Real protected ancestry: /tmp intentionally fails the production
          # transfer-spool ancestry gate even when its leaf is private.
          state_root = File.realpath(Dir.mktmpdir("inbox-authority-", File.realpath(".ace-local")))
          authority_method = @deployment.method(:authority)
          @deployment.define_singleton_method(:authority) { |id| authority_method.call(id).merge("state_root" => state_root) }
          path = File.join(@socket_root, "mutate.sock")
          listener = UNIXServer.new(path)
          server = Authority::Server.new(authority_id: "authority", deployment: @deployment, lifecycle: Authority::Router.new(launch: @owner),
            kernel: ProtectedInboxContextPipelineFixture::PeerKernel.new(@peer), composition: "services")
          server.define_singleton_method(:refusal) do |socket, code|
            @observed_refusal = code
            @observed_error = [$!&.class&.name, $!&.message]
            super(socket, code)
          end
          workers = []; stopping = false
          acceptor = Thread.new do
            until stopping
              socket = listener.accept
              workers << Thread.new(socket) do |connection|
                server.send(:receive, connection)
              ensure
                connection.close
              end
            end
          rescue IOError, Errno::EBADF
            raise unless stopping
          end
          selected = {"project_id" => "project", "mapping_id" => "mapping", "inbox_context_id" => "context",
            "authority" => @authority_peer.slice("uid", "gid", "groups").merge("socket_path" => path)}
          selection = Object.new
          selection.define_singleton_method(:with) { |_options, &block| block.call(selected) }
          wire = ProtectedInboxContextPipelineFixture::SocketFixtureWire.new(@socket_root, @authority_peer.fetch("uid"))
          kernel = ProtectedInboxContextPipelineFixture::PeerKernel.new(@authority_peer)
          factory = ->(selection:) { Ace::Herdr::Molecules::InboxReconciliationClient.new(selection: selection, kernel: kernel, wire: wire) }
          command = Ace::Herdr::CLI.resolve(["inbox"]).first
          previous = %i[@selection @reconciliation_client_factory].to_h { |key| [key, command.instance_variable_get(key)] }
          command.instance_variable_set(:@selection, selection); command.instance_variable_set(:@reconciliation_client_factory, factory)
          command.define_singleton_method(:config) { raise "local Inbox must not be constructed" }
          proof = File.join(@socket_root, "proof.json"); File.binwrite(proof, @bytes); File.binwrite("#{proof}.sig", @signature)
          arguments = %w[inbox reconcile --project project --mapping mapping --inbox-context context --assignment assignment --attempt attempt --event event] +
            ["--receipt", proof, "--mutation", "reconcile", "--expected-generation", "5", "--receipt-key-sha256", @registration.fetch("receipt_key_sha256")]
          out, err = capture_io do
            assert_equal 0, Ace::Herdr::CLI.start(arguments)
          rescue Ace::Support::Cli::Error => error
            raise error.class, "#{error.message} (actual source server refusal #{server.instance_variable_get(:@observed_refusal)}: #{server.instance_variable_get(:@observed_error).inspect})"
          end
          assert_empty err
          first = JSON.parse(out)
          assert_equal "completed", first.fetch("state")
          refute first.fetch("replayed")
          refute first.key?("context_operation")
          out, = capture_io { assert_equal 0, Ace::Herdr::CLI.start(arguments) }
          replay = JSON.parse(out)
          assert replay.fetch("replayed")
          assert_equal first.reject { |key, _| key == "replayed" }, replay.reject { |key, _| key == "replayed" }
          assert_equal 1, events.count { |event| event["type"] == "inbox_reconciliation" }
          assert_equal 2, events.count { |event| event["type"] == "evidence_import" }
          assert_equal 0, @context_owner.status(peer: @authority_peer).fetch("active_operations")
        ensure
          previous&.each { |key, value| command.instance_variable_set(key, value) }
          command&.singleton_class&.send(:remove_method, :config) if command&.singleton_class&.instance_methods(false)&.include?(:config)
          stopping = true; listener&.close; acceptor&.value
          workers&.each(&:value)
          FileUtils.remove_entry(state_root) if state_root && File.exist?(state_root)
        end
      end

      def test_stale_known_idle_readonly_delivery_does_not_block_actual_canonical_retirement
        fixture(direct: true) do
          counter = self
          @box.instance_variable_get(:@native).define_singleton_method(:submit) do |**|
            counter.instance_variable_set(:@native_calls, counter.instance_variable_get(:@native_calls) + 1)
            {"accepted" => true}
          end
          first, args = direct_admission_and_arguments
          assert_equal "idle", @context_owner.deliver_context(**args).fetch("admission_state")
          @context_owner.end_context_operation(operation_id: first.fetch("operation_id"), peer: @peer)
          stale, stale_args = direct_admission_and_arguments
          assert_equal "idle", @context_owner.deliver_context(**stale_args).fetch("admission_state")
          operation = @context_store.transaction { |value| JSON.parse(JSON.generate(value.fetch("operations").fetch(stale.fetch("operation_id")))) }
          assert_equal ["returned", nil, 0], operation.values_at("issuer_state", "admitted_claim", "in_flight")
          assert_equal 1, @native_calls
          prepare_direct_consumed_proof
          assert_equal "completed", reconcile.dig(:data, "state")
          assert_equal 0, @context_owner.status(peer: @authority_peer).fetch("active_operations")
          assert reconcile.fetch(:replayed)
          assert_equal 1, @native_calls
        end
      end

      def prepare_direct_superseded_proof
        prepare_direct_consumed_proof
        receipt = JSON.parse(@bytes)
        receipt["outcome"] = "superseded"
        receipt.fetch("evidence")["kind"] = "queue_evicted"
        @bytes = JSON.generate(receipt); @signature = @key.sign(OpenSSL::Digest::SHA256.new, @bytes)
        @params = @params.merge("receipt_sha256" => Digest::SHA256.hexdigest(@bytes), "signature_sha256" => Digest::SHA256.hexdigest(@signature))
      end

      def test_private_supersession_refuses_retry_until_canonical_confirmation_then_one_exact_claim
        fixture(direct: true) do
          original, args = direct_admission_and_arguments
          @context_owner.deliver_context(**args)
          prepare_direct_superseded_proof
          @box.reconcile(event: "event", receipt: JSON.parse(@bytes), signed_bytes: @bytes,
            signature: @signature, expected_registration: @registration)
          assert_equal "queued", @box.retained_status(event: "event").fetch("state")
          before = File.binread(File.join(@context.fetch("deliveries_dir"), "event.json"))
          assert_raises(Ace::Herdr::ValidationError) do
            @box.prepare_direct_delivery(event: "event", expected_claim_generation: 1,
              expected_attempt: "attempt", claim_owner: "b" * 64)
          end
          assert_equal before, File.binread(File.join(@context.fetch("deliveries_dir"), "event.json"))
          assert_equal 1, @native_calls
          assert_equal "queued", reconcile.dig(:data, "state")
          marker = JSON.parse(File.binread(File.join(@context.fetch("deliveries_dir"), "event.json"))).dig("inbox", "canonical_completion")
          assert_equal 1, marker.fetch("claim_generation")
          assert_equal @registration, marker.fetch("registration")
          assert_equal 0, @context_owner.status(peer: @authority_peer).fetch("active_operations")
          retry_admission, retry_args = direct_admission_and_arguments
          retained_path = File.join(@context.fetch("deliveries_dir"), "event.json")
          retained_bytes = File.binread(retained_path)
          [marker.merge("claim_generation" => 2), marker.merge("claim_generation" => true),
            marker.merge("parsed_receipt_sha256" => "f" * 64), marker.merge("native_binding_sha256" => "f" * 64),
            marker.merge("commit" => "invalid"), marker.merge("extra" => true),
            marker.merge("registration" => marker.fetch("registration").merge("event_id" => "foreign"))].each do |bad|
            value = JSON.parse(retained_bytes); value.fetch("inbox")["canonical_completion"] = bad
            File.binwrite(retained_path, JSON.generate(value))
            assert_raises(Ace::Herdr::ValidationError) { @context_owner.deliver_context(**retry_args.merge(expected_claim_generation: 1)) }
            assert_equal 1, @native_calls
          end
          File.binwrite(retained_path, retained_bytes)
          result = @context_owner.deliver_context(**retry_args.merge(expected_claim_generation: 1))
          assert_equal 2, result.dig("record", "claim_generation")
          assert_equal 2, @native_calls
          refute JSON.parse(File.binread(File.join(@context.fetch("deliveries_dir"), "event.json"))).fetch("inbox").key?("canonical_completion")
          assert_equal result, @context_owner.deliver_context(**retry_args.merge(expected_claim_generation: 1))
          assert_equal 2, @native_calls
          current = @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
          assert_equal current, @journal.ref_value
          retained = @context_store.transaction { |value| JSON.parse(JSON.generate(value.fetch("operations"))) }
          assert_equal [retry_admission.fetch("operation_id")], retained.keys
          assert_equal 2, retained.fetch(retry_admission.fetch("operation_id")).fetch("admitted_claim").fetch("claim_generation")
          assert_equal 1, events.count { |event| event["type"] == "inbox_reconciliation" }
          assert_equal 2, @native_calls
        end
      end

      def test_canonical_marker_save_before_context_failure_blocks_retry_until_exact_confirmation_replay
        fixture(direct: true) do
          original, args = direct_admission_and_arguments
          @context_owner.deliver_context(**args)
          prepare_direct_superseded_proof
          @context_store.singleton_class.class_eval do
            define_method(:persist!) do |state|
              raise Ace::Herdr::ValidationError, "controlled failure after event completion save" if state.fetch("operations").values.any? { |operation| operation["completion"] }
              super(state)
            end
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
          record = JSON.parse(File.binread(File.join(@context.fetch("deliveries_dir"), "event.json")))
          assert_equal 1, record.dig("inbox", "canonical_completion", "claim_generation")
          retained = @context_store.transaction { |value| JSON.parse(JSON.generate(value.fetch("operations"))) }
          assert_equal "returned", retained.fetch(original.fetch("operation_id")).fetch("issuer_state")
          assert_equal 1, retained.fetch(original.fetch("operation_id")).fetch("in_flight")
          assert retained.values.any? { |operation| operation.fetch("purpose") == "reconcile" && operation.fetch("completion").nil? }
          assert_raises(Ace::Herdr::ValidationError) { @context_owner.deliver_context(**args.merge(expected_claim_generation: 1)) }
          assert_equal 1, @native_calls
          @context_store.singleton_class.send(:remove_method, :persist!)
          original_commit = record.dig("inbox", "canonical_completion", "commit")
          @journal.record(assignment_id: "unrelated", attempt_id: "unrelated", type: "intent", payload: {"scope" => "010"})
          refute_equal original_commit, @journal.ref_value
          assert reconcile.fetch(:replayed)
          assert_equal original_commit, JSON.parse(File.binread(File.join(@context.fetch("deliveries_dir"), "event.json"))).dig("inbox", "canonical_completion", "commit")
          assert_equal 0, @context_owner.status(peer: @authority_peer).fetch("active_operations")
          retry_admission, retry_args = direct_admission_and_arguments
          assert_equal 2, @context_owner.deliver_context(**retry_args.merge(expected_claim_generation: 1)).dig("record", "claim_generation")
          assert_equal 2, @native_calls
        end
      end

      def test_new_reconciliation_between_retry_entry_and_claim_preparation_refuses_without_native_effect
        fixture(direct: true) do
          original, args = direct_admission_and_arguments
          @context_owner.deliver_context(**args)
          prepare_direct_superseded_proof
          reconcile
          retry_admission, retry_args = direct_admission_and_arguments
          actual = @context_store.method(:transaction)
          foreign = @authority_peer.merge("pid" => 85, "started_at" => "linux:#{BOOT}:85")
          owner = @context_owner
          interrupted = false
          @context_store.define_singleton_method(:transaction) do |&block|
            result = actual.call(&block)
            unless interrupted
              # Inspect through the real transaction, after the original one
              # released its mutex. Inject only the concurrent admission seam.
              pending = actual.call { |value| value.fetch("operations")[retry_admission.fetch("operation_id")] }
              if pending && pending["issuer_state"] == "running" && pending["admitted_claim"].nil?
                interrupted = true
                owner.begin_context_operation(context_id: "context", purpose: "reconcile", event_id: "event",
                  process_binding: foreign, peer: foreign)
              end
            end
            result
          end
          assert_raises(Ace::Herdr::ValidationError) { @context_owner.deliver_context(**retry_args.merge(expected_claim_generation: 1)) }
          assert interrupted, "the concurrent admission must occur after actual direct entry and before claim preparation"
          assert_equal 1, @native_calls
          assert_equal 1, @box.retained_status(event: "event").fetch("claim_generation")
          retained = actual.call { |value| JSON.parse(JSON.generate(value.fetch("operations"))) }
          direct = retained.fetch(retry_admission.fetch("operation_id"))
          assert_equal ["running", nil, 1], direct.values_at("issuer_state", "admitted_claim", "in_flight")
          assert retained.values.any? { |operation| operation["purpose"] == "reconcile" }
        end
      end

      def test_historical_consumption_uses_original_public_key_and_canonical_prefix_without_native_discovery
        fixture(child: true) do
          reconcile
          commit = @journal.ref_value
          prefix = events
          original_key = @key.public_key
          fingerprint = @registration.fetch("receipt_key_sha256")
          history = Object.new
          history.define_singleton_method(:public_key!) do |sha256:|
            raise AttemptErrors::EvidenceUnavailable, "missing original key" unless sha256 == fingerprint
            original_key
          end
          File.write(@context.fetch("receipt_public_key"), OpenSSL::PKey::RSA.new(1024).public_to_pem)
          @deployment.define_singleton_method(:verify_inbox_context!) { |*| raise "history must not inspect current key/native paths" }
          assert @owner.historical_inbox_settlement_complete!(journal: @journal, events: prefix,
            params: @params, map: @map, commit: commit, deployment: @deployment, history: history)
          history.define_singleton_method(:public_key!) { |sha256:| OpenSSL::PKey::RSA.new(1024).public_key }
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @owner.historical_inbox_settlement_complete!(journal: @journal, events: prefix,
              params: @params, map: @map, commit: commit, deployment: @deployment, history: history)
          end
        end
      end

      def test_selected_context_completion_authenticates_consumed_and_superseded_canonical_effects
        %w[consumed superseded].each do |outcome|
          fixture(child: true) do
            if outcome == "superseded"
              receipt = JSON.parse(@bytes)
              receipt["outcome"] = "superseded"
              receipt["evidence"]["kind"] = "queue_evicted"
              @bytes = JSON.generate(receipt)
              @signature = @key.sign(OpenSSL::Digest::SHA256.new, @bytes)
              @params = @params.merge("receipt_sha256" => Digest::SHA256.hexdigest(@bytes),
                "signature_sha256" => Digest::SHA256.hexdigest(@signature))
            end
            reconcile
            commit, prefix = @journal.ref_value, events
            selected = prefix.find { |event| event["type"] == "inbox_reconciliation" }
            original_key, fingerprint = @key.public_key, @registration.fetch("receipt_key_sha256")
            history = Object.new
            history.define_singleton_method(:public_key!) do |sha256:|
              raise AttemptErrors::EvidenceUnavailable unless sha256 == fingerprint
              original_key
            end
            @deployment.define_singleton_method(:verify_inbox_context!) { |*| raise "completion must not query current context" }
            verifier = Authority::HistoricalInboxEvidence.new(journal: @journal, deployment: @deployment, history: history)
            result = verifier.verify_selected!(events: prefix, params: @params, map: @map, commit: commit,
              reconciliation_digest: selected.fetch("digest"))
            assert_equal(outcome == "consumed" ? "completed" : "queued", result.dig("reconciliation", "payload", "state"))
            assert_equal commit, result.fetch("commit")
            assert_equal "authority_mutation", result.dig("reply", "type")
            assert result.frozen?
            assert result.dig("reconciliation", "payload", "binding").frozen?
            assert_raises(FrozenError) { result.dig("reconciliation", "payload", "registration")["event_id"].replace("other") }
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              verifier.verify_selected!(events: prefix, params: @params, map: @map, commit: commit,
                reconciliation_digest: "f" * 64)
            end
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              verifier.verify_selected!(events: prefix.drop(1), params: @params, map: @map, commit: commit,
                reconciliation_digest: selected.fetch("digest"))
            end
            @journal.stub(:blob, "corrupt") do
              assert_raises(AttemptErrors::EvidenceUnavailable) do
                verifier.verify_selected!(events: prefix, params: @params, map: @map, commit: commit,
                  reconciliation_digest: selected.fetch("digest"))
              end
            end
            if outcome == "superseded"
              assert_raises(AttemptErrors::EvidenceUnavailable) { verifier.verify!(events: prefix, params: @params, map: @map, commit: commit) }
            else
              assert verifier.verify!(events: prefix, params: @params, map: @map, commit: commit)
            end
          end
        end
      end

      def test_wrong_registration_role_context_signature_and_body_refuse_without_import
        fixture do
          assert_raises(AttemptErrors::Conflict) { reconcile(params: @params.merge("expected_registration" => @registration.merge("payload_sha256" => "a" * 64))) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { reconcile(role: :worker) }
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile(params: @params.merge("inbox_context_id" => "missing")) }
          assert_raises(ArgumentError) { reconcile(parts: [@bytes, "wrong"]) }
          altered = @params.merge("signature_sha256" => Digest::SHA256.hexdigest("wrong"))
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile(params: altered, parts: [@bytes, "wrong"]) }
          assert_equal 0, events.count { |event| event["type"] == "evidence_import" }
          @unsafe = true
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
        end
      end

      def test_retained_proof_after_seal_requires_current_context_role_and_exact_launcher
        fixture do
          accepted = reconcile
          parent = events.find { |event| event["type"] == "scope_bound" }
          mutate("fixture_seal", "seal", 6, {data: {}, events: [{type: "scope_sealed", payload: {
            "scope_generation" => 2, "scope_binding_event_id" => parent.fetch("digest")}}]})
          @kernel.dead = [90, 91]
          assert_equal accepted.fetch(:data), reconcile.fetch(:data)
          assert_raises(AttemptErrors::UnauthorizedIdentity) { reconcile(peer: @launcher.merge("started_at" => "replaced"), role: :launcher) }
          assert_equal "completed", reconcile(peer: @launcher, role: :launcher).dig(:data, "state")
          @context["supervisor_uids"] = []
          assert_raises(AttemptErrors::UnauthorizedIdentity) { reconcile }
          @context["supervisor_uids"] = [13004]
          @policy.define_singleton_method(:visible!) { |**| raise AttemptErrors::UnauthorizedIdentity, "revoked" }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { reconcile }
        end
      end

      def test_changed_same_id_and_uncontextual_registration_cannot_adopt_old_proof
        fixture do
          reconcile
          assert_raises(AttemptErrors::Conflict) { reconcile(params: @params.merge("expected_generation" => 6)) }
          assert_raises(ArgumentError) { reconcile(params: @params.merge("expected_registration" => nil)) }
          assert_raises(ArgumentError) { reconcile(params: @params.merge("extra" => true)) }
          assert_equal 2, events.count { |event| event["type"] == "evidence_import" }
        end
        fixture do
          mutate("fixture_duplicate_registration", "old-registration", 5, {data: {}, events: [{type: "inbox_binding", payload: @registration}]})
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
          assert_equal 0, events.count { |event| event["type"] == "evidence_import" }
        end
      end

      def test_superseded_claim_history_is_retained_but_not_used_to_settle_a_new_claim
        fixture do
          receipt = JSON.parse(@bytes)
          receipt["outcome"] = "superseded"
          receipt["evidence"]["kind"] = "queue_evicted"
          @bytes = JSON.generate(receipt)
          @signature = @key.sign(OpenSSL::Digest::SHA256.new, @bytes)
          @params = @params.merge("receipt_sha256" => Digest::SHA256.hexdigest(@bytes),
            "signature_sha256" => Digest::SHA256.hexdigest(@signature))
          first = reconcile
          assert_equal "queued", first.dig(:data, "state")
          historical = events.find { |event| event["type"] == "inbox_reconciliation" }
          old_params, old_bytes, old_signature = @params, @bytes, @signature
          record = @box.deliver(event: "event")
          assert_equal 2, record.fetch("claim_generation")
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
          receipt = record.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding").merge(
            "outcome" => "consumed", "observer" => {"role" => "supervisor", "id" => "observer"},
            "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => "native:2", "observation" => "consumed"})
          @bytes = JSON.generate(receipt); @signature = @key.sign(OpenSSL::Digest::SHA256.new, @bytes)
          @params = @params.merge("expected_generation" => 6, "receipt_sha256" => Digest::SHA256.hexdigest(@bytes),
            "signature_sha256" => Digest::SHA256.hexdigest(@signature))
          second = reconcile(id: "claim-two")
          assert_equal "completed", second.dig(:data, "state")
          assert_equal [1, 2], events.select { |event| event["type"] == "inbox_reconciliation" }.map { |event| event.dig("payload", "claim_generation") }
          assert_equal historical, events.find { |event| event["digest"] == historical.fetch("digest") }
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            reconcile(params: old_params, parts: [old_bytes, old_signature])
          end
          assert_equal second.fetch(:data), reconcile(id: "claim-two").fetch(:data)
          original_key = @key.public_key
          fingerprint = @registration.fetch("receipt_key_sha256")
          history = Object.new
          history.define_singleton_method(:public_key!) do |sha256:|
            raise AttemptErrors::EvidenceUnavailable unless sha256 == fingerprint
            original_key
          end
          assert @owner.historical_inbox_settlement_complete!(journal: @journal, events: events,
            params: @params, map: @map, commit: @journal.ref_value, deployment: @deployment, history: history)
          bogus_reply = {"type" => "authority_mutation", "payload" => {"operation" => "reconcile_inbox",
            "data" => {"event_id" => "event", "state" => "completed"}}}
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            Authority::HistoricalInboxEvidence.new(journal: @journal, deployment: @deployment, history: history).verify!(
              events: events + [bogus_reply], params: @params, map: @map, commit: @journal.ref_value)
          end
          reordered = events.dup
          zero = JSON.parse(JSON.generate(historical))
          zero["payload"]["claim_generation"] = 0
          reordered.insert(reordered.index(historical) + 1, zero)
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            Authority::HistoricalInboxEvidence.new(journal: @journal, deployment: @deployment, history: history).verify!(
              events: reordered, params: @params, map: @map, commit: @journal.ref_value)
          end
          # Earlier superseded claim evidence stays part of authenticated
          # history; the final consumed claim cannot conceal its corruption.
          historical_ref = historical.dig("payload", "receipt_ref", "ref")
          checkout = File.join(@journal.checkout_root, "journal")
          File.binwrite(File.join(checkout, historical_ref), "corrupt")
          git_in(checkout, "add", "-A")
          git_in(checkout, "commit", "-m", "fixture corrupt retained claim evidence")
          git_in(@journal.repo_root, "update-ref", @journal.ref, git_in(checkout, "rev-parse", "HEAD").strip)
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @owner.historical_inbox_settlement_complete!(journal: @journal, events: events,
              params: @params, map: @map, commit: @journal.ref_value, deployment: @deployment, history: history)
          end
        end
      end

      def test_signed_foreign_workspace_and_original_child_mismatch_refuse_before_import
        fixture do
          store = Ace::Herdr::Molecules::DeliveryRecordStore
          record = store.load(@context.fetch("deliveries_dir"), "event")
          foreign = record.inbox.merge("binding" => record.inbox.fetch("binding").merge("session" => "foreign-workspace"))
          store.save(record.advance_inbox(state: record.state, inbox: foreign, detail: {"action" => "fixture"}, timestamp: Time.now.utc.iso8601), @context.fetch("deliveries_dir"))
          receipt = JSON.parse(@bytes)
          receipt["binding"]["session"] = "foreign-workspace"
          @bytes = JSON.generate(receipt); @signature = @key.sign(OpenSSL::Digest::SHA256.new, @bytes)
          @params = @params.merge("receipt_sha256" => Digest::SHA256.hexdigest(@bytes), "signature_sha256" => Digest::SHA256.hexdigest(@signature))
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
          assert_equal 0, events.count { |event| event["type"] == "evidence_import" }
          assert_equal "delivered", @box.status(event: "event").fetch("state")
        end
        %w[pane terminal_id].each do |field|
          fixture(child: true) do
            store = Ace::Herdr::Molecules::DeliveryRecordStore
            record = store.load(@context.fetch("deliveries_dir"), "event")
            foreign_value = field == "pane" ? "p2" : "foreign-terminal"
            foreign = record.inbox.merge("origin_target" => record.inbox.fetch("origin_target").merge(field => foreign_value),
              "binding" => record.inbox.fetch("binding").merge(field => foreign_value))
            store.save(record.advance_inbox(state: record.state, inbox: foreign, detail: {"action" => "fixture"}, timestamp: Time.now.utc.iso8601), @context.fetch("deliveries_dir"))
            receipt = JSON.parse(@bytes); receipt["binding"][field] = foreign_value
            @bytes = JSON.generate(receipt); @signature = @key.sign(OpenSSL::Digest::SHA256.new, @bytes)
            @params = @params.merge("receipt_sha256" => Digest::SHA256.hexdigest(@bytes), "signature_sha256" => Digest::SHA256.hexdigest(@signature))
            assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
            assert_equal 0, events.count { |event| event["type"] == "evidence_import" }
            assert_equal "delivered", @box.status(event: "event").fetch("state")
          end
        end
        fixture(child: true) do
          assert_equal "completed", reconcile.dig(:data, "state")
          @kernel.dead = [90, 91]
          assert reconcile.fetch(:replayed)
        end
      end

      def settlement(events: self.events, commit: @journal.ref_value, evidence: false)
        method = evidence ? :inbox_settlement_evidence! : :inbox_settlement_complete!
        unless @params.key?("inbox_context_id")
          return @owner.public_send(method, journal: @journal, events: events, params: @params, map: @map, commit: commit)
        end
        registrations = events.select { |event| event["type"] == "inbox_binding" }
        enter = lambda do |index|
          if index == registrations.size
            return @owner.public_send(method, journal: @journal, events: events,
              params: @params.slice("mapping_id", "assignment_id", "attempt_id"), map: @map, commit: commit)
          end
          payload = registrations.fetch(index).fetch("payload")
          selected = @params.merge("event_id" => payload.fetch("event_id"), "inbox_context_id" => payload.fetch("inbox_context_id"))
          @owner.send(:with_inbox_context, selected, @map, mutation_id: "settlement-query") { enter.call(index + 1) }
        end
        enter.call(0)
      end

      def test_signed_queued_inbox_never_masks_corrupt_later_or_earlier_import
        fixture do
          receipt = JSON.parse(@bytes)
          receipt["outcome"] = "superseded"
          receipt["evidence"]["kind"] = "queue_evicted"
          @bytes = JSON.generate(receipt)
          @signature = @key.sign(OpenSSL::Digest::SHA256.new, @bytes)
          @params = @params.merge("receipt_sha256" => Digest::SHA256.hexdigest(@bytes),
            "signature_sha256" => Digest::SHA256.hexdigest(@signature))
          reconcile
          record = @box.enqueue(event: "event-2", attempt: "attempt", ref: {"session" => "w1", "pane" => "p1"}, payload: "second")
          record = @box.deliver(event: "event-2")
          registration = record.slice("event_id", "attempt_id", "payload_sha256", "receipt_key_sha256")
          mutate("fixture_registration", "registration-2", 6, {data: {}, events: [{type: "inbox_binding", payload: {
            "event_id" => "event-2", "attempt_id" => "attempt", "inbox_context_id" => "context", "registration" => registration}}]})
          receipt = record.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding").merge(
            "outcome" => "consumed", "observer" => {"role" => "supervisor", "id" => "observer"},
            "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => "native:2", "observation" => "consumed"})
          bytes = JSON.generate(receipt)
          signature = @key.sign(OpenSSL::Digest::SHA256.new, bytes)
          params = @params.merge("event_id" => "event-2", "expected_registration" => registration, "expected_generation" => 7,
            "receipt_sha256" => Digest::SHA256.hexdigest(bytes), "signature_sha256" => Digest::SHA256.hexdigest(signature))
          reconcile(params: params, id: "reconcile-2", parts: [bytes, signature])
          assert_raises(AttemptErrors::InboxSettlementPending) { settlement(evidence: true) }
          second = events.find { |event| event["type"] == "inbox_reconciliation" && event.dig("payload", "event_id") == "event-2" }
          first = events.find { |event| event["type"] == "inbox_reconciliation" && event.dig("payload", "event_id") == "event" }
          original = @journal.method(:blob)
          [first, second].each do |corrupted|
            corrupted_path = corrupted.dig("payload", "signature_ref", "ref")
            reader = ->(path, commit:) { path == corrupted_path ? "corrupt" : original.call(path, commit: commit) }
            @journal.stub(:blob, reader) do
              error = assert_raises(AttemptErrors::EvidenceUnavailable) { settlement(evidence: true) }
              refute_kind_of AttemptErrors::InboxSettlementPending, error
            end
          end
        end
      end

      def test_source_owned_settlement_shares_provenance_without_fabricated_public_peer
        fixture do
          assert_raises(AttemptErrors::EvidenceUnavailable) { settlement }
          reconcile
          @kernel.dead = [81, 82, 90, 91]
          @policy.define_singleton_method(:visible!) { |**| raise "internal source predicate must not invent a public peer" }
          assert settlement
          evidence = settlement(evidence: true)
          reconciliation = events.find { |event| event["type"] == "inbox_reconciliation" }
          reply = events.find { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "reconcile_inbox" }
          assert_equal @journal.ref_value, evidence.fetch("commit")
          assert_equal [{"inbox_context_id" => "context", "event_id" => "event",
            "claim_generation" => reconciliation.dig("payload", "claim_generation"),
            "reconciliation_event_digest" => reconciliation.fetch("digest"), "reply_event_digest" => reply.fetch("digest"),
            "receipt_ref" => reconciliation.dig("payload", "receipt_ref"),
            "signature_ref" => reconciliation.dig("payload", "signature_ref")}], evidence.fetch("inboxes")
          assert_raises(FrozenError) { evidence.fetch("inboxes").first.fetch("receipt_ref")["ref"].replace("changed") }
          store = Ace::Herdr::Molecules::DeliveryRecordStore
          store.with_lock(@context.fetch("deliveries_dir"), "event") { store.archive(@context.fetch("deliveries_dir"), "event") }
          assert settlement
          assert_raises(AttemptErrors::EvidenceUnavailable) { settlement(events: events.drop(1)) }
          @journal.stub(:blob, "corrupt") { assert_raises(AttemptErrors::EvidenceUnavailable) { settlement } }
          lock = Ace::Herdr::Molecules::DeliveryRecordStore.lock_path(@context.fetch("deliveries_dir"), "event")
          File.unlink(lock)
          assert_raises(AttemptErrors::EvidenceUnavailable) { settlement }
          refute File.exist?(lock)
        end
        fixture do
          receipt = JSON.parse(@bytes); receipt["outcome"] = "superseded"; receipt["evidence"]["kind"] = "queue_evicted"
          @bytes = JSON.generate(receipt); @signature = @key.sign(OpenSSL::Digest::SHA256.new, @bytes)
          @params = @params.merge("receipt_sha256" => Digest::SHA256.hexdigest(@bytes), "signature_sha256" => Digest::SHA256.hexdigest(@signature))
          reconcile
          assert_raises(AttemptErrors::EvidenceUnavailable) { settlement }
        end
      end

      def test_source_owned_empty_inbox_set_is_verified_without_native_or_public_peer
        fixture(inbox: false) do
          @kernel.dead = [81, 82, 90, 91]
          @policy.define_singleton_method(:visible!) { |**| raise "no invented public peer" }
          assert settlement
          assert_equal [], settlement(evidence: true).fetch("inboxes")
          @unsafe = true
          assert_raises(AttemptErrors::EvidenceUnavailable) { settlement }
        end
      end

      def test_unregistered_retained_event_cannot_disappear_from_settlement_inventory
        fixture do
          reconcile
          store = Ace::Herdr::Molecules::DeliveryRecordStore
          record = store.load(@context.fetch("deliveries_dir"), "event")
          copy = Ace::Herdr::Models::DeliveryRecord.from_h(record.to_h.merge("event_id" => "unregistered"))
          store.with_lock(@context.fetch("deliveries_dir"), "unregistered") { store.save(copy, @context.fetch("deliveries_dir")) }
          assert_raises(AttemptErrors::EvidenceUnavailable) { settlement }
        end
      end

      def test_settlement_checks_every_live_and_archive_copy
        fixture do
          reconcile
          store = Ace::Herdr::Molecules::DeliveryRecordStore
          dir = @context.fetch("deliveries_dir")
          archived = store.path_for(store.archive_dir(dir), "event")
          FileUtils.mkdir_p(File.dirname(archived))
          original = File.read(store.path_for(dir, "event"))
          File.write(archived, "corrupt")
          assert_raises(AttemptErrors::EvidenceUnavailable) { settlement }
          %w[attempt_id claim_generation].each do |field|
            copy = JSON.parse(original)
            copy.fetch("inbox")[field] = field == "attempt_id" ? "other-attempt" : copy.fetch("inbox").fetch(field) + 1
            File.write(archived, JSON.generate(copy))
            assert_raises(AttemptErrors::EvidenceUnavailable) { settlement }
          end
          File.write(archived, JSON.pretty_generate(JSON.parse(original)))
          assert settlement
          lock = store.lock_path(dir, "event")
          File.unlink(lock)
          assert_raises(AttemptErrors::EvidenceUnavailable) { settlement }
          refute File.exist?(lock)
        end
      end

      def test_lost_canonical_completion_ack_reconfirms_without_reissuing_effect
        fixture do
          original_read = @context_query_wire.method(:read)
          lost = false
          @context_query_wire.define_singleton_method(:read) do |*args, **options|
            result = original_read.call(*args, **options)
            unless lost
              lost = true
              raise Ace::Herdr::ValidationError, "fixture lost canonical completion ACK"
            end
            result
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
          assert_equal 1, events.count { |event| event["type"] == "inbox_reconciliation" }
          retained = @journal.mutation_result("reconcile").fetch("data")
          pending = @context_owner.status(peer: @authority_peer)
          assert_equal 1, pending.fetch("active_operations")
          original_effect = @box.method(:reconcile)
          @box.define_singleton_method(:reconcile) { |**| raise "accepted Inbox effect must not be reissued" }
          replay = reconcile
          assert replay.fetch(:replayed)
          assert_equal retained, replay.fetch(:data).reject { |key, _| key == "journal_commit" }
          assert_equal @journal.mutation_result("reconcile").fetch("data"), retained
          assert_equal @journal.mutation_result("reconcile").fetch("journal_commit"), replay.fetch(:data).fetch("journal_commit")
          assert_equal 1, events.count { |event| event["type"] == "inbox_reconciliation" }
          assert_equal 0, @context_owner.status(peer: @authority_peer).fetch("active_operations")
          @box.define_singleton_method(:reconcile) { |**args| original_effect.call(**args) }
        end
      end

      def test_herdr_accepted_before_qjl_failure_replays_exact_signed_proof
        fixture do
          original = @journal.method(:mutate)
          @journal.define_singleton_method(:mutate) do |**args, &block|
            if args[:operation] == "reconcile_inbox"
              block.call(read_events("assignment").select { |event| event["attempt_id"] == "attempt" }, ref_value, 4)
              raise AttemptErrors::EvidenceUnavailable, "fixture crash before CAS"
            end
            original.call(**args, &block)
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
          assert_equal "completed", @box.status(event: "event").fetch("state")
          assert_equal 0, events.count { |event| event["type"] == "evidence_import" }
          @journal.define_singleton_method(:mutate) { |**args, &block| original.call(**args, &block) }
          assert_equal "completed", reconcile.dig(:data, "state")
          assert_equal 1, events.count { |event| event["type"] == "inbox_reconciliation" }
        end
      end
    end
  end
end
