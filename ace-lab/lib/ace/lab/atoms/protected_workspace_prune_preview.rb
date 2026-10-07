# frozen_string_literal: true

require_relative "protected_workspace_prune_input"
require "ace/assign/molecules/execution_scope_lineage"
require "ace/assign/atoms/evidence_digest"

module Ace
  module Lab
    module Atoms
      # Closed transport data only; canonical and physical owners must
      # independently authenticate these selectors before any effect.
      module ProtectedWorkspacePrunePreview
        Input = ProtectedWorkspacePruneInput
        CONTEXT = %w[journal_commit maintenance head candidate_generation worker_process_binding caller_process_binding].freeze
        RESULT = %w[schema kind intent_digest publication maintenance maintenance_context target preservation inventory_sha256 file_count total_bytes].freeze
        module_function

        def intent!(value)
          Input.object!(value, %w[schema maintenance target publication destinations])
          Input.reject! unless value["schema"] == "ace.protected-workspace-prune-preview/v1"
          Input.association!(value.fetch("maintenance"))
          target = value.fetch("target")
          Input.object!(target, Input::ASSOCIATION + %w[resource descriptor_sha256 binding_event_digest release_event_digest journal_commit])
          Input::ASSOCIATION.each { |key| Input.token!(target.fetch(key)) }
          %w[descriptor_sha256 binding_event_digest release_event_digest].each { |key| Input.digest!(target.fetch(key)) }
          Input.commit!(target.fetch("journal_commit"))
          expected = "workspace:#{target.fetch('project_id')}:#{target.fetch('mapping_id')}:#{target.fetch('assignment_id')}"
          Input.reject! unless expected.bytesize <= 256 && target["resource"] == expected
          publication = Input.object!(value.fetch("publication"), %w[descriptor_sha256 installation_ref])
          Input.digest!(publication.fetch("descriptor_sha256"))
          Input.reference!(publication.fetch("installation_ref"))
          # Reuse the existing exact destination/ref owner, without accepting
          # or manufacturing a preservation authority assertion.
          destinations!(value.fetch("destinations"))
          Input.reject! if JSON.generate(value).bytesize > Input::MAX_BYTES
          Input.freeze_value(value)
        end

        def destinations!(destinations)
          Input.reject! unless destinations.is_a?(Array) && destinations.length <= 64
          ids = destinations.map do |entry|
            Input.object!(entry, %w[repository_id ref head])
            Input.token!(entry.fetch("repository_id")); Input.ref!(entry.fetch("ref")); Input.commit!(entry.fetch("head"))
            entry.values_at("repository_id", "ref", "head")
          end
          Input.reject! unless ids == ids.sort && ids == ids.uniq
        end

        def context!(value)
          Input.object!(value, CONTEXT)
          Input.commit!(value.fetch("journal_commit"))
          Input.association!(value.fetch("maintenance"))
          Input.commit!(value.fetch("head"))
          Input.reject! unless value["candidate_generation"].is_a?(Integer) && value["candidate_generation"].positive?
          original = value.fetch("worker_process_binding")
          birth = original.is_a?(Hash) && original["started_at"]
          boot = birth.is_a?(String) && birth.match(/\Alinux:([0-9a-f-]{36}):[0-9]+\z/)&.captures&.first
          %w[worker_process_binding caller_process_binding].each do |key|
            Ace::Assign::Molecules::ExecutionScopeLineage.validate_process_identity!(value.fetch(key), boot_id: boot)
          end
          Input.reject! if JSON.generate(value).bytesize > 16_384
          Input.freeze_value(value)
        end

        def result!(value, intent:, context:)
          Input.object!(value, RESULT)
          Input.reject! unless value.values_at("schema", "kind") == ["ace.protected-workspace-prune-preview-result/v1", "preview"]
          Input.reject! unless value["intent_digest"] == Ace::Assign::Atoms::EvidenceDigest.digest(intent) &&
            value["maintenance_context"] == context && value["maintenance"] == intent["maintenance"] &&
            value["publication"] == intent["publication"] && value.fetch("target").except("artifact_digest") == intent["target"]
          input = {"schema" => "ace.protected-workspace-prune/v1"}.merge(value.slice("maintenance", "target", "publication", "preservation"))
          Input.parse(JSON.generate(input))
          Input.digest!(value.fetch("inventory_sha256"))
          Input.reject! unless value["inventory_sha256"] == value.dig("preservation", "manifest_sha256")
          Input.reject! unless value["file_count"].is_a?(Integer) && value["file_count"].between?(0, 4096) &&
            value["total_bytes"].is_a?(Integer) && value["total_bytes"].between?(0, 256 * 1024 * 1024)
          Input.reject! unless value.dig("preservation", "destinations") == intent["destinations"] &&
            value.dig("target", "artifact_digest") == Ace::Assign::Atoms::EvidenceDigest.digest(
              "target" => intent.fetch("target"), "preservation" => value.fetch("preservation"))
          Input.reject! if JSON.generate(value).bytesize > 16_384
          Input.freeze_value(value)
        end
      end
    end
  end
end
