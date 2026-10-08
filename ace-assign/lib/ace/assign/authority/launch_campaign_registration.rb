# frozen_string_literal: true
require "ace/review/organisms/campaign_manager"
require_relative "campaign_consumer_policy"

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        # Called by the terminal owner at its selected CAS prefix. Discover
        # children from canonical registration; no caller list can omit one.
        def campaign_children_settled!(journal:, commit:, params:, map:)
          parent = preview_attempt_definition!(journal: journal, commit: commit, params: params, map: map)
          return true unless parent.review_campaign
          inventory = journal.canonical_event_inventory!(commit: commit)
          inventory.fetch("events").each do |assignment, events|
            next if assignment == params.fetch("assignment_id")
            registrations = events.select { |event| event.dig("payload", "operation") == "register_assignment" }
            next if registrations.empty?
            registration = registrations.last.fetch("payload").fetch("data")
            child = inventory_definition!(journal, commit,
              {selector: {"assignment_id" => assignment, "attempt_id" => nil}, registration: registration})
            execution = child.campaign_execution
            next unless execution && execution.values_at("parent_assignment_id", "parent_attempt_id") ==
              params.values_at("assignment_id", "attempt_id")
            original = control_original_descriptor!(registration.fetch("lifecycle_control"))
            mapping_id = registration.fetch("mapping_id")
            child_map = original.mapping(mapping_id)
            authenticate_inventory_registration!(journal, assignment, events, registration, mapping_id,
              child_map, commit, inventory.fetch("introductions").fetch(assignment))
            rows = inventory_index!(journal, commit, mapping_id, child_map).select { |entry|
              entry.fetch(:selector).fetch("assignment_id") == assignment }
            unless !rows.empty? && rows.all? { |entry|
                row = inventory_row!(journal, commit, entry)
                %w[succeeded failed stopped].include?(row["canonical_state"]) &&
                  row["terminal_event_id"] && row["reservation_release_event_id"] }
              raise AttemptErrors::Conflict, "campaign parent has an unsettled registered child"
            end
          end
          true
        rescue KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "campaign child completion provenance is unavailable"
        end

        private

        # Resolve both immutable canonical owners before entering exclusions.
        def campaign_child_context!(params, context, map, journal)
          value = if params.key?("definition_bytes")
            JSON.parse(params.fetch("definition_bytes"))
          elsif context.fetch(:registration)
            registration = context.fetch(:registration)
            bytes = journal.blob(registration.fetch("definition_ref"), commit: context.fetch(:commit))
            unless bytes.is_a?(String) && bytes.bytesize <= 32_768 &&
                Digest::SHA256.hexdigest(bytes) == registration.fetch("definition_digest")
              raise AttemptErrors::EvidenceUnavailable, "campaign definition content differs"
            end
            decoded = JSON.parse(bytes, create_additions: false, max_nesting: 32, allow_duplicate_key: false, allow_comments: false)
            return context unless decoded.is_a?(Hash) && decoded.key?("campaign_execution")
            inventory_definition!(journal, context.fetch(:commit),
              {selector: {"assignment_id" => params.fetch("assignment_id"), "attempt_id" => params["attempt_id"]},
                registration: registration}).to_h
          else
            return context
          end
          return context unless value.key?("campaign_execution")
          execution = value.fetch("campaign_execution")
          unless execution.is_a?(Hash) && execution.keys.sort == CampaignExecution::FIELDS
            raise ArgumentError, "campaign execution fields differ"
          end
          parent_id, attempt = execution.values_at("parent_assignment_id", "parent_attempt_id")
          token!(parent_id); token!(attempt)
          raise ArgumentError, "campaign child cannot be its own parent" if parent_id == params.fetch("assignment_id")
          inventory = journal.canonical_event_inventory!(commit: context.fetch(:commit))
          reserves = inventory.fetch("events").fetch(parent_id).select { |event|
            event["attempt_id"] == attempt && event.dig("payload", "operation") == "reserve_attempt" }
          raise AttemptErrors::EvidenceUnavailable, "campaign parent reservation differs" unless reserves.one?
          parent_mapping = reserves.first.fetch("payload").fetch("data").fetch("mapping_id")
          parent_params = {"assignment_id" => parent_id, "attempt_id" => attempt, "mapping_id" => parent_mapping,
            "scope" => execution.fetch("parent_scope"), "base" => execution.fetch("base"), "head" => execution.fetch("head"),
            "candidate_generation" => execution.fetch("parent_candidate_generation")}.freeze
          parent_map = @deployment.mapping(parent_mapping)
          parent_context = control_registration_context!(parent_params, parent_map, journal, commit: context.fetch(:commit))
          original_map = parent_context.fetch(:map)
          parent = preview_attempt_definition!(journal: journal, commit: context.fetch(:commit), params: parent_params, map: original_map)
          selected = CampaignExecution.validate_parent!(parent.review_campaign)
          unless value["parent"] == parent_id && value["task_id"] == parent.task_id && value["project_id"] == parent.project_id &&
              parent.project_id == map.fetch("project_id") &&
              parent_context.fetch(:selection).fetch("root_identity") == context.fetch(:selection).fetch("root_identity") &&
              original_map.fetch("authority_id") == context.fetch(:map).fetch("authority_id")
            raise AttemptErrors::EvidenceUnavailable, "campaign parent task or control owner differs"
          end
          CampaignExecution.validate!(execution, parent: parent_id, policy: selected.fetch("policy"))
          context.merge(campaign: {params: parent_params, map: parent_map, context: parent_context,
            definition: parent, selected: selected, execution: execution, child_assignment: params.fetch("assignment_id")}.freeze).freeze
        rescue KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "campaign parent canonical registration is unavailable"
        end

        def recheck_campaign_parent!(context, journal, commit: journal.ref_value)
          campaign = context.fetch(:campaign)
          parent = campaign.fetch(:context)
          recheck_control_registration!(parent, campaign.fetch(:params), campaign.fetch(:map), journal,
            commit: commit, held_exclusion: context.fetch(:exclusion))
          unless @result_owner&.respond_to?(:campaign_parent_candidate!)
            raise AttemptErrors::EvidenceUnavailable, "campaign parent candidate owner is unavailable"
          end
          @result_owner.campaign_parent_candidate!(journal: journal, commit: commit,
            params: campaign.fetch(:params), map: parent.fetch(:map))
          true
        end

        # Called inside the existing lifecycle exclusions and authority mutex,
        # before entering the journal mutation; the store lock spans CAS retries.
        def with_parent_campaign_registration(params, context, replay:)
          # A stored mutation remains a historical observation after supersession.
          # The journal still verifies its operation and exact parameters below.
          return yield if replay
          if context[:campaign]
            return with_child_campaign_registration(params, context) { |guard| yield guard }
          end
          return yield unless params.key?("definition_bytes")
          definition = JSON.parse(params.fetch("definition_bytes"))
          return yield unless definition.key?("review_campaign")
          selected = CampaignExecution.validate_parent!(definition.fetch("review_campaign"))
          manager = campaign_manager_for!(context)
          manager.with_campaign_registration!(selected.fetch("campaign_id"), subject: selected.fetch("subject"),
            contract_identity: selected.fetch("contract_identity"), policy: selected.fetch("policy")) { yield }
        rescue KeyError, TypeError, JSON::ParserError, Ace::Review::Atoms::CampaignContract::Invalid
          raise AttemptErrors::EvidenceUnavailable, "registered parent campaign is unavailable"
        end

        def campaign_manager_for!(context, **evidence)
          descriptor = context.fetch(:descriptor)
          map = context.fetch(:map)
          project = descriptor.project(map.fetch("project_id"))
          service = descriptor.authority(map.fetch("authority_id"))
          %w[campaign_repository campaign_store_root].each do |key|
            path = project.fetch(key)
            wire.root_path!(path, directory: true, owner: service.fetch("uid"))
            unless (File.stat(path).mode & 0o077).zero?
              raise AttemptErrors::EvidenceUnavailable, "campaign owner root must remain private"
            end
          end
          store = Ace::Review::Molecules::CampaignStore.new(root: project.fetch("campaign_store_root"))
          Ace::Review::Organisms::CampaignManager.new(repo_root: project.fetch("campaign_repository"), store: store, **evidence)
        end

        def with_child_campaign_registration(params, context)
          campaign = context.fetch(:campaign)
          recheck_campaign_parent!(context, journals.fetch(context.fetch(:map).fetch("project_id")))
          manager = campaign_manager_for!(campaign.fetch(:context))
          deployment = @deployment
          descriptor_sha = protected_descriptor_sha256!
          policy_ref = deployment.project(context.fetch(:map).fetch("project_id")).fetch("campaign_policy")
          CampaignConsumerPolicy.new.with(policy_ref) do |profiles, artifacts|
            manager.with_execution_round!(campaign.fetch(:execution).fetch("campaign_id"),
              round_id: campaign.fetch(:execution).fetch("round_id"), consumer_profiles: profiles) do |round, round_guard|
              selected = campaign.fetch(:selected)
              unless round.slice("campaign_id", "subject", "contract_identity", "policy") == selected.reject { |key, _| key == "version" }
                raise AttemptErrors::EvidenceUnavailable, "campaign child differs from original parent contract"
              end
              CampaignExecution.validate_round!(campaign.fetch(:execution), parent: campaign.fetch(:definition).id, round: round)
              guard = lambda do |journal, commit|
                unless @deployment.equal?(deployment) && protected_descriptor_sha256! == descriptor_sha
                  raise AttemptErrors::Conflict, "current campaign policy descriptor changed"
                end
                artifacts.verify_unchanged!
                round_guard.call
                recheck_campaign_parent!(context, journal, commit: commit)
                unique_campaign_child!(context, journal, commit) if params.key?("definition_bytes")
              end
              yield guard
            end
          end
        rescue KeyError, TypeError, Ace::Review::Atoms::CampaignContract::Invalid, Ace::Runtime::RuntimeUnavailableError
          raise AttemptErrors::EvidenceUnavailable, "campaign child pinned round is unavailable"
        end

        # One immutable phase definition, discovered from the existing canonical
        # registration owner. A caller-provided child list cannot omit a sibling.
        def unique_campaign_child!(context, journal, commit)
          selected = context.fetch(:campaign).fetch(:execution)
          fields = %w[parent_assignment_id parent_attempt_id parent_candidate_generation round_id phase]
          fields += case selected.fetch("phase")
          when "collection" then ["review_scope"]
          when "check" then ["check_name"]
          else []
          end
          inventory = journal.canonical_event_inventory!(commit: commit)
          inventory.fetch("events").each do |assignment, events|
            next if assignment == context.fetch(:campaign).fetch(:definition).id
            events.select { |event| event.dig("payload", "operation") == "register_assignment" }.each do |event|
              registration = event.fetch("payload").fetch("data")
              entry = {selector: {"assignment_id" => assignment, "attempt_id" => nil}, registration: registration}
              definition = inventory_definition!(journal, commit, entry)
              child = definition.campaign_execution
              next unless child && child.slice(*fields) == selected.slice(*fields)
              # Re-registration of this exact child is permitted; a distinct
              # assignment cannot replace the retained phase owner.
              current_assignment = context.fetch(:campaign).fetch(:child_assignment)
              next if assignment == current_assignment
              original = control_original_descriptor!(registration.fetch("lifecycle_control"))
              map_id = registration.fetch("mapping_id")
              authenticate_inventory_registration!(journal, assignment, events, registration, map_id,
                original.mapping(map_id), commit, inventory.fetch("introductions").fetch(assignment))
              raise AttemptErrors::Conflict, "campaign phase already has a registered child"
            end
          end
          true
        end
      end
    end
  end
end
