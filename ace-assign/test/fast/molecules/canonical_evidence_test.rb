# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Assign
    class CanonicalEvidenceTest < AceAssignTestCase
      def params
        {kind: "service", project_id: "fixture", assignment_id: "assignment-1", attempt_id: "attempt-1",
         peer_uid: Process.uid, binding: {"request_id" => "request-1"}, request_id_or_event_id: "request-1",
         generation: 1, admitted_after_event_digest: "a" * 64, artifacts: ["attestation"]}
      end

      def importer
        Molecules::CanonicalEvidence.new(journal: nil)
      end

      def test_artifact_count_individual_and_total_bounds_refuse_before_import
        [[], ["a"] * 17, ["a" * (64 * 1024 + 1)], ["a" * (64 * 1024)] * 4 + ["a"]].each do |artifacts|
          assert_raises(ArgumentError) { importer.import_plan(**params.merge(artifacts: artifacts)) }
        end
        admitted = importer.import_plan(**params.merge(artifacts: ["a" * (64 * 1024)] * 4))
        assert_equal 4, admitted.fetch(:references).length
        assert_equal 256 * 1024, admitted.fetch(:blobs).values.sum(&:bytesize)
      end

      def test_provenance_identity_binding_and_predecessor_are_required
        [{peer_uid: -1}, {peer_uid: "504"}, {generation: -1}, {binding: nil},
         {project_id: "../fixture"}, {admitted_after_event_digest: nil}, {kind: "worker"}].each do |changes|
          assert_raises(ArgumentError) { importer.import_plan(**params.merge(changes)) }
        end
      end

      def test_owner_generated_artifact_ids_and_no_effect_references
        plan = importer.import_plan(**params.merge(binding: {"no_effect_challenge" => "challenge-1"}))
        descriptor = plan.fetch(:events).first.fetch(:payload)
        assert_equal Process.uid, descriptor.fetch("peer_uid")
        assert_equal "executor", descriptor.fetch("role")
        assert_equal 1, descriptor.fetch("version")
        assert_match(/\A[a-f0-9]{32}-no-effect\z/, descriptor.fetch("artifact_id"))
        assert_equal Digest::SHA256.hexdigest("attestation"), descriptor.fetch("sha256")
        assert_equal "evidence/imports/#{descriptor.fetch('artifact_id')}", plan.fetch(:references).first.fetch("ref")
      end

      def pending_fixture
        before = Models::EvidenceEvent.build(type: "authority_mutation", attempt_id: "attempt-1",
          payload: {"operation" => "import-fixture"}, previous_digest: nil)
        input = params.merge(admitted_after_event_digest: before.fetch("digest"))
        plan = importer.import_plan(**input)
        previous = before.fetch("digest")
        events = plan.fetch(:events).map do |entry|
          event = Models::EvidenceEvent.build(type: entry.fetch(:type), attempt_id: "attempt-1",
            payload: entry.fetch(:payload), previous_digest: previous)
          previous = event.fetch("digest")
          event
        end
        context = input.reject { |key, _value| %i[admitted_after_event_digest artifacts].include?(key) }
        [before, events, plan, context]
      end

      def test_pending_import_uses_same_chain_provenance_and_byte_validator
        before, events, plan, context = pending_fixture
        bytes = importer.read_pending(plan.fetch(:references).first, current_events: [before], pending_events: events,
          blobs: plan.fetch(:blobs), commit: nil, **context)
        assert_equal "attestation", bytes
        [{peer_uid: Process.uid + 1}, {generation: 2}, {binding: {"request_id" => "different"}}].each do |changed|
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            importer.read_pending(plan.fetch(:references).first, current_events: [before], pending_events: events,
              blobs: plan.fetch(:blobs), commit: nil, **context.merge(changed))
          end
        end
      end

      def test_pending_corrupted_bytes_or_chain_cannot_pass_precommit_validation
        before, events, plan, context = pending_fixture
        reference = plan.fetch(:references).first
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          importer.read_pending(reference, current_events: [before], pending_events: events,
            blobs: {reference.fetch("ref") => "changed"}, commit: nil, **context)
        end
        changed = Marshal.load(Marshal.dump(events))
        changed.first["payload"]["peer_uid"] = Process.uid + 1
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          importer.read_pending(reference, current_events: [before], pending_events: changed,
            blobs: plan.fetch(:blobs), commit: nil, **context)
        end
      end
    end
  end
end
