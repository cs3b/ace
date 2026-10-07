# frozen_string_literal: true

require_relative "inbox_context_session"

module Ace
  module Assign
    module Authority
      class Endcap
        # Normal lifecycle settlement enters every selected current descriptor
        # context before the slot/assignment/journal exclusions. Historical
        # descriptor eligibility remains the existing historical owner's job.
        def with_inbox_settlement_contexts(params:, map:, journal:)
          # Closed register_assignment parameters are the one normal entry
          # that cannot inspect/settle an attempt and may create the first ref.
          return yield if params.key?("definition_bytes")
          contexts = @deployment.project(map.fetch("project_id")).fetch("inbox_contexts", {})
          return yield if contexts.empty?
          reference = @deployment.artifact_reference
          raise AttemptErrors::EvidenceUnavailable, "current context descriptor is unavailable" unless reference
          commit = journal.ref_value
          journal.verify_commit!(commit)
          selections = journal.assignment_ids(commit: commit).flat_map do |assignment_id|
            journal.read_events(assignment_id, commit: commit).group_by { |event| event.fetch("attempt_id") }.flat_map do |attempt_id, chain|
              next [] unless chain.any? { |event| event["type"] == "inbox_binding" }
              unless Models::EvidenceEvent.chain_valid?(chain)
                raise AttemptErrors::EvidenceUnavailable, "context settlement canonical chain differs"
              end
              provisioning = chain.select { |event| event["type"] == "scope_provisioning" }
              reservations = chain.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "reserve_attempt" }
              unless provisioning.one? && reservations.one?
                raise AttemptErrors::EvidenceUnavailable, "context settlement original reservation differs"
              end
              next [] unless provisioning.first.dig("payload", "descriptor_sha256") == reference.fetch("sha256")
              prior_map_id = reservations.first.dig("payload", "data", "mapping_id")
              prior_map = @deployment.mapping(prior_map_id)
              next [] unless prior_map.fetch("execution_scope").fetch("slot_id") == map.fetch("execution_scope").fetch("slot_id")
              chain.filter_map do |event|
                next unless event["type"] == "inbox_binding"
                params.merge("mapping_id" => prior_map_id, "assignment_id" => assignment_id, "attempt_id" => attempt_id,
                  "inbox_context_id" => event.fetch("payload").fetch("inbox_context_id"), "event_id" => event.fetch("payload").fetch("event_id"))
              end
            end
          end
          selections.sort_by! { |selected| selected.values_at("inbox_context_id", "assignment_id", "attempt_id", "event_id") }
          enter = lambda do |index|
            return yield if index == selections.size
            selected = selections.fetch(index)
            selected_map = @deployment.mapping(selected.fetch("mapping_id"))
            with_inbox_context(selected, selected_map, mutation_id: "settlement-query") do |session|
              session.require_idle!
              enter.call(index + 1)
            end
          end
          enter.call(0)
        rescue KeyError, TypeError, ArgumentError, NoMethodError, Ace::Herdr::Error, Ace::Runtime::RuntimeUnavailableError
          raise AttemptErrors::EvidenceUnavailable, "current context settlement admission is unavailable"
        end

        private

        def with_inbox_context(params, map, mutation_id:)
          key = params.values_at("mapping_id", "assignment_id", "attempt_id", "inbox_context_id", "event_id")
          registry = Thread.current[:ace_assign_inbox_context_sessions] ||= {}
          owner_key = [object_id, key]
          return yield registry.fetch(owner_key) if registry.key?(owner_key)
          context = @deployment.inbox_context(params.fetch("mapping_id"), params.fetch("inbox_context_id"))
          @deployment.verify_inbox_context!(params.fetch("mapping_id"), params.fetch("inbox_context_id"))
          client = @inbox_context_clients&.fetch(params.fetch("inbox_context_id"))
          client ||= Ace::Herdr::Molecules::InboxContextClient.selected(context_id: params.fetch("inbox_context_id"),
            socket_path: context.fetch("control_socket_path"), owner_credentials: context.fetch("owner_credentials"), kernel: @kernel)
          session = InboxContextSession.new(client: client, params: params, map: map, mutation_id: mutation_id,
            authority_peer: @kernel.capture(Process.pid))
          registry[owner_key] = session
          begin
            result = yield session
            resume_inbox_context_completion!(session, params, map, mutation_id) if session.pending?
            session.end!
            result
          rescue StandardError
            # The real owner positively ends only a known idle admission. A
            # pending/uncertain effect refuses end and remains durable.
            begin
              session.end!
            rescue Ace::Herdr::Error, Ace::Assign::Error
              nil
            end
            raise
          ensure
            registry.delete(owner_key)
            Thread.current[:ace_assign_inbox_context_sessions] = nil if registry.empty?
          end
        rescue Ace::Runtime::RuntimeUnavailableError, Ace::Herdr::Error
          raise AttemptErrors::EvidenceUnavailable, "protected inbox context is unavailable"
        end

        # Recover a lost completion ACK only from the accepted original effect.
        # This runs after the yielded assignment/journal exclusions return.
        def resume_inbox_context_completion!(session, params, map, mutation_id)
          journal = @launch.journals.fetch(map.fetch("project_id"))
          commit = journal.ref_value
          journal.verify_commit!(commit)
          events = journal.read_events(params.fetch("assignment_id"), commit: commit).select { |event|
            event["attempt_id"] == params.fetch("attempt_id") }
          replies = events.select { |event| event["type"] == "authority_mutation" &&
            event.dig("payload", "operation") == "reconcile_inbox" && event.dig("payload", "mutation_id") == mutation_id }
          records = events.select { |event| event["type"] == "inbox_reconciliation" &&
            event.dig("payload", "event_id") == params.fetch("event_id") &&
            event.dig("payload", "inbox_context_id") == params.fetch("inbox_context_id") &&
            event.dig("payload", "binding", "receipt_sha256") == params["receipt_sha256"] &&
            event.dig("payload", "binding", "signature_sha256") == params["signature_sha256"] }
          unless replies.one? && records.one?
            raise AttemptErrors::EvidenceUnavailable, "retained accepted context completion unavailable"
          end
          session.resume_completion!(binding: replies.first.fetch("payload").fetch("data").fetch("context_operation"),
            registration: records.first.fetch("payload").fetch("registration"), reconciliation_digest: records.first.fetch("digest"))
        end

        def with_inbox_read_contexts(params, map, &block)
          return block.call unless params["kind"] == "inbox"
          contexts = @deployment.project(map.fetch("project_id")).fetch("inbox_contexts", {})
          selected = contexts.keys.sort.select { |id| contexts.fetch(id).fetch("native_mapping_id") == params.fetch("mapping_id") }
          enter = lambda do |index|
            return block.call if index == selected.size
            own_params = params.merge("inbox_context_id" => selected.fetch(index), "event_id" => params.fetch("purpose_id"))
            with_inbox_context(own_params, map, mutation_id: "query") { enter.call(index + 1) }
          end
          enter.call(0)
        end

        def admitted_inbox_session!(params)
          key = params.values_at("mapping_id", "assignment_id", "attempt_id", "inbox_context_id", "event_id")
          session = Thread.current[:ace_assign_inbox_context_sessions]&.fetch([object_id, key], nil)
          raise AttemptErrors::EvidenceUnavailable, "context admission must precede lifecycle exclusion" unless session
          session
        end
      end
    end
  end
end
