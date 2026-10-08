# frozen_string_literal: true
require_relative "../molecules/protected_control_exclusion"
require_relative "campaign_execution"

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        private

        def control_registration_context!(params, map, journal, commit: journal.ref_value)
          assignment = params.fetch("assignment_id")
          mapping = params.fetch("mapping_id")
          inventory = if commit.nil?
            unless params.key?("definition_bytes") && journal.ref_value.nil?
              raise AttemptErrors::EvidenceUnavailable, "Original control canonical ref is unavailable"
            end
            # Existing first-registration bootstrap. The lower CAS initializes
            # and authenticates its seed prefix before accepting any event.
            {"commit" => nil, "events" => {}, "introductions" => {}}
          else
            journal.canonical_event_inventory!(commit: commit)
          end
          unless inventory.fetch("commit") == commit
            raise AttemptErrors::EvidenceUnavailable, "Control canonical snapshot differs"
          end
          events = inventory.fetch("events").fetch(assignment, [])
          introductions = inventory.fetch("introductions").fetch(assignment, {})
          registrations = events.select { |event| event["type"] == "authority_mutation" &&
            event.dig("payload", "operation") == "register_assignment" }
          first = registrations.first&.dig("payload", "data")
          registration = registrations.last&.dig("payload", "data")
          if params["attempt_id"]
            chain = events.select { |event| event["attempt_id"] == params.fetch("attempt_id") }
            reserves = chain.select { |event| event.dig("payload", "operation") == "reserve_attempt" }
            unless reserves.one? && reserves.first.dig("payload", "data", "mapping_id") == mapping
              raise AttemptErrors::EvidenceUnavailable, "Original control reservation is unavailable"
            end
            prefix = introductions.fetch(reserves.first.fetch("digest"))
            registration = definition(journal, assignment, commit: prefix)
          end
          unless registration || params.key?("definition_bytes")
            raise AttemptErrors::NotFound, "canonical assignment registration is missing"
          end
          selection = first&.fetch("lifecycle_control")
          selected = selection ? control_original_descriptor!(selection) : @deployment
          original_map = selected.mapping(mapping)
          project = selected.project(original_map.fetch("project_id"))
          unless original_map.fetch("project_id") == map.fetch("project_id") &&
              project.values_at("journal_repository", "evidence_git_ref", "evidence_checkout_root") ==
                [journal.repo_root, journal.ref, journal.checkout_root]
            raise AttemptErrors::EvidenceUnavailable, "Original control journal association differs"
          end
          control_owner_unchanged!(selected, original_map, map)
          if first
            authenticate_inventory_registration!(journal, assignment, events, first, mapping, original_map,
              commit, introductions)
            authenticate_inventory_registration!(journal, assignment, events, registration, mapping, original_map,
              commit, introductions) unless registration == first
            unless registrations.all? { |event| event.dig("payload", "data", "lifecycle_control") == selection }
              raise AttemptErrors::EvidenceUnavailable, "Assignment control owner was replaced"
            end
          end
          control = exclusion_for(original_map, journal, deployment: selected, selection: selection)
          actual_selection = control.selection!
          if actual_selection.fetch("descriptor_sha256") != selected.artifact_reference.fetch("sha256") ||
              selection && actual_selection != selection
            raise AttemptErrors::EvidenceUnavailable, "Original control root differs"
          end
          proposed = params.key?("definition_bytes") ? validated_registration_definition!(params, map) : nil
          tasks = [registration&.fetch("task_id"), proposed&.task_id].compact.uniq.sort
          tasks.each { |task| token!(task) }
          keys = tasks.map { |task| control.task_key(task) } + [control.assignment_key(assignment)]
          {commit: commit, registration: registration, descriptor: selected, map: original_map,
            selection: actual_selection, exclusion: control, keys: keys.freeze}.freeze
        rescue KeyError, TypeError, JSON::ParserError
          raise AttemptErrors::EvidenceUnavailable, "Original control registration is unavailable"
        end

        def control_original_descriptor!(selection)
          unless selection.is_a?(Hash) && selection.keys.sort == %w[descriptor_sha256 root_identity] &&
              selection["descriptor_sha256"].is_a?(String) && selection["descriptor_sha256"].match?(/\A[0-9a-f]{64}\z/)
            raise AttemptErrors::EvidenceUnavailable, "Original control selection is malformed"
          end
          sha = selection.fetch("descriptor_sha256")
          return @deployment if sha == protected_descriptor_sha256!
          unless @deployment_history
            raise AttemptErrors::EvidenceUnavailable, "Original control descriptor is unavailable"
          end
          @deployment_history.descriptor!(sha256: sha)
        end

        def control_owner_unchanged!(selected, original_map, current_map)
          old_authority = selected.authority(original_map.fetch("authority_id"))
          current_authority = @deployment.authority(current_map.fetch("authority_id"))
          slot_fields = %w[slot_id slice_unit service_unit root_directory runtime_directory network_namespace_path]
          unless original_map.fetch("authority_id") == current_map.fetch("authority_id") &&
              old_authority.values_at("state_root", "uid", "gid") == current_authority.values_at("state_root", "uid", "gid") &&
              original_map.fetch("execution_scope").slice(*slot_fields) == current_map.fetch("execution_scope").slice(*slot_fields)
            raise AttemptErrors::Conflict, "Control ownership changes require a fresh assignment"
          end
        end

        def recheck_control_registration!(context, params, map, journal, commit: journal.ref_value)
          fresh = if context.fetch(:commit) == commit
            context
          else
            control_registration_context!(params, map, journal, commit: commit)
          end
          unless fresh.fetch(:registration) == context.fetch(:registration) &&
              fresh.fetch(:selection) == context.fetch(:selection) && fresh.fetch(:keys) == context.fetch(:keys) &&
              journal.ref_value == commit && context.fetch(:exclusion).selection! == context.fetch(:selection)
            raise AttemptErrors::Conflict, "Control registration changed while entering exclusion"
          end
          context.fetch(:exclusion).verify_unchanged!
          true
        end

        def validated_registration_definition!(params, map)
          bytes = params.fetch("definition_bytes")
          unless bytes.is_a?(String) && bytes.bytesize <= 32_768 && params["definition_digest"].is_a?(String) &&
              Digest::SHA256.hexdigest(bytes) == params["definition_digest"]
            raise ArgumentError, "invalid assignment definition digest or size"
          end
          value = JSON.parse(bytes)
          allowed = %w[session_id name description created_at updated_at source_config parent task_id project_id prepared_work review_campaign]
          unless value.is_a?(Hash) && (value.keys - allowed).empty? &&
              %w[session_id name created_at source_config task_id project_id].all? { |key| value[key].is_a?(String) && !value[key].empty? } &&
              value["session_id"] == params["assignment_id"] && value["project_id"] == map["project_id"]
            raise ArgumentError, "invalid managed assignment definition"
          end
          CampaignExecution.validate_parent!(value.fetch("review_campaign")) if value.key?("review_campaign")
          assignment = Models::Assignment.from_h(value)
          raise ArgumentError, "definition is not managed" unless assignment.managed?
          token!(assignment.task_id)
          assignment
        end
      end
    end
  end
end
