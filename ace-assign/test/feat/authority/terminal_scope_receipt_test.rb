# frozen_string_literal: true
require_relative "../../test_helper"
require_relative "../../support/endcap_result_owner_fixture"

module Ace
  module Assign
    class TerminalScopeReceiptTest < AceAssignTestCase
      include EndcapResultOwnerFixture
      def test_actual_terminal_owner_accepts_imported_result_and_shared_release_producer_binds_it
        fixture do
          result = submit.fetch(:data)
          events = @journal.read_events("assignment").select { |event| event["attempt_id"] == @attempt }
          submitted = events.find { |event| event["type"] == "result_submitted" }.fetch("payload")
          terminal_params = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}
          @launch.close_execution_scope!(params: terminal_params.merge("mutation_id" => "terminal-seal", "expected_generation" => generation),
            peer: @launcher, role: :launcher)
          proof = @launch.close_execution_scope!(params: terminal_params.merge("mutation_id" => "terminal-proof", "expected_generation" => generation),
            peer: @launcher, role: :launcher)
          binding = submitted.fetch("binding")
          canonical = Molecules::CanonicalEvidence.new(journal: @journal)
          reader = ->(_receipt, artifact) { canonical.read({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
            kind: "result", project_id: "project", assignment_id: "assignment", attempt_id: @attempt, peer_uid: 13001,
            binding: binding, request_id_or_event_id: binding.fetch("result_id"), generation: binding.fetch("candidate_generation")) }
          verifier = Molecules::ReceiptVerifier.new(artifact_reader: reader)
          coordinator = Organisms::AttemptCoordinator.new(cache_base: File.join(@root, "terminal-cache"),
            repo_root: @journal.repo_root, journal: @journal, verifier: verifier,
            lifecycle_exclusion: @launch.send(:exclusion_for, @map, @journal))
          receipt_path = File.join(@root, "terminal-receipt.json")
          File.write(receipt_path, JSON.generate(submitted.fetch("receipt")))
          identity = Molecules::ExecutionIdentityResolver::Identity.new(actor: "fixture-operator", role: "coordinator", runtime: "local")
          finished = coordinator.finish(attempt_id: @attempt, receipt_path: receipt_path, identity: identity)
          assert_equal "succeeded", finished.state
          terminal_events = @journal.read_events("assignment").select { |event| event["attempt_id"] == @attempt }
          lineage = Molecules::ExecutionScopeLineage.new(events: terminal_events, project_id: "project",
            assignment_id: "assignment", attempt_id: @attempt, mapping_id: "mapping")
          malformed = [
            terminal_events.reject { |event| event["type"] == "intent" },
            terminal_events.reject { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "reserve_attempt" },
            terminal_events.map { |event| event["type"] == "receipt_accepted" ? event.merge("payload" => []) : event }
          ]
          malformed.each do |records|
            previous = nil
            records = records.map do |event|
              rebuilt = Models::EvidenceEvent.build(type: event.fetch("type"), attempt_id: event.fetch("attempt_id"),
                payload: event.fetch("payload"), recorded_at: Time.parse(event.fetch("recorded_at")), previous_digest: previous)
              previous = rebuilt.fetch("digest")
              rebuilt
            end
            assert Models::EvidenceEvent.chain_valid?(records)
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              Molecules::TerminalScopeReceipt.verify!(events: records, lineage: lineage, journal: @journal,
                commit: @journal.ref_value, mapping: @map)
            end
          end
          release = @launch.release_scope_reservation!(params: terminal_params.merge("mutation_id" => "terminal-release", "expected_generation" => generation),
            peer: @launcher, role: :launcher)
          terminal = @journal.read_events("assignment").find { |event| event["type"] == "receipt_accepted" }
          assert_equal terminal.fetch("digest"), release.dig(:data, "terminal_event_id")
          assert_equal proof.dig(:data, "proof_id"), release.dig(:data, "proof_id")
          assert_equal result.fetch("receipt_digest"), terminal.dig("payload", "receipt", "digest")
          assert_equal "released", release.dig(:data, "reservation")
        end
      end

    end
  end
end
