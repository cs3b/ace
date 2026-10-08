# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../support/execution_scope_observation_fixtures"
require_relative "../support/protected_inbox_context_pipeline_fixture"
require "ace/assign/authority/endcap"
require "ace/assign/authority/inbox_observation_producer"
require "ace/assign/authority/inbox_observation_signer"
require "ace/herdr/organisms/inbox"
require "ace/herdr/organisms/inbox_context_owner"
require "ace/herdr/organisms/inbox_context_server"
require "ace/assign/authority/inbox_context_completion"
require "ace/assign/authority/inbox_context_original"
require "ace/assign/authority/server"
require "ace/assign/authority/router"
require "ace/herdr/cli"
require_relative "../../../ace-herdr/test/support/inbox_context_owner_fixture"

require_relative "../support/endcap_inbox_fixture"
module Ace
  module Assign
    class EndcapObservationsTest < AceAssignTestCase
      include EndcapInboxFixture
      def prepare_observation
        @observer = process(95, 13008)
        @signer = process(96, 13010)
        record = Ace::Herdr::Molecules::DeliveryRecordStore.load(@context.fetch("deliveries_dir"), "event")
        @runtime = {"assignment_id" => "assignment", "attempt_id" => "attempt", "provider" => "codex", "provider_version" => "0.159.3",
          "native_target" => record.inbox.fetch("binding").slice(*Authority::ObservationTrust::TARGET),
          "runtime_process_binding" => process(94, 13009), "endpoint_reference_sha256" => "c" * 64, "observer_uid" => 13008}
        intent = {"schema" => "ace.herdr.codex-submission/v1", "provider_version" => "0.159.3", "endpoint_reference_sha256" => "c" * 64,
          "server_process_binding" => @runtime.fetch("runtime_process_binding"), "thread_id" => @runtime.dig("native_target", "thread"),
          "event_id" => "event", "attempt_id" => "attempt", "claim_generation" => record.inbox.fetch("claim_generation"),
          "payload_sha256" => record.answer_digest, "client_user_message_id" => "ace-" + "d" * 32}
        queue = intent.slice("provider_version", "endpoint_reference_sha256", "server_process_binding", "thread_id", "payload_sha256", "client_user_message_id")
          .merge("queued_submission_id" => "0123abcd-0000-4000-8000-000000000002")
        inbox = record.inbox.merge("codex_submission" => intent, "receipt" => record.inbox.fetch("receipt").merge("codex_submission" => queue))
        Ace::Herdr::Molecules::DeliveryRecordStore.save(record.advance_inbox(state: record.state, inbox: inbox,
          detail: {"action" => "maintained source correlation fixture"}, timestamp: Time.now.utc.iso8601), @context.fetch("deliveries_dir"))
        @context.merge!("observer_uids" => [13008], "signer_uids" => [13010], "runtime_bindings" => {"runtime" => @runtime})
        prior_project = @deployment.method(:project)
        @deployment.define_singleton_method(:project) do |id|
          prior_project.call(id).merge("observer_uids" => [13008], "signer_uids" => [13010],
            "peer_credentials" => {"13008" => {"gid" => 13008, "groups" => [13008]}, "13010" => {"gid" => 13010, "groups" => [13010]},
              "13004" => {"gid" => 13004, "groups" => [13004]}})
        end
        reference = {"provider" => "codex", "version" => "0.159.3", "thread_id" => intent.fetch("thread_id"),
          "queued_submission_id" => queue.fetch("queued_submission_id"), "client_user_message_id" => intent.fetch("client_user_message_id"),
          "turn_id" => "0123abcd-0000-4000-8000-000000000003", "item_id" => "item-1", "payload_sha256" => record.answer_digest}
        excerpt = {"status" => "completed", "native_reference" => reference}
        @observation = {"schema" => "ace.native-observation.v1", "provider" => "codex", "provider_version" => "0.159.3",
          "event_id" => "event", "attempt_id" => "attempt", "claim_generation" => record.inbox.fetch("claim_generation"),
          "payload_sha256" => record.answer_digest, "binding" => record.inbox.fetch("binding"),
          "runtime_process_binding" => @runtime.fetch("runtime_process_binding"), "outcome" => "consumed", "native_reference" => reference,
          "source_sha256" => Digest::SHA256.hexdigest(JSON.generate(excerpt)), "source_bytes" => JSON.generate(excerpt).bytesize, "source_excerpt" => excerpt}
      end

      def import_observation(id: "observe", bytes: JSON.generate(@observation), peer: @observer, role: :observer, generation: @journal.authority_generation(events))
        params = @params.slice("mapping_id", "assignment_id", "attempt_id", "event_id", "inbox_context_id", "expected_registration").merge(
          "expected_generation" => generation, "observation_sha256" => Digest::SHA256.hexdigest(bytes), "transfer" => {})
        @owner.dispatch(request: {"operation" => "import_observation", "project_id" => "project", "mutation_id" => id, "params" => params},
          peer: peer, role: role, transfer: Parts.new([bytes]))
      end

      def fetch_observation(evidence_id, peer: @signer, role: :signer)
        params = @params.slice("mapping_id", "assignment_id", "attempt_id", "event_id", "inbox_context_id").merge("evidence_id" => evidence_id)
        @owner.dispatch(request: {"operation" => "fetch_observation", "project_id" => "project", "mutation_id" => nil, "params" => params}, peer: peer, role: role)
      end

      # Reuses the actual owner/journal fixture. Only native completed-turn
      # query and installed process credentials are controlled source seams.
      def joined_workflows
        prepare_observation
        original = {"project_id" => "project", "mapping_id" => "mapping", "assignment_id" => "assignment", "inbox_context_id" => "context"}
        record = Ace::Herdr::Molecules::DeliveryRecordStore.load(@context.fetch("deliveries_dir"), "event")
        Ace::Herdr::Molecules::DeliveryRecordStore.save(record.advance_inbox(state: record.state,
          inbox: record.inbox.merge("original_context" => original, "original_binding_digest" => events.find { |event| event["type"] == "scope_native_bound" }.fetch("digest")), detail: {"action" => "retained original fixture"},
          timestamp: Time.now.utc.iso8601), @context.fetch("deliveries_dir"))
        grants = @context_grants + [@observer, @signer].map { |peer| peer.slice("uid", "gid", "groups").merge("role" => "supervisor", "purposes" => ["observe_to_sign"]) }
        @context_owner = Ace::Herdr::Organisms::InboxContextOwner.new(context_id: "context", deliveries_dir: @context.fetch("deliveries_dir"),
          grants: grants, store: @context_store, keys: @context_keys, kernel: @kernel, inbox: @box, completion: @context_completion, epoch: context_owner_epoch)
        @candidate = @observation.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding").merge(
          "observation" => {"outcome" => "consumed", "native_reference" => @observation.fetch("native_reference"), "server_process_binding" => @runtime.fetch("runtime_process_binding"), "endpoint_reference_sha256" => @runtime.fetch("endpoint_reference_sha256")})
        fixture_owner = self
        @box.instance_variable_get(:@native).define_singleton_method(:observe) { |**| fixture_owner.instance_variable_get(:@candidate).fetch("observation") }
        @context["receipt_private_key"] = {"path" => "/fixture/signer/key"}
        @workflow_uploads = []; @workflow_context_calls = []; @lose_reply = false
        @workflow_peer = @observer
        context = Object.new
        context.define_singleton_method(:request) do |operation, params|
          fixture_owner.instance_variable_get(:@workflow_context_calls) << operation
          opts = params.transform_keys(&:to_sym).merge(peer: fixture_owner.instance_variable_get(:@workflow_peer))
          opts[:deadline] = Ace::Runtime::Molecules::ProtectedSocket.deadline(30) if operation == "observe_context"
          result = fixture_owner.instance_variable_get(:@context_owner).public_send(operation, **opts)
          result = result.merge("attempt_id" => "foreign") if operation == "observe_context" && fixture_owner.instance_variable_get(:@wrong_candidate_response)
          result
        end
        client = Object.new
        client.define_singleton_method(:mapping_id) { "mapping" }
        client.define_singleton_method(:call) do |operation, params, **options|
          peer = fixture_owner.instance_variable_get(:@workflow_peer)
          fixture_owner.instance_variable_get(:@workflow_uploads) << [operation, options[:upload_parts]] if options[:upload_parts]
          selected = params.merge("mapping_id" => "mapping")
          selected["transfer"] = {} if options[:upload_parts]
          result = fixture_owner.instance_variable_get(:@owner).dispatch(request: {"operation" => operation, "project_id" => "project",
            "mutation_id" => options[:mutation_id], "params" => selected}, peer: peer, role: peer["uid"] == 13008 ? :observer : :signer,
            transfer: options[:upload_parts] && Parts.new(options[:upload_parts]))
          raise AttemptErrors::EvidenceUnavailable, "controlled lost canonical reply" if fixture_owner.instance_variable_get(:@lose_reply) && options[:upload_parts]
          Authority::Client::Reply.new(data: result.fetch(:data), parts: result[:transfer_parts], replayed: result[:replayed])
        end
        kernel = PeerKernel.new(@observer)
        @producer = Authority::InboxObservationProducer.new(client: client, deployment: @deployment, kernel: kernel, context_client_factory: ->(**) { context })
        key = @key
        loader = Object.new
        loader.define_singleton_method(:with) do |**_, &block|
          artifacts = Object.new; artifacts.define_singleton_method(:verify_unchanged!) { true }
          block.call(key, artifacts)
        end
        @settler = Authority::InboxObservationSigner.new(client: client, deployment: @deployment, kernel: PeerKernel.new(@signer),
          context_client_factory: ->(*) { context }, signing_key_factory: ->(*) { loader })
      end

      def produce(generation)
        @producer.observe(assignment_id: "assignment", attempt_id: "attempt", event_id: "event", inbox_context_id: "context",
          claim_generation: 1, mutation_id: "producer", expected_generation: generation)
      end

      def settle_observation(id, generation)
        @workflow_peer = @signer
        @settler.settle(assignment_id: "assignment", attempt_id: "attempt", event_id: "event", inbox_context_id: "context",
          evidence_id: id, mutation_id: "settler", expected_generation: generation)
      end

      def test_joined_producer_and_signer_recover_exact_canonical_reply_loss
        fixture do
          joined_workflows
          generation = @journal.authority_generation(events)
          @lose_reply = true
          assert_raises(AttemptErrors::EvidenceUnavailable) { produce(generation) }
          assert_equal 1, @context_owner.status(peer: @authority_peer).fetch("active_operations")
          @lose_reply = false
          imported = produce(generation)
          assert_equal "consumed", imported.fetch("outcome")
          assert_equal 1, events.count { |event| event["type"] == "native_observation" }
          assert_equal 0, @context_owner.status(peer: @authority_peer).fetch("active_operations")
          generation = @journal.authority_generation(events)
          @lose_reply = true
          assert_raises(AttemptErrors::EvidenceUnavailable) { settle_observation(imported.fetch("evidence_id"), generation) }
          assert_equal 1, @context_owner.status(peer: @authority_peer).fetch("active_operations")
          @lose_reply = false
          assert_equal "completed", settle_observation(imported.fetch("evidence_id"), generation).fetch("state")
          proofs = @workflow_uploads.select { |op, _| op == "reconcile_inbox" }.map(&:last)
          assert_equal proofs.first, proofs.last
          assert @key.verify(OpenSSL::Digest::SHA256.new, proofs.first.last, proofs.first.first)
          assert_equal 1, events.count { |event| event["type"] == "inbox_reconciliation" }
          assert_equal 0, @context_owner.status(peer: @authority_peer).fetch("active_operations")
          assert_equal 1, @native_calls
        end
      end

      def test_producer_uncertainty_and_wrong_association_never_import_or_settle
        fixture do
          joined_workflows
          generation = @journal.authority_generation(events)
          @candidate["observation"] = {"outcome" => "uncertain"}
          assert_equal "uncertain", produce(generation).fetch("outcome")
          assert_empty @workflow_uploads
          assert_equal 0, @context_owner.status(peer: @authority_peer).fetch("active_operations")
          @wrong_candidate_response = true
          @candidate["observation"] = {"outcome" => "consumed", "native_reference" => @observation.fetch("native_reference"),
            "server_process_binding" => @runtime.fetch("runtime_process_binding"), "endpoint_reference_sha256" => @runtime.fetch("endpoint_reference_sha256")}
          assert_raises(AttemptErrors::EvidenceUnavailable) { produce(generation) }
          assert_empty @workflow_uploads
          assert_equal 1, @context_owner.status(peer: @authority_peer).fetch("active_operations")
          assert_equal 0, events.count { |event| event["type"] == "native_observation" }
        end
      end

      def test_observation_routes_import_fetch_restart_and_deduplicate_exact_canonical_bytes
        fixture do
          prepare_observation
          before_record = File.binread(File.join(@context.fetch("deliveries_dir"), "event.json"))
          original_generation = @journal.authority_generation(events)
          imported = import_observation(generation: original_generation)
          evidence_id = imported.fetch(:data).fetch("evidence_id")
          assert_match(/\A[0-9a-f]{32}\z/, evidence_id)
          assert_equal 1, events.count { |event| event["type"] == "evidence_import" }
          assert_equal 1, events.count { |event| event["type"] == "native_observation" }
          assert_equal imported.fetch(:data).except("generation", "journal_commit"), import_observation(id: "same-new-id").fetch(:data).except("generation", "journal_commit")
          assert_equal 1, events.count { |event| event["type"] == "evidence_import" }
          replay = import_observation(generation: original_generation)
          assert replay.fetch(:replayed)
          restart
          fetched = fetch_observation(evidence_id)
          assert_equal [JSON.generate(@observation)], fetched.fetch(:transfer_parts)
          assert_equal "observer", fetched.dig(:data, "descriptor", "role")
          assert_equal @observer.fetch("uid"), fetched.dig(:data, "descriptor", "peer_uid")
          assert_equal @journal.ref_value, fetched.dig(:data, "journal_commit")
          assert fetched.dig(:data, "eligible")
          assert_equal before_record, File.binread(File.join(@context.fetch("deliveries_dir"), "event.json"))
          assert_equal 1, @native_calls
          assert_equal 0, @context_owner.status(peer: @authority_peer).fetch("active_operations")
        end
      end

      def test_exact_mapped_signer_settlement_replays_same_proof_and_keeps_observation_eligible
        fixture do
          prepare_observation
          imported = import_observation
          generation = @journal.authority_generation(events)
          selected = @params.merge("expected_generation" => generation)
          assert_raises(AttemptErrors::UnauthorizedIdentity) { reconcile(params: selected, peer: @signer.merge("groups" => [13001]), role: :signer, id: "wrong-signer") }
          accepted = reconcile(params: selected, peer: @signer, role: :signer, id: "signer-settle")
          assert_equal "completed", accepted.dig(:data, "state")
          retry_reply = reconcile(params: selected, peer: @signer, role: :signer, id: "signer-settle")
          assert retry_reply.fetch(:replayed)
          assert_equal accepted.fetch(:data), retry_reply.fetch(:data)
          assert_equal 1, events.count { |event| event["type"] == "inbox_reconciliation" }
          fetched = fetch_observation(imported.dig(:data, "evidence_id"))
          assert fetched.dig(:data, "eligible"), "completed same claim may verify and replay exact signed proof"
          assert_equal [JSON.generate(@observation)], fetched.fetch(:transfer_parts)
          assert_equal 1, @native_calls
        end
      end

      def test_observation_routes_refuse_foreign_peer_private_correlation_conflicts_and_tampered_blob
        fixture do
          prepare_observation
          assert_raises(AttemptErrors::UnauthorizedIdentity) { import_observation(peer: @peer, role: :supervisor) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { import_observation(peer: @observer.merge("groups" => [13001])) }
          changes = [{"claim_generation" => 2}, {"runtime_process_binding" => process(94, 13001)}, {"payload_sha256" => "f" * 64},
            {"source_excerpt" => {"prompt" => "private body"}}, {"outcome" => "superseded"}, {"event_id" => "foreign"}]
          changes.each do |change|
            assert_raises(AttemptErrors::EvidenceUnavailable) { import_observation(bytes: JSON.generate(@observation.merge(change))) }
          end
          bad = Marshal.load(Marshal.dump(@observation)); bad["native_reference"]["client_user_message_id"] = "ace-" + "f" * 32
          assert_raises(AttemptErrors::EvidenceUnavailable) { import_observation(bytes: JSON.generate(bad)) }
          imported = import_observation
          id = imported.dig(:data, "evidence_id")
          different = Marshal.load(Marshal.dump(@observation)); different["native_reference"]["item_id"] = "item-2"
          source = JSON.generate(different.fetch("source_excerpt")); different["source_sha256"] = Digest::SHA256.hexdigest(source); different["source_bytes"] = source.bytesize
          assert_raises(AttemptErrors::Conflict) { import_observation(id: "conflicting", bytes: JSON.generate(different)) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { fetch_observation(id, peer: @observer.merge("uid" => 13011), role: :observer) }
          assert_raises(AttemptErrors::NotFound) { fetch_observation("f" * 32) }
          @journal.stub(:blob, "corrupt") { assert_raises(AttemptErrors::EvidenceUnavailable) { fetch_observation(id) } }
          assert_equal 1, events.count { |event| event["type"] == "native_observation" }
        end
      end

    end
  end
end
