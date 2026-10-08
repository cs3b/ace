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
