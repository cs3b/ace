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
    end
  end
end
