# frozen_string_literal: true
require_relative "../atoms/evidence_digest"

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        # One authenticated immutable prefix; never the latest registration.
        def original_prepared_registration!(journal:, params:, commit:)
          original_prepared_registration_for_phase!(journal: journal, params: params, commit: commit, phase: :issued) do |map, state|
            yield(map, state) if block_given?
          end
        end

        private

        def original_bound_prepared_registration!(journal:, params:, commit:)
          original_prepared_registration_for_phase!(journal: journal, params: params, commit: commit, phase: :bound)
        end

        def original_prepared_registration_for_phase!(journal:, params:, commit:, phase:)
          inventory = journal.canonical_event_inventory!(commit: commit)
          raise AttemptErrors::EvidenceUnavailable, "prepared canonical snapshot differs" unless inventory.fetch("commit") == commit
          assignment = params.fetch("assignment_id")
          events = inventory.fetch("events").fetch(assignment)
          chain = events.select { |event| event["attempt_id"] == params.fetch("attempt_id") }
          state = origin(chain, **params.slice("assignment_id", "attempt_id", "mapping_id").transform_keys(&:to_sym))
          reserves = chain.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "reserve_attempt" }
          releases = chain.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "release_launch" }
          provisioning = chain.select { |event| event["type"] == "scope_provisioning" }
          admitted_phase = if phase == :issued
            releases.one? && releases.first.dig("payload", "data", "phase") == "issued"
          else
            releases.empty? && state.fetch("phase") == "bound"
          end
          unless reserves.one? && admitted_phase && provisioning.one? &&
              !terminal_events?(chain) && !chain.any? { |event| %w[scope_sealed input_inhibited attempt_stopped].include?(event["type"]) }
            raise AttemptErrors::EvidenceUnavailable, "original prepared attempt is not #{phase} and open"
          end
          identity = provisioning.first.fetch("payload")
          sha = identity.fetch("descriptor_sha256")
          selected = if @deployment.artifact_reference.fetch("sha256") == sha
            @deployment
          else
            raise AttemptErrors::EvidenceUnavailable, "original prepared deployment is unavailable" unless @deployment_history
            @deployment_history.descriptor!(sha256: sha)
          end
          map = selected.mapping(params.fetch("mapping_id"))
          original_project = selected.project(map.fetch("project_id"))
          unless identity.fetch("deployment_digest") == Digest::SHA256.hexdigest(JSON.generate(canonical(map))) &&
              identity.fetch("slot_id") == map.fetch("execution_scope").fetch("slot_id") && state.fetch("project_id") == map.fetch("project_id") &&
              selected.project(map.fetch("project_id")).values_at("journal_repository", "evidence_git_ref", "evidence_checkout_root") ==
                [journal.repo_root, journal.ref, journal.checkout_root]
            raise AttemptErrors::EvidenceUnavailable, "original prepared deployment association differs"
          end
          lineage = Molecules::ExecutionScopeLineage.new(events: chain, project_id: state.fetch("project_id"),
            assignment_id: assignment, attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
          unless lineage.require_launch_bound! == state.fetch("process_binding")
            raise AttemptErrors::EvidenceUnavailable, "original prepared child binding differs"
          end
          original = original_prompt_record!(chain, state, params: params)
          # Authenticate the actual original worker/descendant before reading artifacts.
          yield(map, state) if block_given?
          introductions = inventory.fetch("introductions").fetch(assignment)
          reservation_commit = introductions.fetch(reserves.first.fetch("digest"))
          registration = definition(journal, assignment, commit: reservation_commit)
          original_events = journal.read_events(assignment, commit: reservation_commit)
          authenticate_inventory_registration!(journal, assignment, original_events, registration, params.fetch("mapping_id"), map, reservation_commit, introductions)
          registered = original_events.find { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "register_assignment" && event.dig("payload", "data") == registration }
          registration_commit = introductions.fetch(registered.fetch("digest"))
          TaskContextEntry.validate!(registration.fetch("task_context_entry"))
          unless registration.fetch("task_context_entry") == map.fetch("task_context_entry")
            raise AttemptErrors::EvidenceUnavailable, "original prepared task context entry differs"
          end
          prepared = registration.fetch("prepared_work")
          unless prepared.fetch("scope") == state.fetch("scope") && prepared.fetch("task_id") == state.fetch("task_id")
            raise AttemptErrors::EvidenceUnavailable, "original prepared selection differs"
          end
          bytes = journal.bounded_blob(registration.fetch("definition_ref"), commit: registration_commit, max_bytes: PreparedWork::MAX_MANIFEST)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, PreparedWork::MAX_MANIFEST) &&
              Digest::SHA256.hexdigest(bytes) == registration.fetch("definition_digest") && JSON.parse(bytes).fetch("prepared_work") == prepared
            raise AttemptErrors::EvidenceUnavailable, "original prepared definition differs"
          end
          projection = immutable_maintenance_projection(registration: registration, registration_commit: registration_commit, state: state, map: map, events: chain,
            original_worker_scratch_root: original_project.fetch("peer_credentials").fetch(map.fetch("worker_uid").to_s).fetch("scratch_root"),
            original_binding_digest: original.fetch("binding_digest"), commit: commit)
          pin = compact_prepared_input(projection)
          if phase == :issued
            unless Atoms::EvidenceDigest.digest(releases.first.dig("payload", "data", "prepared_input")) == Atoms::EvidenceDigest.digest(pin)
              raise AttemptErrors::EvidenceUnavailable, "accepted prepared release differs"
            end
          else
            bundle = journal.bounded_blob(registration.fetch("prepared_bundle_ref"), commit: registration_commit, max_bytes: CandidateTransfer::MAX_BYTES)
            unless bundle.is_a?(String) && bundle.bytesize == registration.fetch("prepared_bundle_bytes") &&
                bundle.bytesize.between?(1, CandidateTransfer::MAX_BYTES) && Digest::SHA256.hexdigest(bundle) == registration.fetch("prepared_bundle_sha256")
              raise AttemptErrors::EvidenceUnavailable, "original prepared bundle differs"
            end
          end
          projection
        rescue KeyError, TypeError, NoMethodError, JSON::ParserError
          raise AttemptErrors::EvidenceUnavailable, "original prepared registration is unavailable"
        end

        def compact_prepared_input(projection)
          registration = projection.fetch(:registration)
          immutable_maintenance_projection(
            "registration_generation" => registration.fetch("generation"),
            "registration_commit" => projection.fetch(:registration_commit),
            "definition_digest" => registration.fetch("definition_digest"),
            "original_binding_digest" => projection.fetch(:original_binding_digest),
            "prepared_work" => registration.fetch("prepared_work"),
            "worker_entry" => Ace::Runtime::Molecules::ProtectedWorkerEntry.validate!(projection.fetch(:map).fetch("worker_entry")),
            "bundle_ref" => registration.fetch("prepared_bundle_ref"),
            "bundle_bytes" => registration.fetch("prepared_bundle_bytes"),
            "bundle_sha256" => registration.fetch("prepared_bundle_sha256"))
        end
      end
    end
  end
end
