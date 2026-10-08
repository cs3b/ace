# frozen_string_literal: true
require_relative "../../test_helper"
require_relative "../../support/endcap_result_owner_fixture"
require_relative "../../support/service_no_effect_owner_fixture"
require "ace/assign/authority/service_evidence"
require "ace/assign/authority/server"
require "ace/assign/authority/client"
require "ace/lab/molecules/protected_cleanup_owner_admission"
require "ace/lab/organisms/protected_cleanup_owner"
require "ace/lab/organisms/protected_service_client"
require_relative "../../../../ace-overseer/lib/ace/overseer"

module Ace
  module Assign
    # Actual authority ingress/CAS/import; installed receiver inspection is a
    # controlled prerequisite, not evidence of delivered domain inspection.
    class ServiceSettlementTest < AceAssignTestCase
      include EndcapResultOwnerFixture
      include ServiceNoEffectOwnerFixture
      Parts = Struct.new(:parts) do
        def count; parts.length; end
        def bytes(index: 0); parts.fetch(index); end
      end

      def configure_result_owner_fixture
        @project["worker_uids"] = [13001]
        @project["service_receivers"] = {"executor" => {"executor_uid" => 13005,
          "socket_path" => "/fixture/service.sock", "staging_root" => "/fixture/staging"}}
        owner = nil
        @journal = Molecules::EvidenceJournal.new(repo_root: @journal.repo_root, ref: @journal.ref,
          checkout_root: @journal.checkout_root, mode: :protected,
          evidence_reader: ->(*args) { owner.call(*args) },
          service_authorizer: ->(existing, replacement, pending) {
            @endcap.authorize_service_update!(journal: @journal, existing: existing,
              replacement: replacement, pending: pending) })
        owner = Authority::ServiceEvidence.new(journal: @journal)
      end

      def request_service
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
        @request_params, @request_body = params, body
      end

      def seal_and_challenge
        @launch.close_execution_scope!(params: {"mapping_id" => "mapping", "assignment_id" => "assignment",
          "attempt_id" => @attempt, "mutation_id" => "seal", "expected_generation" => generation},
          peer: @launcher, role: :launcher)
        params = {"head" => @head, "candidate_generation" => 1,
          "request_id" => "service-request", "expected_generation" => generation}
        result = call("claim_service_settlement", params, id: "challenge", peer: @executor, role: :executor)
        [params, result]
      end

      def test_actual_preview_context_is_read_only_and_authenticates_both_principals
        fixture do
          @policy.define_singleton_method(:workspace_prune_receiver!) do |project:, uid:, service_id:, executor_uid:|
            raise SecurityError, "selected preview policy differs" unless
              [project, uid, service_id, executor_uid] == ["project", 13001, "executor", 13005]
            true
          end
          client = start_service_server
          params = {"assignment_id" => "assignment", "attempt_id" => @attempt,
            "service_id" => "executor", "worker_process_binding" => @worker}
          before = @journal.ref_value
          result = client.call("workspace_prune_preview_context", params)
          assert_equal before, result.data.fetch("journal_commit")
          assert_equal @head, result.data.fetch("head")
          assert_equal 1, result.data.fetch("candidate_generation")
          assert_equal @worker, result.data.fetch("worker_process_binding")
          assert_equal @worker, result.data.fetch("caller_process_binding")
          assert_equal before, @journal.ref_value
          assert_equal [], @journal.service_requests("assignment")
          root_admission = Ace::Lab::Molecules::ProtectedCleanupOwnerAdmission.new(deployment: @deployment,
            authority_id: "authority", mapping_id: "mapping", service_id: "executor", kernel: @kernel, preview_policy: @policy)
          target = {"project_id" => "project", "mapping_id" => "old", "assignment_id" => "old-assignment", "attempt_id" => "old-attempt",
            "resource" => "workspace:project:old:old-assignment", "descriptor_sha256" => "a" * 64,
            "binding_event_digest" => "b" * 64, "release_event_digest" => "c" * 64, "journal_commit" => "d" * 40}
          intent = {"schema" => "ace.protected-workspace-prune-preview/v1", "maintenance" => result.data.fetch("maintenance"),
            "target" => target, "publication" => {"descriptor_sha256" => "e" * 64,
              "installation_ref" => {"path" => "/fixture/installation.json", "bytes" => 10, "sha256" => "f" * 64}}, "destinations" => []}
          frame = {"schema" => Ace::Lab::Molecules::ProtectedCleanupOwnerClient::SCHEMA, "kind" => "preview",
            "intent" => intent, "maintenance_context" => result.data}
          original_root = {"controlled_original_root" => "fixed"}
          selected = root_admission.preview!(frame: frame, peer: @executor, operation_owner_binding: original_root, journal: @journal)
          assert_equal result.data, selected.fetch("maintenance_context")
          assert selected.frozen?
          # Actual socket transports and canonical owners, with no physical
          # Installer producer claimed by this controlled metadata collaborator.
          @project.fetch("service_receivers").fetch("executor")["staging_root"] = @root
          kernel = @kernel
          executor = @executor
          original_capture = kernel.method(:capture)
          kernel.define_singleton_method(:capture) { |pid| pid == Process.pid ? executor : original_capture.call(pid) }
          transports = []
          root_owners = []
          preview_errors = []
          root_factory = lambda do |physical|
            root_local, root_remote = UNIXSocket.pair
            root_wire = Object.new
            %i[deadline read write].each { |name| root_wire.define_singleton_method(name) { |*args, **opts| WIRE.public_send(name, *args, **opts) } }
            root_wire.define_singleton_method(:root_path!) { |*_, **_| true }
            root_wire.define_singleton_method(:socket_identity) { |*_, **_| [1, 2, 0] }
            root_wire.define_singleton_method(:connect) { |*_, **_, &block| block.call(root_local) }
            observer = Object.new
            observer.define_singleton_method(:observe!) { |**_| original_root }
            observer.define_singleton_method(:observe_self!) { |**_| original_root }
            view = Object.new
            view.define_singleton_method(:with) { |**_, &block| block.call(:held_snapshot) }
            original_journal = @journal
            root_owner = Ace::Lab::Organisms::ProtectedCleanupOwner.new(observer: observer, admission: root_admission,
              snapshots: ->(&block) { block.call(view) }, journals: ->(_) { original_journal }, kernel: kernel,
              installer: physical, scratch_root: @root)
            root_owners << root_owner
            root_errors = Queue.new
            root_thread = Thread.new do
              root_owner.handle(root_remote)
            rescue SecurityError => error
              root_errors << error.class
              preview_errors << [error.class.name, error.message, error.backtrace.first]
            end
            transports << [root_local, root_remote, root_thread]
            Ace::Lab::Molecules::ProtectedCleanupOwnerClient.new(observer: observer, scratch_root: @root, wire: root_wire)
          end
          public_exchange = lambda do |physical, cli = false|
            cleanup_client = root_factory.call(physical)
            receiver = Ace::Lab::Organisms::ProtectedServiceReceiver.new(mapping_id: "mapping", service_id: "executor",
              deployment: @deployment, kernel: kernel, client: client, cleanup_owner: cleanup_client)
            receiver_preview = receiver.method(:preview_workspace_prune)
            receiver.define_singleton_method(:preview_workspace_prune) do |**args|
              receiver_preview.call(**args)
            rescue Exception => error
              preview_errors << [error.class.name, error.message, error.backtrace.first]
              raise
            end
            receiver_kernel = Kernel.new
            receiver_kernel.peer_identity = @worker
            receiver_listener = Ace::Lab::Organisms::ProtectedServiceListener.new(mapping_id: "mapping", service_id: "executor",
              deployment: @deployment, kernel: receiver_kernel, receiver: receiver)
            worker_kernel = Kernel.new
            original_worker = @worker
            worker_kernel.define_singleton_method(:capture) { |_| original_worker }
            worker_kernel.peer_identity = @executor
            public_local, public_remote = UNIXSocket.pair
            public_wire = Object.new
            %i[deadline read write].each { |name| public_wire.define_singleton_method(name) { |*args, **opts| WIRE.public_send(name, *args, **opts) } }
            public_wire.define_singleton_method(:socket_identity) { |_| [3, 4, executor.fetch("uid")] }
            public_wire.define_singleton_method(:connect) { |*_, **_, &block| block.call(public_local) }
            public_thread = Thread.new do
              receiver_listener.send(:receive, public_remote)
            ensure
              public_remote.close unless public_remote.closed?
            end
            transports << [public_local, public_remote, public_thread]
            worker_client = Ace::Lab::Organisms::ProtectedServiceClient.new(mapping_id: "mapping", service_id: "executor",
              deployment: @deployment, kernel: worker_kernel, wire: public_wire)
            if cli
              selection = Object.new
              deployment = @deployment
              selection.define_singleton_method(:call) { |**_| [deployment] }
              owner = Ace::Overseer::Organisms::ProtectedPrune.new(selection: selection,
                document_loader: -> { {"operations" => {"prune-preserved-workspace" => {"project" => "project", "service_id" => "executor"}}} },
                client_factory: ->(mapping, service, actual) {
                  raise "CLI selected another receiver" unless [mapping, service, actual] == ["mapping", "executor", @deployment]
                  worker_client
                })
              file = File.join(@root, "preview-intent.json")
              File.write(file, JSON.generate(intent))
              output = StringIO.new
              Ace::Overseer::CLI::Commands::Prune.new(protected_prune: owner, output: output).call(
                project: "project", agent: "old", assignment: "old-assignment", attempt: "old-attempt", request: file, dry_run: true)
              JSON.parse(output.string)
            else
              worker_client.preview_workspace_prune(intent: intent)
            end
          end
          assert_raises(SecurityError) { public_exchange.call(Object.new) }
          physical_calls = 0
          physical = Object.new
          physical.define_singleton_method(:execute_cleanup!) { |**_| raise "preview must not execute cleanup" }
          physical.define_singleton_method(:inspect_cleanup!) { |**_| raise "preview must not inspect an effect" }
          physical.define_singleton_method(:preview_cleanup!) do |context:, receiver_peer:, deadline:|
            raise "deadline reset" unless deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC) <= 5
            raise "receiver peer changed" unless receiver_peer == executor
            raise "receiver peer aliases kernel object" if receiver_peer.equal?(executor)
            verify_frozen = lambda do |value|
              raise "mutable receiver peer" unless value.frozen?
              value.each { |key, item| verify_frozen.call(key); verify_frozen.call(item) } if value.is_a?(Hash)
              value.each { |item| verify_frozen.call(item) } if value.is_a?(Array)
            end
            verify_frozen.call(receiver_peer)
            physical_calls += 1
            preservation = {"head" => "a" * 40, "branch" => nil, "destinations" => [], "manifest_sha256" => "b" * 64}
            target_result = target.merge("artifact_digest" => Ace::Assign::Atoms::EvidenceDigest.digest("target" => target, "preservation" => preservation))
            {"schema" => "ace.protected-workspace-prune-preview-result/v1", "kind" => "preview",
              "intent_digest" => Ace::Assign::Atoms::EvidenceDigest.digest(intent), "publication" => intent.fetch("publication"),
              "maintenance" => intent.fetch("maintenance"), "maintenance_context" => context.fetch("maintenance_context"),
              "target" => target_result, "preservation" => preservation, "inventory_sha256" => preservation.fetch("manifest_sha256"),
              "file_count" => 0, "total_bytes" => 0}
          end
          public_result = begin
            public_exchange.call(physical, true)
          rescue SecurityError => error
            raise SecurityError, "controlled preview stages: #{preview_errors.inspect}", cause: error
          end
          assert_equal result.data, public_result.fetch("maintenance_context")
          assert_equal 1, physical_calls
          assert root_owners.all? { |owner| owner.instance_variable_get(:@consumed).empty? }, "preview must not consume invocation state"
          assert_equal before, @journal.ref_value
          transports.each do |left, right, thread|
            left.close unless left.closed?
            right.close unless right.closed?
            assert thread.join(3), "controlled transport did not finish"
            thread.value
          end
          assert_raises(SecurityError) do
            root_admission.preview!(frame: frame.merge("receiver_peer" => @executor), peer: @executor,
              operation_owner_binding: original_root, journal: @journal)
          end
          mismatched = JSON.parse(JSON.generate(frame))
          mismatched["intent"]["maintenance"]["attempt_id"] = "foreign-attempt"
          assert_raises(SecurityError) do
            root_admission.preview!(frame: mismatched, peer: @executor, operation_owner_binding: original_root, journal: @journal)
          end
          stale = JSON.parse(JSON.generate(frame))
          stale["maintenance_context"]["head"] = "f" * 40
          assert_raises(SecurityError) do
            root_admission.preview!(frame: stale, peer: @executor, operation_owner_binding: original_root, journal: @journal)
          end
          assert_equal 1, physical_calls
          missing = JSON.parse(JSON.generate(frame))
          missing["intent"]["maintenance"]["assignment_id"] = "missing-assignment"
          missing["maintenance_context"]["maintenance"]["assignment_id"] = "missing-assignment"
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            root_admission.preview!(frame: missing, peer: @executor, operation_owner_binding: original_root, journal: @journal)
          end
          original_project = @map.fetch("project_id")
          @map["project_id"] = "foreign-project"
          wrong = JSON.parse(JSON.generate(frame))
          wrong["intent"]["maintenance"]["project_id"] = "foreign-project"
          wrong["maintenance_context"]["maintenance"]["project_id"] = "foreign-project"
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            root_admission.preview!(frame: wrong, peer: @executor, operation_owner_binding: original_root, journal: @journal)
          end
          @map["project_id"] = original_project
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            call("workspace_prune_preview_context", params.merge("worker_process_binding" => @reviewer),
              peer: @executor, role: :executor)
          end
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            call("workspace_prune_preview_context", params, peer: @worker, role: :worker)
          end
          assert_raises(ArgumentError) do
            call("workspace_prune_preview_context", params, id: "no-preview-mutation", peer: @executor, role: :executor)
          end
          socket = UNIXSocket.new(@service.fetch("socket_path"))
          WIRE.write(socket, {"version" => 1, "operation" => "workspace_prune_preview_context", "project_id" => "project",
            "mutation_id" => nil, "params" => params.merge("mapping_id" => "mapping")}, deadline: WIRE.deadline(2))
          socket.write("unexpected body")
          socket.shutdown(Socket::SHUT_WR)
          assert_equal "invalid_input", WIRE.read(socket, deadline: WIRE.deadline(3)).dig("error", "code")
          assert_equal before, @journal.ref_value
          previous = git(@journal.repo_root, "rev-parse", "#{before}^")
          journal = @journal
          git_runner = method(:git)
          @policy.define_singleton_method(:workspace_prune_receiver!) do |**|
            git_runner.call(journal.repo_root, "update-ref", journal.ref, previous, before)
            true
          end
          assert_raises(AttemptErrors::Conflict) do
            call("workspace_prune_preview_context", params, peer: @executor, role: :executor)
          end
          assert_equal previous, @journal.ref_value
          git(@journal.repo_root, "update-ref", @journal.ref, before, previous)
        ensure
          socket&.close unless socket&.closed?
          transports&.each do |left, right, thread|
            left.close unless left.closed?
            right.close unless right.closed?
            thread.join(3)
          end
        end
      end

      def test_retained_orphan_challenge_cannot_authorize_import_or_fresh_challenge
        fixture do
          request_service
          seal_and_challenge
          original = @journal.service_request("service-request")
          owner = Authority::ServiceEvidence.new(journal: @journal)
          payload = owner.challenge!(original).fetch("payload").merge(
            "no_effect_challenge" => "f" * 32, "challenge_generation" => generation + 1)
          orphan = nil
          @journal.mutate(assignment_id: "assignment", attempt_id: @attempt, mutation_id: "orphan",
            operation: "fixture_orphan", parameters_digest: "b" * 64, expected_generation: generation) do |events|
            at = Time.now.utc
            event = Models::EvidenceEvent.build(type: "service_no_effect_challenge", attempt_id: @attempt,
              payload: payload, previous_digest: events.last.fetch("digest"), recorded_at: at)
            orphan = original.merge(payload.slice("no_effect_challenge", "challenge_generation"),
              "challenge_event_digest" => event.fetch("digest"))
            {data: {}, events: [{type: "service_no_effect_challenge", payload: payload, recorded_at: at},
              {type: "service_challenge", payload: {"request_id" => "service-request", "state" => orphan.fetch("state"),
                "input_digest" => orphan.fetch("input_digest"), "record_digest" => Atoms::EvidenceDigest.digest(orphan),
                "receipt_digest" => nil}}]}
          end
          old = @journal.ref_value
          checkout = @journal.send(:checkout_dir)
          @journal.send(:write_service_records, [{path: @journal.send(:service_request_path, "service-request"), record: orphan}])
          git(checkout, "add", "--", @journal.send(:service_request_path, "service-request"))
          git(checkout, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "injected orphan record")
          changed = git(checkout, "rev-parse", "HEAD")
          git(@journal.repo_root, "update-ref", @journal.ref, changed, old)
          assert Models::EvidenceEvent.chain_valid?(@journal.read_events("assignment").select { |event| event["attempt_id"] == @attempt })
          assert_equal orphan, @journal.service_request("service-request")
          error = assert_raises(AttemptErrors::EvidenceUnavailable) { owner.challenge!(orphan) }
          assert_match(/accepted authority mutation/, error.message)
          error = assert_raises(AttemptErrors::EvidenceUnavailable) do
            @endcap.service_settlement_evidence!(journal: @journal,
              events: @journal.read_events("assignment").select { |entry| entry["attempt_id"] == @attempt },
              params: {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt},
              map: @map, commit: @journal.ref_value)
          end
          refute_kind_of AttemptErrors::ServiceSettlementPending, error
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            call("service_status", {"head" => @head, "candidate_generation" => 1, "request_id" => "service-request"},
              peer: @executor, role: :executor)
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            call("claim_service_settlement", {"head" => @head, "candidate_generation" => 1,
              "request_id" => "service-request", "expected_generation" => generation},
              id: "replace-orphan", peer: @executor, role: :executor)
          end
          assert_equal changed, @journal.ref_value
          partial = orphan.merge("challenge_event_digest" => nil)
          @journal.mutate(assignment_id: "assignment", attempt_id: @attempt, mutation_id: "partial-selector",
            operation: "fixture_partial_selector", parameters_digest: "e" * 64, expected_generation: generation) do
            {data: {}, events: [{type: "service_transition", payload: {"request_id" => "service-request",
              "state" => partial.fetch("state"), "input_digest" => partial.fetch("input_digest"),
              "record_digest" => Atoms::EvidenceDigest.digest(partial), "receipt_digest" => nil}}]}
          end
          old = @journal.ref_value
          @journal.send(:write_service_records, [{path: @journal.send(:service_request_path, "service-request"), record: partial}])
          git(checkout, "add", "--", @journal.send(:service_request_path, "service-request"))
          git(checkout, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "injected partial selector")
          partial_commit = git(checkout, "rev-parse", "HEAD")
          git(@journal.repo_root, "update-ref", @journal.ref, partial_commit, old)
          assert_equal partial, @journal.service_request("service-request")
          error = assert_raises(AttemptErrors::EvidenceUnavailable) do
            @endcap.service_settlement_evidence!(journal: @journal,
              events: @journal.read_events("assignment").select { |entry| entry["attempt_id"] == @attempt },
              params: {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt},
              map: @map, commit: partial_commit)
          end
          refute_kind_of AttemptErrors::ServiceSettlementPending, error
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            call("service_status", {"head" => @head, "candidate_generation" => 1, "request_id" => "service-request"},
              peer: @executor, role: :executor)
          end
          assert_equal partial_commit, @journal.ref_value
        end
      end

      def test_original_prechallenge_import_is_not_no_effect_completion_evidence
        fixture do
          request_service
          record = @journal.service_request("service-request")
          owner = Authority::ServiceEvidence.new(journal: @journal)
          evidence = "ace-service-attestation request:service-request input:#{record.fetch("input_digest")} outcome:failed no-effect:true\nold inspection"
          plan = Molecules::CanonicalEvidence.new(journal: @journal).import_plan(**owner.context(record), artifacts: [evidence],
            admitted_after_event_digest: @journal.read_events("assignment").last.fetch("digest"))
          @journal.mutate(assignment_id: "assignment", attempt_id: @attempt, mutation_id: "prior-import",
            operation: "fixture_prior_executor_import", parameters_digest: "c" * 64, expected_generation: generation) { plan.merge(data: {}) }
          reference = plan.fetch(:references).first
          seal_and_challenge
          current = @journal.service_request("service-request")
          assert_equal evidence, Molecules::CanonicalEvidence.new(journal: @journal).read(reference,
            **owner.context(record), commit: @journal.ref_value)
          assert_raises(AttemptErrors::EvidenceUnavailable) { owner.call(reference, current, "failed-settled", {commit: @journal.ref_value}) }
          params, parts = no_effect_upload(current, owner.challenge!(current))
          old_receipt = current.slice(*Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS).merge("outcome" => "failed",
            "evidence" => [{"ref" => "old", "sha256" => Digest::SHA256.hexdigest(evidence)}])
          bytes = JSON.generate(old_receipt)
          params.merge!("receipt_sha256" => Digest::SHA256.hexdigest(bytes),
            "transfer" => Authority::TransferCodec.new(root: @root).descriptor([bytes, evidence], purpose: :receipt_artifacts))
          before = @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            call("complete_no_effect", params, id: "old-settlement", peer: @executor, role: :executor, transfer: Parts.new([bytes, evidence]))
          end
          assert_equal before, @journal.ref_value
          # Correct current binding and valid inspection, but an older barrier:
          # removing the exact selected-challenge guard must make this fail.
          valid = no_effect_upload(current, owner.challenge!(current)).last.parts.last
          wrong_order = Molecules::CanonicalEvidence.new(journal: @journal).import_plan(**owner.context(current, no_effect: true),
            artifacts: [valid], admitted_after_event_digest: plan.fetch(:events).first.fetch(:payload).fetch("admitted_after_event_digest"))
          @journal.mutate(assignment_id: "assignment", attempt_id: @attempt, mutation_id: "wrong-barrier",
            operation: "fixture_wrong_barrier", parameters_digest: "d" * 64, expected_generation: generation) { wrong_order.merge(data: {}) }
          error = assert_raises(AttemptErrors::EvidenceUnavailable) do
            owner.call(wrong_order.fetch(:references).first, current, "failed-settled", {commit: @journal.ref_value})
          end
          assert_match(/Canonical evidence import/, error.message)
        end
      end

      def test_later_failed_outcome_renews_challenge_and_refuses_wrong_binding_replays
        fixture do
          request_service
          challenge_params, first = seal_and_challenge
          before = @journal.ref_value
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            call("claim_service_settlement", challenge_params, id: "wrong-peer", peer: @reviewer, role: :executor)
          end
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            @router.dispatch(request: {"version" => 1, "operation" => "claim_service_settlement", "project_id" => "project",
              "mutation_id" => "wrong-map", "params" => challenge_params.merge("mapping_id" => "another-map",
                "assignment_id" => "assignment", "attempt_id" => @attempt, "expected_generation" => generation)},
              peer: @executor, role: :executor)
          end
          assert_raises(AttemptErrors::Conflict) do
            call("request_service", @request_params.merge("input_digest" => "e" * 64), id: "service-claim",
              peer: @executor, role: :executor, transfer: Parts.new([@request_body]))
          end
          assert_equal before, @journal.ref_value
          record = @journal.service_request("service-request")
          evidence = "ace-service-attestation request:service-request input:#{record.fetch("input_digest")} outcome:failed\nactual failed executor result"
          receipt = record.slice(*Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS).merge("outcome" => "failed",
            "evidence" => [{"ref" => "failed", "sha256" => Digest::SHA256.hexdigest(evidence)}])
          bytes = JSON.generate(receipt)
          params = {"head" => @head, "candidate_generation" => 1, "request_id" => "service-request",
            "claim_binding" => record.fetch("claim_binding"), "receipt_sha256" => Digest::SHA256.hexdigest(bytes),
            "transfer" => Authority::TransferCodec.new(root: @root).descriptor([bytes, evidence], purpose: :receipt_artifacts)}
          call("complete_service", params, id: "actual-failure", peer: @executor, role: :executor, transfer: Parts.new([bytes, evidence]))
          failed = @journal.service_request("service-request")
          assert_equal "failed", failed.fetch("state")
          assert_raises(AttemptErrors::EvidenceUnavailable) { Authority::ServiceEvidence.new(journal: @journal).challenge!(failed) }
          assert_equal first.fetch(:data), call("claim_service_settlement", challenge_params,
            id: "challenge", peer: @executor, role: :executor).fetch(:data)
          second = call("claim_service_settlement", challenge_params.merge("expected_generation" => generation),
            id: "renewed", peer: @executor, role: :executor)
          refute_equal first.dig(:data, "reconciliation_challenge"), second.dig(:data, "reconciliation_challenge")
          current = @journal.service_request("service-request")
          params, parts = no_effect_upload(current, Authority::ServiceEvidence.new(journal: @journal).challenge!(current))
          assert_raises(AttemptErrors::Conflict) do
            call("complete_no_effect", params.merge("reconciliation_challenge" => first.dig(:data, "reconciliation_challenge")),
              id: "stale-settlement", peer: @executor, role: :executor, transfer: parts)
          end
          completed = call("complete_no_effect", params, id: "renewed-settlement", peer: @executor, role: :executor, transfer: parts)
          assert_equal "failed-settled", completed.dig(:data, "state")
          assert_equal failed.fetch("completion_digest"), @journal.service_request("service-request").fetch("completion_digest")
          assert_raises(AttemptErrors::Conflict) do
            call("complete_no_effect", params.merge("claim_binding" => "0" * 64), id: "renewed-settlement",
              peer: @executor, role: :executor, transfer: parts)
          end
        end
      end

      def test_matching_retained_record_and_accepted_generations_refuse_json_floats
        %w[record accepted].each do |kind|
          fixture do
            request_service
            seal_and_challenge
            record = @journal.service_request("service-request")
            owner = Authority::ServiceEvidence.new(journal: @journal)
            assert owner.challenge!(record)
            checkout = @journal.send(:checkout_dir)
            if kind == "record"
              replacement = record.merge("challenge_generation" => record.fetch("challenge_generation").to_f)
              @journal.mutate(assignment_id: "assignment", attempt_id: @attempt, mutation_id: "float-record",
                operation: "fixture_float_record", parameters_digest: "f" * 64, expected_generation: generation) do
                {data: {}, events: [{type: "service_transition", payload: {"request_id" => "service-request",
                  "state" => replacement.fetch("state"), "input_digest" => replacement.fetch("input_digest"),
                  "record_digest" => Atoms::EvidenceDigest.digest(replacement), "receipt_digest" => nil}}]}
              end
              @journal.send(:write_service_records, [{path: @journal.send(:service_request_path, "service-request"), record: replacement}])
              git(checkout, "add", "--", @journal.send(:service_request_path, "service-request"))
            else
              replacement = record
              accepted = @journal.read_events("assignment").select { |event| event["attempt_id"] == @attempt }.last
              assert_equal "claim_service_settlement", accepted.dig("payload", "operation")
              payload = JSON.parse(JSON.generate(accepted.fetch("payload")))
              payload.fetch("data")["generation"] = payload.fetch("data").fetch("generation").to_f
              changed = Models::EvidenceEvent.build(type: "authority_mutation", attempt_id: @attempt, payload: payload,
                previous_digest: accepted.fetch("previous_digest"), recorded_at: Time.iso8601(accepted.fetch("recorded_at")))
              File.delete(File.join(checkout, "execution", "assignment", "events", @journal.send(:event_filename, accepted)))
              @journal.send(:write_event_files, "assignment", [changed])
              git(checkout, "add", "--", "execution/assignment")
            end
            old = @journal.ref_value
            git(checkout, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "injected float #{kind}")
            commit = git(checkout, "rev-parse", "HEAD")
            git(@journal.repo_root, "update-ref", @journal.ref, commit, old)
            assert Models::EvidenceEvent.chain_valid?(@journal.read_events("assignment").select { |event| event["attempt_id"] == @attempt })
            assert_equal replacement, @journal.service_request("service-request")
            error = assert_raises(AttemptErrors::EvidenceUnavailable) { owner.challenge!(replacement, current: false) }
            assert_match(kind == "record" ? /selector is invalid/ : /accepted authority mutation/, error.message)
            pending = assert_raises(AttemptErrors::EvidenceUnavailable) do
              @endcap.service_settlement_evidence!(journal: @journal,
                events: @journal.read_events("assignment").select { |event| event["attempt_id"] == @attempt },
                params: {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}, map: @map, commit: commit)
            end
            refute_kind_of AttemptErrors::ServiceSettlementPending, pending
          end
        end
      end

      def test_actual_client_server_challenge_eof_and_completion_transfer
        fixture do
          request_service
          @launch.close_execution_scope!(params: {"mapping_id" => "mapping", "assignment_id" => "assignment",
            "attempt_id" => @attempt, "mutation_id" => "seal", "expected_generation" => generation}, peer: @launcher, role: :launcher)
          client = start_service_server
          params = {"assignment_id" => "assignment", "attempt_id" => @attempt, "head" => @head,
            "candidate_generation" => 1, "request_id" => "service-request", "expected_generation" => generation}
          result = client.call("claim_service_settlement", params, mutation_id: "wire-challenge", timeout: 60)
          record = @journal.service_request("service-request")
          assert_equal record.slice("no_effect_challenge", "challenge_generation", "challenge_event_digest"),
            result.data.fetch("reconciliation_challenge")
          socket = UNIXSocket.new(@service.fetch("socket_path"))
          before = @journal.ref_value
          WIRE.write(socket, {"version" => 1, "operation" => "claim_service_settlement", "project_id" => "project",
            "mutation_id" => "extra-body", "params" => params.merge("mapping_id" => "mapping", "expected_generation" => generation)},
            deadline: WIRE.deadline(2))
          socket.write("unexpected body")
          socket.shutdown(Socket::SHUT_WR)
          refusal = WIRE.read(socket, deadline: WIRE.deadline(3))
          assert_equal "invalid_input", refusal.dig("error", "code")
          socket.close
          assert_equal before, @journal.ref_value
          completion, parts = no_effect_upload(record, Authority::ServiceEvidence.new(journal: @journal).challenge!(record))
          response = client.call("complete_no_effect", completion.except("transfer").merge("assignment_id" => "assignment", "attempt_id" => @attempt),
            mutation_id: "wire-settle", upload_parts: parts.parts, purpose: :receipt_artifacts, timeout: 60)
          assert_equal "failed-settled", response.data.fetch("state")
          assert_equal "failed-settled", @journal.service_request("service-request").fetch("state")
        ensure
          socket&.close unless socket&.closed?
        end
      end

      def test_actual_challenge_import_settlement_and_exact_replay
        fixture do
          request_service
          challenge_params, result = seal_and_challenge
          replay = call("claim_service_settlement", challenge_params, id: "challenge", peer: @executor, role: :executor)
          assert_equal result.fetch(:data), replay.fetch(:data)
          record = @journal.service_request("service-request")
          owner = Authority::ServiceEvidence.new(journal: @journal)
          challenge = owner.challenge!(record)
          pending = assert_raises(AttemptErrors::ServiceSettlementPending) do
            @endcap.service_settlement_evidence!(journal: @journal,
              events: @journal.read_events("assignment").select { |entry| entry["attempt_id"] == @attempt },
              params: {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt},
              map: @map, commit: @journal.ref_value)
          end
          assert_match(/unsettled/, pending.message)
          params, parts = no_effect_upload(record, challenge)
          valid = parts.parts.last
          assert owner.inspection!(valid, record, challenge)
          original_json = valid.lines.last.delete_prefix("ace-service-no-effect ")
          parsed = JSON.parse(original_json)
          invalid = [parsed.merge("version" => 1.0), parsed.merge("challenge_generation" => parsed.fetch("challenge_generation").to_f),
            parsed.merge("effect_absent" => 1), parsed.merge("target" => {"resource" => "other"})]
            .map { |body| "ace-service-no-effect #{JSON.generate(body)}\n" }
          invalid.concat(["ace-service-no-effect #{original_json.chomp} trailing\n",
            "ace-service-no-effect #{original_json.sub('{', '{"version":1,')}\n", "ace-service-no-effect \xff".b,
            valid + valid, "x" * (Molecules::CanonicalEvidence::MAX_ARTIFACT_BYTES + 1)])
          invalid.each { |bytes| assert_raises(AttemptErrors::EvidenceUnavailable) { owner.inspection!(bytes, record, challenge) } }
          completed = call("complete_no_effect", params, id: "settlement", peer: @executor, role: :executor, transfer: parts)
          assert_equal "failed-settled", completed.dig(:data, "state")
          settled = @journal.service_request("service-request")
          projection = @endcap.service_settlement_evidence!(journal: @journal,
            events: @journal.read_events("assignment").select { |event| event["attempt_id"] == @attempt },
            params: {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt},
            map: @map, commit: @journal.ref_value)
          assert_equal "failed-settled", projection.fetch("services").first.fetch("state")
          assert_equal settled.fetch("receipt").fetch("evidence"), projection.fetch("services").first.fetch("evidence_refs")
          assert_raises(FrozenError) { projection.fetch("services").first["state"].replace("changed") }
          original_commit = @journal.ref_value
          replay = call("complete_no_effect", params, id: "settlement", peer: @executor, role: :executor, transfer: parts)
          assert_equal completed.fetch(:data), replay.fetch(:data)
          assert_equal original_commit, @journal.ref_value
          restart
          assert_equal "failed-settled", @journal.service_request("service-request").fetch("state")
          assert_equal 1, @journal.read_events("assignment").count { |event| event["type"] == "service_no_effect_challenge" }
        end
      end
    end
  end
end
