# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class Endcap

        def prepared_fetch?(request)
          request["operation"] == "evidence_fetch" && request.dig("params", "kind") == "prepared_work"
        end

        def dispatch_prepared_fetch(request:, peer:, role:, body: true)
          params = request.fetch("params")
          unless request.fetch("mutation_id").nil? && params.is_a?(Hash) && params.keys.sort == PARAMETERS.fetch("evidence_fetch").sort &&
              params.values_at("kind", "purpose_id", "artifact_id") == %w[prepared_work original_prepared_work prepared_bundle]
            raise ArgumentError, "prepared fetch envelope differs"
          end
          %w[mapping_id assignment_id attempt_id].each { |key| result_id!(params.fetch(key)) }
          map = @deployment.mapping(params.fetch("mapping_id"))
          raise AttemptErrors::UnauthorizedIdentity, "prepared project differs" unless map.fetch("project_id") == request.fetch("project_id")
          raise AttemptErrors::UnauthorizedIdentity, "prepared fetch requires original worker" unless role == :worker
          @kernel.live!(peer)
          service_policy!.visible!(project: map.fetch("project_id"), uid: peer.fetch("uid"))
          journal = @launch.send(:journal_for, map)
          protected_journal!(journal)
          commit = journal.ref_value
          selected = @launch.original_prepared_registration!(journal: journal, params: params, commit: commit) do |original_map, state|
            unless peer.values_at("uid", "gid", "groups") == original_map.values_at("worker_uid", "worker_gid", "worker_groups")
              raise AttemptErrors::UnauthorizedIdentity, "prepared worker principal differs"
            end
            binding = state.fetch("process_binding")
            @kernel.live!(binding.fetch("process_identity"))
            @kernel.live!(binding.fetch("native_origin").fetch("server_identity"))
            worker_or_launcher!(peer, role, original_map, state)
          end
          original_map = selected.fetch(:map)
          return true unless body
          registration = selected.fetch(:registration)
          reference = registration.fetch("prepared_work")
          bytes = journal.bounded_blob(registration.fetch("prepared_bundle_ref"), commit: selected.fetch(:registration_commit), max_bytes: CandidateTransfer::MAX_BYTES)
          unless bytes.is_a?(String) && bytes.bytesize == registration.fetch("prepared_bundle_bytes") &&
              bytes.bytesize.between?(1, CandidateTransfer::MAX_BYTES) && Digest::SHA256.hexdigest(bytes) == registration.fetch("prepared_bundle_sha256")
            raise AttemptErrors::EvidenceUnavailable, "original prepared bundle differs"
          end
          descriptor = reference.slice("task_id", "scope", "selection_sha256", "prepared_head", "prepared_tree", "manifest_bytes", "manifest_sha256").merge(
            params.slice("mapping_id", "assignment_id", "attempt_id"), "version" => 1, "kind" => "prepared_work", "purpose" => "original_prepared_work", "artifact" => "prepared_bundle",
            "project_id" => original_map.fetch("project_id"), "definition_digest" => registration.fetch("definition_digest"),
            "registration_generation" => registration.fetch("generation"), "registration_commit" => selected.fetch(:registration_commit),
            "original_binding_digest" => selected.fetch(:original_binding_digest), "ref" => registration.fetch("prepared_bundle_ref"), "bytes" => bytes.bytesize,
            "sha256" => registration.fetch("prepared_bundle_sha256"))
          {data: {"descriptor" => descriptor, "generation" => journal.authority_generation(selected.fetch(:events)), "journal_commit" => commit}, replayed: false, transfer_parts: [bytes]}
        rescue KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "original prepared input is unavailable"
        end
      end
    end
  end
end
