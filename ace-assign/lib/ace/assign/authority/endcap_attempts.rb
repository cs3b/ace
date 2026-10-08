# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class Endcap
        BIND_INBOX_PARAMETERS = %w[mapping_id assignment_id attempt_id expected_generation event_id inbox_context_id].freeze
        FINISH_PARAMETERS = %w[mapping_id assignment_id attempt_id expected_generation candidate_generation head result_id].freeze
        RECOVERY_PARAMETERS = %w[mapping_id assignment_id attempt_id expected_generation].freeze

        # Called only by the canonical terminal owner at its authenticated
        # introduction prefix, using the original deployment mapping.
        def finished_review_evidence!(journal:, events:, params:, map:, commit:)
          current = exact_candidate!(retained_candidate(events, params.fetch("candidate_generation")), params)
          accepted = approved_review!(journal, events, params, map, current, commit: commit)
          result = verified_result(journal, events, params, map, retained_origin(events, params), current, commit)
          raise AttemptErrors::EvidenceUnavailable, "finished canonical result is missing" unless result
          campaign_finished_result!(journal: journal, commit: commit, events: events, params: params, map: map,
            result: result, accepted: accepted)
          @launch.campaign_children_settled!(journal: journal, commit: commit, params: params, map: map)
          accepted
        end

        private

        def dispatch_recover(request:, peer:, role:, transfer: nil)
          raise ArgumentError, "Recovery forbids transfer" unless transfer.nil?
          params, map = attempt_consumer_request!(request, RECOVERY_PARAMETERS)
          selected_commit = nil
          journal = @launch.journals.fetch(map.fetch("project_id"))
          readonly = @launch.with_assignment(params: params, map: map) do |selected, _|
            protected_journal!(selected)
            selected_commit = selected.ref_value
            events = @launch.preview_attempt_events!(journal: selected, commit: selected_commit, params: params, map: map)
            finish_identity!(events, params, map, peer, role)
            accepted = selected.mutation_result(request.fetch("mutation_id"), commit: selected_commit)
            if accepted
              verify_recovery_reply!(selected, accepted, request, params, map)
              next({data: accepted.fetch("data").merge("journal_commit" => accepted.fetch("journal_commit")), replayed: true})
            end
            state = Molecules::CanonicalAttemptState.derive(events)
            next unless %w[succeeded failed stopped].include?(state)
            terminal = @launch.completion_terminal!(journal: selected, commit: selected_commit, params: params, map: map)
            {data: {"attempt_id" => params.fetch("attempt_id"), "state" => terminal.fetch("canonical_state"),
              "decision" => "restart-required", "reason" => "terminal_attempt", "generation" => terminal.fetch("generation"),
              "journal_commit" => selected_commit}, replayed: false}
          end
          return readonly if readonly
          recover_under_exclusion!(request, params, map, peer, role, selected_commit)
        end

        def recover_under_exclusion!(request, params, map, peer, role, selected_commit)
          @launch.with_assignment(params: params, map: map, exclusive: true) do |journal, _|
            unless journal.ref_value == selected_commit
              raise AttemptErrors::Conflict, "Recovery canonical selection advanced"
            end
            events = @launch.preview_attempt_events!(journal: journal, commit: selected_commit, params: params, map: map)
            finish_identity!(events, params, map, peer, role)
            journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: request.fetch("mutation_id"), operation: "recover", parameters_digest: Atoms::EvidenceDigest.digest(params),
              expected_generation: params.fetch("expected_generation"), with_replay: true) do |fresh, prefix, _generation|
              unless prefix == selected_commit
                raise AttemptErrors::Conflict, "Recovery canonical selection advanced"
              end
              origin = finish_identity!(fresh, params, map, peer, role)
              state = Molecules::CanonicalAttemptState.derive(fresh)
              effects_pending = recovery_pending_settlement do
                service_settlement_evidence!(journal: journal, events: fresh, params: params, map: map, commit: prefix)
              end
              bound = %w[bound issued].include?(origin["phase"])
              observation = if !effects_pending && state == "running" && bound
                @launch.recovery_observation!(journal: journal, events: fresh, params: params, map: map, commit: prefix)
              else
                {"liveness" => "unknown"}
              end
              decision, reason = Organisms::AttemptCoordinator.protected_recovery_decision(state: state,
                effects_pending: effects_pending, bound: bound,
                live: observation["liveness"] == "live", checkpoint: true)
              plan = Organisms::AttemptCoordinator.protected_recovery_plan(events: fresh, decision: decision, reason: reason, observation: observation)
              plan.except(:state).merge(data: {"attempt_id" => params.fetch("attempt_id"), "state" => plan.fetch(:state),
                "decision" => decision, "reason" => reason})
            end
          end
        end

        def recovery_pending_settlement
          yield
          false
        rescue AttemptErrors::ServiceSettlementPending
          true
        end

        def verify_recovery_reply!(journal, accepted, request, params, map)
          unless accepted["operation"] == "recover" && accepted["parameters_digest"] == Atoms::EvidenceDigest.digest(params) &&
              accepted.values_at("assignment_id", "attempt_id") == params.values_at("assignment_id", "attempt_id")
            raise AttemptErrors::Conflict, "Recovery mutation is already bound to different input"
          end
          prefix = accepted.fetch("journal_commit")
          events = @launch.preview_attempt_events!(journal: journal, commit: prefix, params: params, map: map)
          index = events.index { |event| event.dig("payload", "mutation_id") == request.fetch("mutation_id") && event.dig("payload", "operation") == "recover" }
          raise AttemptErrors::EvidenceUnavailable, "Recovery acceptance is missing" unless index && index.positive?
          before = events.take(index)
          transition = before.last["type"] == "transition" && before.last.dig("payload", "to") == "uncertain" ? before.pop : nil
          observation = before.last
          data = accepted.fetch("data")
          reasons = %w[live_owner unresolved_effect unresolved_inbox launch_unbound scope_unverifiable attempt_uncertain checkpoint_unavailable]
          unless data.is_a?(Hash) && data.keys.sort == %w[attempt_id state decision reason generation].sort &&
              data["attempt_id"] == params.fetch("attempt_id") && data["generation"].is_a?(Integer) &&
              data["generation"] == journal.authority_generation(events) && reasons.include?(data["reason"]) &&
              ((data["decision"] == "adopt" && data["reason"] == "live_owner" && data["state"] == "running") ||
                (data["decision"] == "reconcile-required" && data["reason"] != "live_owner")) &&
              events[index]["type"] == "authority_mutation" && index == events.length - 1
            raise AttemptErrors::EvidenceUnavailable, "Recovery reply schema or accepted prefix differs"
          end
          unless observation && observation["type"] == "recovery_observation" && observation.dig("payload", "decision") == data["decision"] &&
              observation.dig("payload", "recovery_reason") == data["reason"] && observation.dig("payload", "observation").is_a?(Hash) &&
              (!transition || transition.fetch("payload") == {"from" => "running", "to" => "uncertain", "reason" => data.fetch("reason")}) &&
              Molecules::CanonicalAttemptState.derive(events) == data.fetch("state")
            raise AttemptErrors::EvidenceUnavailable, "Recovery observation acceptance differs"
          end
          binding = retained_origin(events, params).fetch("process_binding", nil)
          observed = observation.dig("payload", "observation")
          if observed["liveness"] == "live" && (!binding || observed["runtime_binding"] != binding || observed["identity"] != binding.fetch("process_identity"))
            raise AttemptErrors::EvidenceUnavailable, "Recovery original live binding differs"
          end
          true
        end

        def dispatch_finish(request:, peer:, role:, transfer: nil)
          raise ArgumentError, "Result finish forbids transfer" unless transfer.nil?
          params, map = attempt_consumer_request!(request, FINISH_PARAMETERS)
          unless params["candidate_generation"].is_a?(Integer) && params["candidate_generation"].positive? &&
              params["head"].is_a?(String) && params["head"].match?(CandidateTransfer::SHA) &&
              params["result_id"].is_a?(String) && params["result_id"].match?(/\A[0-9a-f]{32}\z/)
            raise ArgumentError, "Result finish selectors differ"
          end
          journal = @launch.journals.fetch(map.fetch("project_id"))
          replay = @launch.with_assignment(params: params, map: map) do |selected, _|
            commit = selected.ref_value
            accepted = selected.mutation_result(request.fetch("mutation_id"), commit: commit)
            next unless accepted
            unless accepted["operation"] == "finish" && accepted["parameters_digest"] == Atoms::EvidenceDigest.digest(params) &&
                accepted.values_at("assignment_id", "attempt_id") == params.values_at("assignment_id", "attempt_id")
              raise AttemptErrors::Conflict, "Finish mutation is already bound to different input"
            end
            events = @launch.preview_attempt_events!(journal: selected, commit: commit, params: params, map: map)
            finish_identity!(events, params, map, peer, role)
            @launch.completion_terminal!(journal: selected, commit: commit, params: params, map: map)
            {data: accepted.fetch("data").merge("journal_commit" => accepted.fetch("journal_commit")), replayed: true}
          end
          return replay if replay
            @launch.with_assignment(params: params, map: map, exclusive: true) do |selected, _|
              protected_journal!(selected)
              commit = selected.ref_value
              events = @launch.preview_attempt_events!(journal: selected, commit: commit, params: params, map: map)
              finish_identity!(events, params, map, peer, role)
              replay = selected.mutation_result(request.fetch("mutation_id"), commit: commit)
              if replay && replay["operation"] == "finish"
                @launch.completion_terminal!(journal: selected, commit: commit, params: params, map: map)
              end
              with_campaign_finish!(journal: selected, commit: commit, events: events, params: params, map: map) do
                selected.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
                mutation_id: request.fetch("mutation_id"), operation: "finish", parameters_digest: Atoms::EvidenceDigest.digest(params),
                expected_generation: params.fetch("expected_generation"), with_replay: true) do |fresh, prefix, _generation|
                origin = finish_identity!(fresh, params, map, peer, role)
                unless Molecules::CanonicalAttemptState.derive(fresh) == "running" && %w[bound issued].include?(origin["phase"])
                  raise AttemptErrors::Conflict, "Result finish requires an active bound attempt"
                end
                current = exact_candidate!(candidate(fresh), params)
                result = verified_result(selected, fresh, params, map, origin, current, prefix, result_id: params.fetch("result_id"))
                unless result && result.fetch("result_id") == params.fetch("result_id")
                  raise AttemptErrors::EvidenceUnavailable, "Result finish requires its exact submitted receipt"
                end
                if result.dig("receipt", "verdict") == "succeeded"
                  accepted = approved_review!(selected, fresh, params, map, current, commit: prefix)
                  campaign_finished_result!(journal: selected, commit: prefix, events: fresh, params: params, map: map,
                    result: result, accepted: accepted)
                end
                @launch.campaign_children_settled!(journal: selected, commit: prefix, params: params, map: map)
                @launch.completion_scope!(journal: selected, events: fresh, params: params, map: map, commit: prefix)
                service_settlement_evidence!(journal: selected, events: fresh, params: params, map: map, commit: prefix)
                plan = Organisms::AttemptCoordinator.finished_transition_plan(events: fresh, receipt: result.fetch("receipt"))
                plan.merge(data: params.slice("attempt_id", "result_id", "head", "candidate_generation").merge(
                  "receipt_digest" => result.fetch("receipt_digest"), "state" => result.dig("receipt", "verdict")))
                end
              end
            end
        end

        def finish_identity!(events, params, map, peer, role)
          unless %i[launcher supervisor].include?(role)
            raise AttemptErrors::UnauthorizedIdentity, "Result finish requires mapped completion owner"
          end
          origin = retained_origin(events, params)
          purpose_peer!(events, params, map, origin, peer, role, kind: "result")
          origin
        end

        def attempt_consumer_request!(request, fields)
          params = request.fetch("params")
          unless params.is_a?(Hash) && params.keys.sort == fields.sort
            raise ArgumentError, "attempt consumer parameters differ"
          end
          %w[mapping_id assignment_id attempt_id].each { |key| result_id!(params.fetch(key)) }
          result_id!(request.fetch("mutation_id"))
          unless params["expected_generation"].is_a?(Integer) && params["expected_generation"] >= 0
            raise ArgumentError, "attempt consumer generation differs"
          end
          map = @deployment.mapping(params.fetch("mapping_id"))
          unless map.fetch("project_id") == request.fetch("project_id")
            raise AttemptErrors::UnauthorizedIdentity, "attempt consumer project differs"
          end
          [params, map]
        end

        # Original registration comes from the admitted fixed Inbox owner, not
        # from peer fields or a current filesystem receipt. Bind and seal share
        # the same canonical slot/task/assignment exclusion and CAS.
        def dispatch_bind_inbox(request:, peer:, role:, transfer: nil)
          raise ArgumentError, "Inbox binding forbids transfer" unless transfer.nil?
          params, map = attempt_consumer_request!(request, BIND_INBOX_PARAMETERS)
          %w[event_id inbox_context_id].each { |key| result_id!(params.fetch(key)) }
          with_inbox_context(params, map, mutation_id: request.fetch("mutation_id")) do |session|
            @launch.with_assignment(params: params, map: map, exclusive: true) do |journal, _|
              protected_journal!(journal)
              commit = journal.ref_value
              events = @launch.preview_attempt_events!(journal: journal, commit: commit, params: params, map: map)
              binding = bind_inbox_selection!(events, params, map, peer, role, session)
              replay = journal.mutation_result(request.fetch("mutation_id"), commit: commit)
              verify_inbox_binding_reply!(events, replay, binding) if replay && replay["operation"] == "bind_inbox"
              journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
                mutation_id: request.fetch("mutation_id"), operation: "bind_inbox", parameters_digest: Atoms::EvidenceDigest.digest(params),
                expected_generation: params.fetch("expected_generation"), with_replay: true) do |fresh, _prefix, _generation|
                @launch.scope_open_for_effect!(events: fresh, params: params, map: map)
                selected = bind_inbox_selection!(fresh, params, map, peer, role, session)
                existing = fresh.select { |event| event["type"] == "inbox_binding" && event.dig("payload", "event_id") == params.fetch("event_id") }
                unless existing.empty? || (existing.one? && existing.first.fetch("payload") == selected)
                  raise AttemptErrors::Conflict, "Inbox registration is already bound differently"
                end
                {events: existing.empty? ? [{type: "inbox_binding", payload: selected}] : [], blobs: {}, data: selected}
              end
            end
          end
        end

        def bind_inbox_selection!(events, params, map, peer, role, session)
          unless Molecules::CanonicalAttemptState.derive(events) == "running"
            raise AttemptErrors::EvidenceUnavailable, "Inbox binding requires an active original worker"
          end
          submitting_worker!(events, params, map, peer, role)
          context = @deployment.inbox_context(params.fetch("mapping_id"), params.fetch("inbox_context_id"))
          lineage = Molecules::ExecutionScopeLineage.new(events: events, project_id: map.fetch("project_id"),
            assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: context.fetch("native_mapping_id"))
          original = params.slice("assignment_id", "mapping_id", "inbox_context_id").merge("project_id" => map.fetch("project_id"))
          record = session.request("status_context", {"event_id" => params.fetch("event_id"),
            "attempt_id" => params.fetch("attempt_id"), "original" => original}).fetch("record")
          registration = record.slice(*INBOX_REGISTRATION_FIELDS)
          unless inbox_registration?(registration) && registration.values_at("event_id", "attempt_id") == params.values_at("event_id", "attempt_id")
            raise AttemptErrors::EvidenceUnavailable, "Inbox original registration differs"
          end
          inbox_native_lineage!(record, lineage)
          params.slice("event_id", "attempt_id", "inbox_context_id").merge("registration" => registration)
        end

        def verify_inbox_binding_reply!(events, reply, selected)
          bindings = events.select { |event| event["type"] == "inbox_binding" && event.fetch("payload") == selected }
          unless bindings.one? && reply.fetch("data").except("generation") == selected
            raise AttemptErrors::EvidenceUnavailable, "Inbox binding replay provenance differs"
          end
        end
      end
    end
  end
end
