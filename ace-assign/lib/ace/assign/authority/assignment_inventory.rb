# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        # Fixed source readers reuse the complete canonical inventory and its
        # original registration/definition proof; this is never a live grant.
        def preview_attempt_events!(journal:, commit:, params:, map:)
          preview_attempt_entry!(journal: journal, commit: commit, params: params, map: map).fetch(:events)
        end

        def preview_attempt_definition!(journal:, commit:, params:, map:)
          entry = preview_attempt_entry!(journal: journal, commit: commit, params: params, map: map)
          inventory_definition!(journal, commit, entry)
        end

        private

        def preview_attempt_entry!(journal:, commit:, params:, map:)
          entries = inventory_index!(journal, commit, params.fetch("mapping_id"), map).select do |entry|
            entry.fetch(:selector) == params.slice("assignment_id", "attempt_id")
          end
          raise AttemptErrors::EvidenceUnavailable, "preview original registration is unavailable or ambiguous" unless entries.one?
          entry = entries.first
          inventory_definition!(journal, commit, entry)
          entry
        end

        # Discovery authenticates the current mapped principal, then reads one
        # immutable canonical prefix. It neither pins the original launcher nor
        # grants permission to mutate that launch.
        def assignment_inventory!(request:, peer:, role:)
          params = request.fetch("params")
          strict!(params, %w[mapping_id journal_commit after limit])
          raise ArgumentError, "Inventory mutation ID must be null" unless request.fetch("mutation_id").nil?
          unless %i[launcher supervisor].include?(role)
            raise AttemptErrors::UnauthorizedIdentity, "Inventory requires mapped launcher or supervisor"
          end
          map = steering_principal!(params, peer, role)
          limit = params.fetch("limit")
          raise ArgumentError, "Inventory limit is invalid" unless limit.is_a?(Integer) && limit.between?(1, 50)
          after = params.fetch("after")
          unless after.nil?
            strict!(after, %w[assignment_id attempt_id])
            token!(after.fetch("assignment_id"))
            token!(after.fetch("attempt_id")) unless after.fetch("attempt_id").nil?
            raise ArgumentError, "Inventory continuation requires selected commit" if params.fetch("journal_commit").nil?
          end
          journal = journal_for(map)
          canonical_commit = journal.ref_value
          commit = params.fetch("journal_commit") || canonical_commit
          journal.verify_canonical_prefix!(commit: commit, canonical_commit: canonical_commit)
          indexed = inventory_index!(journal, commit, params.fetch("mapping_id"), map)
          offset = 0
          if after
            position = indexed.index { |entry| entry.fetch(:selector) == after }
            raise AttemptErrors::NotFound, "Inventory cursor does not select a visible row" unless position
            offset = position + 1
          end
          data = {"project_id" => map.fetch("project_id"), "mapping_id" => params.fetch("mapping_id"),
            "journal_commit" => commit, "items" => [], "next_after" => nil}
          indexed.drop(offset).first(limit).each do |entry|
            row = inventory_row!(journal, commit, entry)
            proposed = data.merge("items" => data.fetch("items") + [row],
              "next_after" => offset + data.fetch("items").size + 1 < indexed.size ? entry.fetch(:selector) : nil)
            # Size the actual fixed public envelope, retaining whole rows and
            # an honest cursor without truncating or omitting canonical facts.
            frame = {"status" => "ok", "data" => proposed, "transport" => {"replayed" => false}}
            if JSON.generate(frame).bytesize + 1 > 16_384
              raise AttemptErrors::BoundedResultUnavailable, "Inventory row exceeds bounded response" if data.fetch("items").empty?
              break
            end
            data = proposed
          end
          {data: data, replayed: false}
        end

        def inventory_index!(journal, commit, mapping_id, map)
          authenticated = journal.canonical_event_inventory!(commit: commit)
          raise AttemptErrors::EvidenceUnavailable, "Inventory authenticated snapshot differs" unless authenticated.fetch("commit") == commit
          snapshots = authenticated.fetch("events")
          introductions = authenticated.fetch("introductions")
          entries = snapshots.flat_map do |assignment_id, events|
            registrations = events.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "register_assignment" }
            next [] if registrations.empty?
            attempts = events.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "reserve_attempt" }
            if attempts.empty?
              registration = registrations.last.fetch("payload").fetch("data")
              next [] unless registration["mapping_id"] == mapping_id
              authenticate_inventory_registration!(journal, assignment_id, events, registration, mapping_id, map, commit, introductions.fetch(assignment_id))
              next [{selector: {"assignment_id" => assignment_id, "attempt_id" => nil}, registration: registration, map: map}]
            end
            selected = attempts.select { |event| event.dig("payload", "data", "mapping_id") == mapping_id }
            next [] if selected.empty?
            prefixes = introductions.fetch(assignment_id)
            selected.map do |reserve|
              attempt_id = reserve.fetch("attempt_id")
              chain = events.select { |event| event["attempt_id"] == attempt_id }
              registration = definition(journal, assignment_id, commit: prefixes.fetch(reserve.fetch("digest")))
              unless registration && registration.values_at("assignment_id", "project_id", "mapping_id") == [assignment_id, map.fetch("project_id"), mapping_id]
                raise AttemptErrors::EvidenceUnavailable, "Inventory reservation registration differs"
              end
              registration_events = journal.read_events(assignment_id, commit: prefixes.fetch(reserve.fetch("digest")))
              authenticate_inventory_registration!(journal, assignment_id, registration_events, registration, mapping_id, map, prefixes.fetch(reserve.fetch("digest")), prefixes)
              {selector: {"assignment_id" => assignment_id, "attempt_id" => attempt_id},
                registration: registration, events: chain, map: map, introductions: prefixes}
            end
          end
          selectors = entries.map { |entry| entry.fetch(:selector).values_at("assignment_id", "attempt_id") }
          raise AttemptErrors::EvidenceUnavailable, "Inventory row identity is ambiguous" unless selectors.uniq.size == selectors.size
          entries.sort_by { |entry| [entry.fetch(:selector).fetch("assignment_id").b, entry.fetch(:selector).fetch("attempt_id").to_s.b] }
        rescue KeyError, TypeError, NoMethodError
          raise AttemptErrors::EvidenceUnavailable, "Inventory canonical index is malformed"
        end

        def authenticate_inventory_registration!(journal, assignment_id, events, registration, mapping_id, map, commit, introductions)
          unless registration.is_a?(Hash) && registration.values_at("assignment_id", "project_id", "mapping_id", "phase") ==
              [assignment_id, map.fetch("project_id"), mapping_id, "registered"]
            raise AttemptErrors::EvidenceUnavailable, "Inventory accepted registration association differs"
          end
          chain = events.select { |event| event["attempt_id"] == "definition-#{assignment_id}" }
          journal.authority_generation(chain)
          accepted = chain.select { |event| event["type"] == "authority_mutation" &&
            event.dig("payload", "operation") == "register_assignment" && event.dig("payload", "data") == registration }
          raise AttemptErrors::EvidenceUnavailable, "Inventory registration provenance is ambiguous" unless accepted.one?
          event = accepted.first
          prefix = introductions.fetch(event.fetch("digest"))
          original_chain = journal.read_events(assignment_id, commit: prefix).select { |item| item["attempt_id"] == "definition-#{assignment_id}" }
          unless original_chain.last == event && registration["generation"].is_a?(Integer) &&
              registration["generation"] == journal.authority_generation(original_chain)
            raise AttemptErrors::EvidenceUnavailable, "Inventory registration generation/introduction differs"
          end
        end

        def inventory_definition!(journal, commit, entry)
          selector, registration = entry.values_at(:selector, :registration)
          bytes = journal.blob(registration.fetch("definition_ref"), commit: commit)
          unless bytes.is_a?(String) && bytes.bytesize <= 32_768 &&
              Digest::SHA256.hexdigest(bytes) == registration.fetch("definition_digest")
            raise AttemptErrors::EvidenceUnavailable, "Inventory definition content differs"
          end
          value = JSON.parse(bytes)
          prepared = value.fetch("prepared_work")
          unless registration.fetch("prepared_work") == prepared && prepared.fetch("task_id") == registration.fetch("task_id") &&
              registration.fetch("selection_sha256") == prepared.fetch("selection_sha256") &&
              registration.fetch("prepared_bundle_sha256").is_a?(String) && registration.fetch("prepared_bundle_sha256").match?(PreparedWork::SHA) &&
              registration.fetch("prepared_bundle_bytes").is_a?(Integer) && registration.fetch("prepared_bundle_bytes").between?(1, PreparedWork::MAX_TOTAL) &&
              registration.fetch("prepared_bundle_ref") == "execution/prepared/#{selector.fetch('assignment_id')}-#{registration.fetch('prepared_bundle_sha256')}.bundle"
            raise AttemptErrors::EvidenceUnavailable, "Inventory prepared input identity differs"
          end
          assignment = Models::Assignment.from_h(value)
          unless assignment.managed? && assignment.id == selector.fetch("assignment_id") &&
              assignment.project_id == registration.fetch("project_id") && assignment.task_id == registration.fetch("task_id") &&
              registration.fetch("definition_generation").is_a?(Integer) && registration.fetch("definition_generation").positive?
            raise AttemptErrors::EvidenceUnavailable, "Inventory definition provenance differs"
          end
          assignment
        end

        def inventory_row!(journal, commit, entry)
          inventory_definition!(journal, commit, entry)
          selector, registration = entry.values_at(:selector, :registration)
          row = selector.merge(registration.slice("task_id", "definition_digest", "definition_generation", "prepared_bundle_ref", "prepared_bundle_bytes", "prepared_bundle_sha256", "selection_sha256"),
            "scope" => nil, "reservation_mutation_id" => nil, "base_head" => nil, "reservation_generation" => nil, "generation" => nil, "canonical_state" => nil,
            "original_binding_digest" => nil, "terminal_event_id" => nil, "reservation_release_event_id" => nil)
          return row unless selector.fetch("attempt_id")
          events = entry.fetch(:events)
          map = entry.fetch(:map)
          state = origin(events, **selector.merge("mapping_id" => registration.fetch("mapping_id")).transform_keys(&:to_sym))
          generation = journal.authority_generation(events)
          unless generation.is_a?(Integer) && generation.positive? && state.fetch("reservation_generation").is_a?(Integer) && state.fetch("reservation_generation").positive?
            raise AttemptErrors::EvidenceUnavailable, "Inventory attempt generation is invalid"
          end
          reservations = events.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "reserve_attempt" }
          raise AttemptErrors::EvidenceUnavailable, "Inventory original reservation is ambiguous" unless reservations.one?
          reservation = reservations.first.fetch("payload")
          mutation_id = reservation.fetch("mutation_id")
          token!(mutation_id)
          base_head = reservation.fetch("data").fetch("base_head")
          unless base_head.is_a?(String) && base_head.match?(/\A[0-9a-f]{40}\z/) && state.fetch("base_head") == base_head
            raise AttemptErrors::EvidenceUnavailable, "Inventory original reservation base differs"
          end
          row.merge!("scope" => state.fetch("scope"), "reservation_mutation_id" => mutation_id, "base_head" => base_head, "reservation_generation" => state.fetch("reservation_generation"),
            "generation" => generation, "canonical_state" => journal.canonical_attempt_state(events))
          if events.any? { |event| event.dig("payload", "operation") == "record_launch" }
            row["original_binding_digest"] = original_prompt_record!(events, state,
              params: selector.merge("mapping_id" => registration.fetch("mapping_id"))).fetch("binding_digest")
          end
          terminal_events = events.select { |event| %w[receipt_accepted attempt_stopped].include?(event["type"]) }
          releases = events.select { |event| event.dig("payload", "operation") == "scope_reservation_release" }
          guarded_abort = events.any? { |event| event.dig("payload", "operation") == "abort_launch" }
          return row if terminal_events.empty? && releases.empty? && !guarded_abort
          original, original_map = inventory_original_deployment!(journal, events, registration.fetch("mapping_id"), map)
          lineage = Molecules::ExecutionScopeLineage.new(events: events, project_id: original_map.fetch("project_id"),
            assignment_id: selector.fetch("assignment_id"), attempt_id: selector.fetch("attempt_id"), mapping_id: registration.fetch("mapping_id"))
          introductions = entry.fetch(:introductions)
          terminal_introduction = nil
          terminal = if events.any? { |event| event["type"] == "attempt_stopped" }
            stopped = events.find { |event| event["type"] == "attempt_stopped" }
            accepted = events.select { |event| event["type"] == "authority_mutation" && event["previous_digest"] == stopped.fetch("digest") }
            raise AttemptErrors::EvidenceUnavailable, "Inventory stopped acceptance is ambiguous" unless accepted.one?
            terminal_introduction = introductions.fetch(accepted.first.fetch("digest"))
            verify_stopped_terminal_at_prefix!(events, journal, terminal_introduction, deployment: original)
          else
            inventory_terminal_at_introduction!(journal, selector, events, original, original_map, registration.fetch("mapping_id"), introductions)
          end
          row["terminal_event_id"] = terminal.fetch("digest")
          unless releases.empty?
            raise AttemptErrors::EvidenceUnavailable, "Inventory release is ambiguous" unless releases.one?
            release = releases.first
            prefix = introductions.fetch(release.fetch("digest"))
            verify_released_lineage_at_prefix!(journal, prefix, selector.fetch("assignment_id"), selector.fetch("attempt_id"), events, original, original_map, terminal_introduction: terminal_introduction)
            row["reservation_release_event_id"] = release.fetch("digest")
          end
          row
        rescue KeyError, TypeError, JSON::ParserError, NoMethodError
          raise AttemptErrors::EvidenceUnavailable, "Inventory canonical row is malformed"
        end

        def inventory_terminal_at_introduction!(journal, selector, events, original, map, mapping_id, introductions)
          terminals = events.select { |event| event["type"] == "receipt_accepted" ||
            (event["type"] == "authority_mutation" && event.dig("payload", "operation") == "abort_launch") }
          raise AttemptErrors::EvidenceUnavailable, "Inventory terminal provenance is ambiguous" unless terminals.one?
          event = terminals.first
          prefix_commit = introductions.fetch(event.fetch("digest"))
          prefix = journal.read_events(selector.fetch("assignment_id"), commit: prefix_commit).select { |entry| entry["attempt_id"] == selector.fetch("attempt_id") }
          terminal_length = events.index(event) + 1
          if event["type"] == "receipt_accepted"
            transition, acceptance = events.drop(terminal_length).take(2)
            if transition && acceptance && transition["type"] == "transition" &&
                acceptance["type"] == "authority_mutation" && acceptance.dig("payload", "operation") == "finish"
              unless introductions.fetch(transition.fetch("digest")) == prefix_commit &&
                  introductions.fetch(acceptance.fetch("digest")) == prefix_commit
                raise AttemptErrors::EvidenceUnavailable, "Inventory finish acceptance introduction differs"
              end
              terminal_length += 2
            end
          end
          unless prefix == events.take(terminal_length)
            raise AttemptErrors::EvidenceUnavailable, "Inventory terminal introduction differs"
          end
          lineage = Molecules::ExecutionScopeLineage.new(events: prefix, project_id: map.fetch("project_id"),
            assignment_id: selector.fetch("assignment_id"), attempt_id: selector.fetch("attempt_id"), mapping_id: mapping_id)
          terminal = terminal_scope_receipt!(prefix, lineage, journal, prefix_commit, deployment: original)
          if prefix.any? { |entry| entry.dig("payload", "operation") == "finish" }
            unless lineage.proof_event && !pending_prompt_issuers?(prefix, journal, prefix_commit) && @result_owner
              raise AttemptErrors::EvidenceUnavailable, "Inventory finish closure owner is unavailable"
            end
            lineage.require_positive!(scope_generation: lineage.binding.fetch("scope_generation"),
              scope_binding_event_id: lineage.binding_event.fetch("digest"), seal_event_id: lineage.seal_event.fetch("digest"), proof_id: lineage.proof_id)
            params = selector.merge("mapping_id" => mapping_id)
            if terminal.dig("payload", "receipt", "verdict") == "succeeded"
              finish = prefix.find { |entry| entry.dig("payload", "operation") == "finish" }
              review_params = params.merge(finish.fetch("payload").fetch("data").slice("head", "candidate_generation"))
              @result_owner.finished_review_evidence!(journal: journal, events: prefix, params: review_params,
                map: map, commit: prefix_commit)
            end
            @result_owner.service_settlement_complete!(journal: journal, events: prefix, params: params, map: map, commit: prefix_commit)
            @result_owner.historical_inbox_settlement_complete!(journal: journal, events: prefix, params: params, map: map,
              commit: prefix_commit, deployment: original, history: @deployment_history)
          end
          terminal
        end

        def inventory_original_deployment!(journal, events, mapping_id, current_map)
          provisioning = events.select { |event| event["type"] == "scope_provisioning" }
          raise AttemptErrors::EvidenceUnavailable, "Inventory original provisioning is ambiguous" unless provisioning.one?
          identity = provisioning.first.fetch("payload")
          unless identity.is_a?(Hash) && identity.keys.sort == %w[deployment_digest descriptor_sha256 reservation_generation slot_id]
            raise AttemptErrors::EvidenceUnavailable, "Inventory original provisioning is malformed"
          end
          original = if identity.fetch("descriptor_sha256") == protected_descriptor_sha256!
            @deployment
          else
            raise AttemptErrors::EvidenceUnavailable, "Inventory original descriptor owner unavailable" unless @deployment_history
            @deployment_history.descriptor!(sha256: identity.fetch("descriptor_sha256"))
          end
          map = original.mapping(mapping_id)
          project = original.project(map.fetch("project_id"))
          unless map.fetch("project_id") == current_map.fetch("project_id") &&
              map.fetch("execution_scope").fetch("slot_id") == identity.fetch("slot_id") &&
              original.mapping_digest(mapping_id) == identity.fetch("deployment_digest") &&
              [project.fetch("journal_repository"), project.fetch("evidence_git_ref"), project.fetch("evidence_checkout_root")] == [journal.repo_root, journal.ref, journal.checkout_root]
            raise AttemptErrors::EvidenceUnavailable, "Inventory original descriptor association differs"
          end
          [original, map]
        end
      end
    end
  end
end
