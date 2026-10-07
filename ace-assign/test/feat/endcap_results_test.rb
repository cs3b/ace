# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../support/endcap_result_owner_fixture"
require "ace/assign/authority/endcap"
require "ace/assign/authority/launch_lifecycle"
require "ace/assign/authority/router"
require "ace/assign/authority/server"
require "ace/assign/authority/client"

module Ace
  module Assign
    # Real journal and wire seams with injected source-authorization identities.
    # This fixture does not claim installed native launch/scope/security proof.
    class EndcapResultsTest < AceAssignTestCase
      include EndcapResultOwnerFixture

      def test_result_private_record_and_ordered_blobs_commit_once_with_distinct_digests
        fixture do
          params, input, receipt = upload
          original = Models::ExecutionReceipt.from_h(receipt).digest
          result = call("submit_result", params, id: "result", transfer: input)
          data = result.fetch(:data)
          assert_equal (Authority::Endcap::RESULT_FIELDS + %w[generation journal_commit]).sort, data.keys.sort
          assert_equal original, data.fetch("original_receipt_digest")
          assert_equal params["receipt_sha256"], data["uploaded_receipt_sha256"]
          refute_equal data["receipt_digest"], data["original_receipt_digest"]
          events = @journal.read_events("assignment", commit: data.fetch("journal_commit")).select { |event| event["attempt_id"] == @attempt }
          assert Models::EvidenceEvent.chain_valid?(events)
          private_record = events.find { |event| event["type"] == "result_submitted" }.fetch("payload")
          assert_equal Authority::Endcap::RESULT_PAYLOAD_FIELDS.sort, private_record.keys.sort
          assert_equal @binding, private_record.dig("binding", "process_binding")
          assert_equal receipt["producer"], private_record.dig("receipt", "producer")
          assert_equal "first\x00\r\n".b, fetch(data).fetch(:transfer_parts).first
          assert_equal "second evidence", fetch(data, 1).fetch(:transfer_parts).first
          refute events.any? { |event| %w[receipt_accepted transition].include?(event["type"]) }
          before = @journal.ref_value
          replay = call("submit_result", params, id: "result", transfer: input)
          assert replay.fetch(:replayed)
          assert_equal data, replay.fetch(:data)
          assert_equal before, @journal.ref_value
          assert_equal 1, @journal.read_events("assignment").count { |event| event["type"] == "result_submitted" }
          assert_raises(AttemptErrors::Conflict) { call("submit_result", params, id: "new-result", transfer: input) }
          assert_raises(AttemptErrors::Conflict) { call("submit_result", params.merge("expected_generation" => 0), id: "result", transfer: input) }
          assert_equal before, @journal.ref_value
        end
      end

      def test_failed_empty_result_survives_restart_exit_discovery_and_same_head_correction
        fixture do
          data = submit(verdict: "failed", parts: []).fetch(:data)
          assert_empty data["artifacts"]
          FileUtils.rm_rf(@project.fetch("assignment_root"))
          FileUtils.rm_rf(File.join(@root, "checkout"))
          restart
          @kernel.dead << @worker.fetch("pid")
          assert_equal data.slice(*Authority::Endcap::RESULT_FIELDS), status.fetch("submitted_result")
          assert_raises(AttemptErrors::EvidenceUnavailable) { submit(verdict: "failed", parts: []) }
          @kernel.dead.clear
          candidate(2)
          params, input, = upload(parts: ["corrected"])
          corrected = call("submit_result", params.merge("candidate_generation" => 2), id: "corrected", transfer: input).fetch(:data)
          assert_equal @head, corrected["head"]
          refute_equal data["result_id"], corrected["result_id"]
          assert_equal corrected["result_id"], status.fetch("submitted_result").fetch("result_id")
          assert_equal data["result_id"], status(1).fetch("submitted_result").fetch("result_id")
          assert_raises(AttemptErrors::NotFound) { status(3) }
        end
      end

      def test_canonical_absence_is_null_and_selectors_schema_and_executor_fail_closed
        fixture do
          assert_nil status.fetch("submitted_result")
          assert_equal 1, status.fetch("result_candidate_generation")
          assert_raises(ArgumentError) { status(-1) }
          assert_raises(ArgumentError) { call("attempt_status", {}) }
          assert_raises(ArgumentError) { call("attempt_status", {"result_candidate_generation" => nil}, id: "illegal") }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { status(nil, peer: @executor, role: :executor) }
        end
      end

      def test_source_authorization_roles_reassignment_visibility_and_wrong_purposes
        fixture do
          data = submit.fetch(:data)
          [[:worker, @worker], [:launcher, @launcher], [:supervisor, @supervisor]].each do |role, peer|
            projection = status(nil, peer: peer, role: role)
            assert_equal data["result_id"], projection.dig("submitted_result", "result_id")
            if role == :worker
              %w[process_binding launcher_identity mapping_id receipt producer binding].each { |key| refute projection.key?(key), key }
              %w[receipt producer binding process_binding].each { |key| refute projection.fetch("submitted_result").key?(key), key }
            end
            assert_equal "first\x00\r\n".b, fetch(data, peer: peer, role: role).fetch(:transfer_parts).first
          end
          assert_raises(AttemptErrors::UnauthorizedIdentity) { fetch(data, peer: @executor, role: :executor) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { fetch(data, peer: @launcher.merge("started_at" => "reused"), role: :launcher) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { fetch(data, peer: @reviewer, role: :reviewer) }
          review_params = {"head" => @head, "candidate_generation" => 1, "expected_generation" => generation,
            "reviewer_uid" => @reviewer["uid"], "reviewer_process_binding" => @reviewer}
          call("assign_review", review_params, id: "review", peer: @launcher, role: :launcher)
          projection = status(nil, peer: @reviewer, role: :reviewer)
          assert_equal data["result_id"], projection.dig("submitted_result", "result_id")
          %w[process_binding launcher_identity mapping_id receipt producer binding].each { |key| refute projection.key?(key), key }
          %w[receipt producer binding process_binding].each { |key| refute projection.fetch("submitted_result").key?(key), key }
          assert_equal "first\x00\r\n".b, fetch(data, peer: @reviewer, role: :reviewer).fetch(:transfer_parts).first
          candidate(2)
          assert_equal data["result_id"], status(1, peer: @reviewer, role: :reviewer).dig("submitted_result", "result_id")
          call("assign_review", review_params.merge("candidate_generation" => 2, "expected_generation" => generation),
            id: "review-new", peer: @launcher, role: :launcher)
          assert_raises(AttemptErrors::UnauthorizedIdentity) { fetch(data, peer: @reviewer, role: :reviewer) }
          @revoked << @supervisor["uid"]
          assert_raises(AttemptErrors::UnauthorizedIdentity) { status }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { fetch(data) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            call("evidence_fetch", {"kind" => "review", "purpose_id" => "anything", "artifact_id" => "artifact"}, peer: @worker)
          end
        end
      end

      def test_bad_receipt_producer_digest_artifact_order_and_stale_candidate_do_not_change_ref
        fixture do
          before = @journal.ref_value
          params, input, receipt = upload
          [receipt.merge("producer" => {"actor" => "forged", "role" => "worker", "runtime" => "herdr"}),
           receipt.merge("digest" => "c" * 64), receipt.merge("campaign" => {}), receipt.merge("extra" => true)].each_with_index do |bad, i|
            bad_params, bad_input, = upload(receipt: bad)
            assert_raises(AttemptErrors::ReceiptRejected, AttemptErrors::EvidenceUnavailable) { call("submit_result", bad_params, id: "bad-#{i}", transfer: bad_input) }
            assert_equal before, @journal.ref_value
          end
          input.parts[1], input.parts[2] = input.parts[2], input.parts[1]
          assert_raises(AttemptErrors::ReceiptRejected) { call("submit_result", params, id: "reordered", transfer: input) }
          params, input, = upload
          assert_raises(AttemptErrors::Conflict) { call("submit_result", params.merge("candidate_generation" => 0), id: "stale", transfer: input) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { call("submit_result", params, id: "forged-peer", peer: @worker.merge("started_at" => "reused"), transfer: input) }
          assert_raises(ArgumentError) { call("submit_result", params.merge("actor" => "worker"), id: "extra", transfer: input) }
          assert_equal before, @journal.ref_value
        end
      end
    end
  end
end

module Ace
  module Assign
    class EndcapResultsTest
      def start_server
        @kernel.peer_identity = @worker
        @server = Authority::Server.new(authority_id: "authority", lifecycle: @router,
          deployment: @deployment, kernel: @kernel, composition: "services")
        # Private socket directory is a source fixture, not installer proof.
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

      def client_params(params)
        params.except("mapping_id", "transfer").merge("assignment_id" => "assignment", "attempt_id" => @attempt)
      end

      def client_fetch(data)
        @client.call("evidence_fetch", client_params("kind" => "result", "purpose_id" => data.fetch("result_id"),
          "artifact_id" => data.fetch("artifacts").first.fetch("path").delete_prefix("evidence/imports/")),
          download: true, purpose: :artifacts, timeout: 30)
      end

      def test_real_client_server_submit_lost_reply_exit_restart_status_and_exact_fetch
        fixture do
          start_server
          params, input, = upload
          original_dispatch = @router.method(:dispatch)
          lost_once = false
          @router.define_singleton_method(:dispatch) do |**options|
            result = original_dispatch.call(**options)
            if options.fetch(:request).fetch("operation") == "submit_result" && !lost_once
              lost_once = true
              raise IOError, "source fixture reply lost after durable CAS"
            end
            result
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @client.call("submit_result", client_params(params), mutation_id: "wire-result", upload_parts: input.parts, purpose: :receipt_artifacts, timeout: 30)
          end
          @kernel.dead << @worker.fetch("pid")
          @kernel.peer_identity = @supervisor
          FileUtils.rm_rf(@project.fetch("assignment_root"))
          FileUtils.rm_rf(File.join(@root, "checkout"))
          @journal = Molecules::EvidenceJournal.new(repo_root: @journal.repo_root, checkout_root: File.join(@root, "new-checkout"),
            mode: :protected, evidence_reader: ->(*) { raise "unused" }, service_authorizer: ->(*) { raise "unused" })
          restart
          router = @router
          @server.instance_variable_set(:@lifecycle, router)
          discovered = @client.call("attempt_status", client_params("result_candidate_generation" => nil), timeout: 30)
          assert_equal false, discovered.replayed
          data = discovered.data.fetch("submitted_result")
          assert_equal generation, discovered.data.fetch("authority_generation")
          assert_equal 2, data.fetch("artifacts").length
          refute data.key?("receipt")
          refute data.key?("binding")
          reply = client_fetch(data)
          assert_equal ["first\x00\r\n".b], reply.parts
          descriptor, transfer = reply.data.values_at("descriptor", "transfer")
          assert_equal [descriptor.slice("bytes", "sha256")], transfer.fetch("parts")
          assert_equal descriptor["sha256"], transfer["sha256"]
          assert_equal @journal.ref_value, reply.data["journal_commit"]
          assert_empty Dir.children(File.join(@root, "transfers"))
          @revoked << @supervisor.fetch("uid")
          assert_raises(AttemptErrors::EvidenceUnavailable) { client_fetch(data) }
        end
      end

      def test_real_client_refuses_missing_mismatched_extra_part_and_open_descriptor_before_bytes
        fixture do
          data = submit.fetch(:data)
          start_server
          original = @router.method(:dispatch)
          corruption = nil
          @router.define_singleton_method(:dispatch) do |**options|
            result = original.call(**options)
            if options.fetch(:request).fetch("operation") == "evidence_fetch"
              result = Marshal.load(Marshal.dump(result))
              case corruption
              when :missing then result[:data].delete("descriptor")
              when :mismatch then result[:data]["descriptor"]["sha256"] = "f" * 64
              when :extra then result[:transfer_parts] << "extra"
              when :open then result[:data]["descriptor"]["private"] = "must not escape"
              end
            end
            result
          end
          wire = @server.send(:wire)
          wire.define_singleton_method(:write) do |socket, value, **options|
            if corruption == :missing_transfer && value.dig("data", "descriptor")
              value = Marshal.load(Marshal.dump(value))
              value["data"].delete("transfer")
            end
            WIRE.write(socket, value, **options)
          end
          %i[missing missing_transfer mismatch extra open].each do |bad|
            corruption = bad
            assert_raises(AttemptErrors::EvidenceUnavailable) { client_fetch(data) }
          end
          corruption = nil
          assert_equal ["first\x00\r\n".b], client_fetch(data).parts
        end
      end

      def alter_canonical(path, bytes)
        @journal.send(:with_lock) do
          checkout = @journal.send(:checkout_dir)
          bytes.nil? ? File.unlink(File.join(checkout, path)) : File.binwrite(File.join(checkout, path), bytes)
          git(checkout, "add", "--", path)
          git(checkout, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "corrupt canonical fixture")
          git(@journal.repo_root, "update-ref", @journal.ref, git(checkout, "rev-parse", "HEAD"))
        end
      end

      def test_corrupt_blob_and_private_record_never_fall_back_to_workspace_or_cached_reply
        fixture do
          params, input, = upload
          data = call("submit_result", params, id: "result", transfer: input).fetch(:data)
          commit = @journal.ref_value
          artifact = data.fetch("artifacts").first.fetch("path")
          File.binwrite(File.join(@journal.repo_root, "private-0"), input.parts[1])
          alter_canonical(artifact, "corruption")
          assert_raises(AttemptErrors::EvidenceUnavailable) { status }
          assert_raises(AttemptErrors::EvidenceUnavailable) { fetch(data) }
          assert_raises(AttemptErrors::EvidenceUnavailable) { call("submit_result", params, id: "result", transfer: input) }
          git(@journal.repo_root, "update-ref", @journal.ref, commit)
          event = @journal.read_events("assignment").find { |item| item["type"] == "result_submitted" }
          path = "execution/assignment/events/#{@journal.send(:event_filename, event)}"
          changed = Marshal.load(Marshal.dump(event))
          changed["payload"]["receipt"]["producer"]["actor"] = "forged"
          alter_canonical(path, JSON.generate(changed))
          restart
          assert_raises(AttemptErrors::EvidenceUnavailable) { status }
          assert_raises(AttemptErrors::EvidenceUnavailable) { fetch(data) }
          git(@journal.repo_root, "update-ref", @journal.ref, commit)
          alter_canonical(path, nil)
          assert_raises(AttemptErrors::EvidenceUnavailable) { status }
          assert_raises(AttemptErrors::EvidenceUnavailable) { fetch(data) }
          git(@journal.repo_root, "update-ref", @journal.ref, commit)
          duplicate = Models::EvidenceEvent.build(type: "result_submitted", attempt_id: @attempt,
            previous_digest: @journal.read_events("assignment").last.fetch("digest"), payload: event.fetch("payload"))
          @journal.append(assignment_id: "assignment", attempt_id: @attempt, events: [duplicate])
          assert_raises(AttemptErrors::EvidenceUnavailable) { status }
          assert_raises(AttemptErrors::EvidenceUnavailable) { fetch(data) }
        end
      end

      def test_pre_cas_failure_leaves_no_result_and_cas_retry_revalidates_generation
        fixture do
          params, input, = upload
          before = @journal.ref_value
          @journal.stub(:update_ref_cas, ->(*) { raise IOError, "source fixture CAS failure" }) do
            assert_raises(IOError) { call("submit_result", params, id: "before-cas", transfer: input) }
          end
          assert_equal before, @journal.ref_value
          assert_nil status.fetch("submitted_result")
          assert_empty @journal.read_events("assignment").select { |event| event["type"] == "result_submitted" }
          original = @journal.method(:update_ref_cas)
          journal = @journal
          competed = false
          @journal.define_singleton_method(:update_ref_cas) do |new_commit, old|
            unless competed
              competed = true
              output, error, status = Open3.capture3("git", "-C", repo_root, "-c", "user.name=test", "-c", "user.email=test@example.invalid",
                "commit-tree", "#{new_commit}^{tree}", "-p", old, "-m", "same-id competing source fixture", stdin_data: "")
              raise error unless status.success?
              _out, error, status = Open3.capture3("git", "-C", repo_root, "update-ref", ref, output.strip, old)
              raise error unless status.success?
              next false
            end
            original.call(new_commit, old)
          end
          replay = call("submit_result", params, id: "competing", transfer: input)
          assert replay.fetch(:replayed)
          assert_equal @journal.ref_value, replay.dig(:data, "journal_commit")
          assert_equal 1, @journal.read_events("assignment").count { |event| event["type"] == "result_submitted" }
        end
      end
    end
  end
end

module Ace
  module Assign
    class EndcapResultsTest
      def test_retained_review_fetch_exact_reviewer_purpose_and_terminal_result_permissions
        fixture do
          data = submit.fetch(:data)
          review = call("assign_review", {"head" => @head, "candidate_generation" => 1, "expected_generation" => generation,
            "reviewer_uid" => @reviewer["uid"], "reviewer_process_binding" => @reviewer},
            id: "review", peer: @launcher, role: :launcher).fetch(:data)
          _, _, receipt = upload(parts: ["review report"])
          receipt.merge!("operation" => "review", "review" => {"head" => @head, "verdict" => "approved",
            "reviewer" => {"actor" => review.fetch("reviewer_actor")}})
          params, input, = upload(parts: ["review report"], receipt: receipt)
          accepted = call("accept_review", params.merge("purpose_id" => review.fetch("review_id")), id: "accept-review",
            peer: @reviewer, role: :reviewer, transfer: input).fetch(:data)
          ref = accepted.fetch("review_receipt").fetch("artifacts").first
          fetch_params = {"kind" => "review", "purpose_id" => review.fetch("review_id"),
            "artifact_id" => ref.fetch("path").delete_prefix("evidence/imports/")}
          [[:reviewer, @reviewer], [:launcher, @launcher], [:supervisor, @supervisor]].each do |role, peer|
            assert_equal ["review report"], call("evidence_fetch", fetch_params, peer: peer, role: role).fetch(:transfer_parts)
          end
          assert_raises(AttemptErrors::UnauthorizedIdentity) { call("evidence_fetch", fetch_params) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { call("evidence_fetch", fetch_params, peer: @executor, role: :executor) }
          submitted = @journal.read_events("assignment").find { |event| event["type"] == "result_submitted" }.fetch("payload")
          selected = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}
          @launch.close_execution_scope!(params: selected.merge("mutation_id" => "retained-seal", "expected_generation" => generation), peer: @launcher, role: :launcher)
          @launch.close_execution_scope!(params: selected.merge("mutation_id" => "retained-proof", "expected_generation" => generation), peer: @launcher, role: :launcher)
          binding = submitted.fetch("binding")
          canonical = Molecules::CanonicalEvidence.new(journal: @journal)
          reader = ->(_, artifact) { canonical.read({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
            kind: "result", project_id: "project", assignment_id: "assignment", attempt_id: @attempt, peer_uid: @worker.fetch("uid"),
            binding: binding, request_id_or_event_id: binding.fetch("result_id"), generation: binding.fetch("candidate_generation")) }
          coordinator = Organisms::AttemptCoordinator.new(cache_base: File.join(@root, "retained-terminal-cache"), repo_root: @journal.repo_root,
            journal: @journal, verifier: Molecules::ReceiptVerifier.new(artifact_reader: reader), lifecycle_exclusion: @launch.send(:exclusion_for, @map, @journal))
          path = File.join(@root, "retained-terminal-receipt.json")
          File.write(path, JSON.generate(submitted.fetch("receipt")))
          identity = Molecules::ExecutionIdentityResolver::Identity.new(actor: "fixture-operator", role: "coordinator", runtime: "local")
          assert_equal "succeeded", coordinator.finish(attempt_id: @attempt, receipt_path: path, identity: identity).state
          @kernel.dead << @worker.fetch("pid")
          restart
          assert_equal data["result_id"], status(1).dig("submitted_result", "result_id")
          assert_equal ["first\x00\r\n".b], fetch(data).fetch(:transfer_parts)
          assert_equal ["review report"], call("evidence_fetch", fetch_params, peer: @reviewer, role: :reviewer).fetch(:transfer_parts)
          @kernel.dead << @reviewer.fetch("pid")
          assert_raises(AttemptErrors::EvidenceUnavailable) { call("evidence_fetch", fetch_params, peer: @reviewer, role: :reviewer) }
          assert_equal ["review report"], call("evidence_fetch", fetch_params, peer: @launcher, role: :launcher).fetch(:transfer_parts)
          assert_raises(AttemptErrors::EvidenceUnavailable) { submit }
        end
      end

      def test_recorded_executor_fetches_only_own_canonical_terminal_service_evidence
        fixture do
          owner = Authority::ServiceEvidence.new(journal: @journal)
          @journal.instance_variable_set(:@evidence_reader, ->(reference, record, state, pending) { owner.call(reference, record, state, pending) })
          @journal.instance_variable_set(:@service_authorizer, ->(*) {})
          binding = {"request_id" => "request-1", "assignment_id" => "assignment", "attempt_id" => @attempt,
            "project_id" => "project", "operation" => "publish", "input_digest" => "a" * 64, "target" => {"resource" => "fixture"},
            "candidate_head" => @head, "executor_uid" => @executor["uid"], "transport" => "unix", "dispatch_ticket_id" => "ticket",
            "claim_binding" => "b" * 64, "candidate_generation" => 1, "claim_generation" => 1, "policy_digest" => "c" * 64}
          claim = binding.merge("state" => "accepted")
          @journal.mutate(assignment_id: "assignment", attempt_id: @attempt, mutation_id: "claim", operation: "fixture",
            parameters_digest: "a" * 64, expected_generation: generation) do
            {data: {}, service_updates: [{request_id: "request-1", expected: nil, replacement: claim, event_type: "service_claim"}]}
          end
          bytes = "ace-service-attestation request:request-1 input:#{binding.fetch('input_digest')} outcome:succeeded\nexecuted fixture"
          events = @journal.read_events("assignment").select { |event| event["attempt_id"] == @attempt }
          plan = Molecules::CanonicalEvidence.new(journal: @journal).import_plan(**owner.context(binding), artifacts: [bytes],
            admitted_after_event_digest: events.last.fetch("digest"))
          receipt = binding.slice(*Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS).merge("outcome" => "succeeded", "evidence" => plan.fetch(:references))
          completed = binding.merge("state" => "succeeded", "receipt" => receipt)
          @journal.mutate(assignment_id: "assignment", attempt_id: @attempt, mutation_id: "complete", operation: "fixture",
            parameters_digest: "b" * 64, expected_generation: generation) do
            plan.merge(data: {}, service_updates: [{request_id: "request-1", expected: claim, replacement: completed, event_type: "service_transition"}])
          end
          params = {"kind" => "service", "purpose_id" => "request-1", "artifact_id" => plan.fetch(:references).first.fetch("ref").delete_prefix("evidence/imports/")}
          [[:executor, @executor], [:launcher, @launcher], [:supervisor, @supervisor]].each do |role, peer|
            assert_equal [bytes], call("evidence_fetch", params, peer: peer, role: role).fetch(:transfer_parts)
          end
          assert_raises(AttemptErrors::UnauthorizedIdentity) { call("evidence_fetch", params, peer: @executor.merge("uid" => 13006), role: :executor) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { call("evidence_fetch", params) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { call("evidence_fetch", params, peer: @reviewer, role: :reviewer) }
          @revoked << @executor["uid"]
          assert_raises(AttemptErrors::UnauthorizedIdentity) { call("evidence_fetch", params, peer: @executor, role: :executor) }
          # Inbox now has its canonical reader; this service request is not
          # an inbox registration. Observation still has no protected reader.
          assert_raises(AttemptErrors::NotFound) do
            call("evidence_fetch", params.merge("kind" => "inbox"), peer: @supervisor, role: :supervisor)
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            call("evidence_fetch", params.merge("kind" => "observation"), peer: @supervisor, role: :supervisor)
          end
        end
      end
    end
  end
end

module Ace
  module Assign
    class EndcapResultsTest
      def test_services_read_body_and_mutation_metadata_refuse_without_canonical_change
        fixture do
          data = submit.fetch(:data)
          start_server
          @kernel.peer_identity = @supervisor
          before = @journal.ref_value
          requests = [
            ["attempt_status", {"result_candidate_generation" => nil}],
            ["evidence_fetch", {"kind" => "result", "purpose_id" => data.fetch("result_id"),
              "artifact_id" => data.fetch("artifacts").first.fetch("path").delete_prefix("evidence/imports/")}]
          ]
          socket = nil
          requests.each do |operation, params|
            socket = UNIXSocket.new(@service.fetch("socket_path"))
            WIRE.write(socket, {"version" => 1, "operation" => operation, "project_id" => "project", "mutation_id" => nil,
              "params" => client_params(params).merge("mapping_id" => "mapping")}, deadline: WIRE.deadline(2))
            socket.write("unexpected body")
            socket.shutdown(Socket::SHUT_WR)
            reply = WIRE.read(socket, deadline: WIRE.deadline(2))
            assert_equal "invalid_input", reply.dig("error", "code")
            refute reply.key?("data")
            socket.close
          end
          assert_equal before, @journal.ref_value
        ensure
          socket&.close
        end
      end
    end
  end
end

module Ace
  module Assign
    class EndcapResultsTest
      def test_campaign_result_and_review_refuse_before_local_campaign_manager_lookup
        require "ace/review"
        fixture do
          review = call("assign_review", {"head" => @head, "candidate_generation" => 1, "expected_generation" => generation,
            "reviewer_uid" => @reviewer["uid"], "reviewer_process_binding" => @reviewer},
            id: "review", peer: @launcher, role: :launcher).fetch(:data)
          bytes = JSON.generate("campaign_id" => "campaign-1", "accepted" => true, "dry_run" => false,
            "result_identity" => "fixture", "evidence" => {"current_head" => @head})
          _, _, receipt = upload(parts: [bytes])
          receipt.merge!("operation" => "review", "review" => {"head" => @head, "verdict" => "approved",
            "reviewer" => {"actor" => review.fetch("reviewer_actor")}},
            "campaign" => {"id" => "campaign-1", "result" => receipt.fetch("artifacts").first})
          params, input, = upload(parts: [bytes], receipt: receipt)
          before = @journal.ref_value
          Ace::Review::Organisms::CampaignManager.stub(:new, ->(**_) { flunk "protected receipt must never consult local campaign state" }) do
            assert_raises(AttemptErrors::EvidenceUnavailable) { call("submit_result", params, id: "campaign-result", transfer: input) }
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              call("accept_review", params.merge("purpose_id" => review.fetch("review_id")), id: "campaign-review",
                transfer: input, peer: @reviewer, role: :reviewer)
            end
          end
          assert_equal before, @journal.ref_value
        end
      end
    end
  end
end
