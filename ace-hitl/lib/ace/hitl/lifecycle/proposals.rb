# frozen_string_literal: true

require_relative "../proposals/policy"

module Ace
  module Hitl
    module Lifecycle
      module Proposals
        def proposal_create(assignment:, attempt:, project:, document:)
          require_proposer!(project)
          content = Ace::Hitl::Proposals::Policy.document(document)
          id = "proposal-#{SecureRandom.hex(12)}"
          proposal_revision(id, 1, assignment: assignment, attempt: attempt, project: project, content: content)
        end

        def proposal_revise(id, document:)
          old = proposal_access!(id, requester: true)
          require_proposer!(old["project_id"])
          content = Ace::Hitl::Proposals::Policy.document(document)
          proposal_transition(old) do |current|
            unresolved = proposal_journal.proposal_claims(current["revision_id"]).any? do |claim|
              claim["state"] != "succeeded" &&
                !(claim["state"] == "failed-settled" && proposal_journal.settlement_evidence_intact?(claim))
            end
            if unresolved
              raise StateError, "Claimed proposal cannot be revised; reconcile the existing effect"
            end
            current.merge("state" => "superseded", "resolution" => "revised")
          end
          proposal_revision(id, old.fetch("revision") + 1, assignment: old["assignment_id"],
            attempt: old["attempt_id"], project: old["project_id"], content: content)
        end

        def proposal_show(id, history_after: 0)
          record = proposal_access!(id)
          unless history_after.is_a?(Integer) && history_after >= 0
            raise StateError, "history cursor must be a non-negative offset"
          end
          history = proposal_journal.proposal_history(id)
          entries = (history.slice(history_after, 3) || []).map do |entry|
            outcome = proposal_journal.proposal_claims(entry["revision_id"]).last
            entry.merge("actual_outcome" => outcome && outcome["state"],
              "effect_request_id" => outcome && outcome["request_id"])
          end
          claims = proposal_journal.proposal_claims(record["revision_id"])
          claim = claims.last
          outcome = case claim && claim["state"]
          when "accepted" then "executing"
          when "succeeded" then "succeeded"
          when "failed", "failed-settled", "rejected" then "failed"
          when "uncertain" then "uncertain"
          end
          record.merge("state" => outcome || record["state"], "decision_state" => record["state"],
            "effect_claim" => claim, "history" => entries, "history_count" => history.length,
            "history_next" => history_after + entries.length < history.length ? history_after + entries.length : nil)
        end

        def proposal_acknowledge(request, submitted_at:)
          record = proposal_for_request!(request)
          require_transport!("proposal delivery", {"project" => record["project_id"]})
          proposal_transition(record) { |current| Ace::Hitl::Proposals::Policy.acknowledge(current, submitted_at) }
        end

        def proposal_reply(request, answer:, received_at:, sequence:)
          record = proposal_for_request!(request)
          require_transport!("proposal reply", {"project" => record["project_id"]})
          proposal_transition(record) do |current|
            # Claims and this transition share one canonical ref lock/CAS.
            claimed = proposal_journal.proposal_claims(current["revision_id"]).any?
            Ace::Hitl::Proposals::Policy.reply(current, answer: answer, received_at: received_at,
              sequence: sequence, claimed: claimed)
          end
        end

        def proposal_reconcile(request, checkpoint:)
          record = proposal_for_request!(request)
          require_transport!("proposal reconciliation", {"project" => record["project_id"]})
          proposal_transition(record) do |current|
            Ace::Hitl::Proposals::Policy.resolve(current, checkpoint: checkpoint, now: proposal_now)
          end
        end

        def proposal_due(after: nil)
          require_transport!("proposal deadlines")
          records = proposal_journal.proposals.sort_by { |record| record["proposal_id"] }.select do |record|
            (!after || record["proposal_id"] > after) &&
              @policy.transport?(@identity, project: record["project_id"]) &&
              record["state"] == "awaiting-decision" && record["deadline"] <= proposal_now
          end
          selected = records.first(8)
          {"items" => selected.map { |record| record.slice("proposal_id", "request_id", "deadline") },
           "next" => records.length > 8 ? selected.last["proposal_id"] : nil}
        end

        def proposal_history(project:, query: "", after: nil)
          unless query.is_a?(String) && query.bytesize <= 240 && project.is_a?(String)
            raise StateError, "history requires a project and bounded query"
          end
          records = proposal_journal.proposals.sort_by { |record| record["proposal_id"] }.select do |record|
            next false unless record["project_id"] == project && (!after || record["proposal_id"] > after)
            visible = (record["requester"] == @identity.username && record["caller_uid"] == @identity.uid) ||
              @policy.transport?(@identity, project: project)
            visible && (query.empty? || JSON.generate(record.slice("operation", "target", "context", "recommendation")).downcase.include?(query.downcase))
          end
          selected = records.first(3)
          {"items" => selected, "next" => records.length > 3 ? selected.last["proposal_id"] : nil}
        end

        private

        def require_proposer!(project)
          unless @policy.respond_to?(:proposal?) && @policy.proposal?(@identity, project: project)
            raise PermissionError, "proposal requires the installed second-commander decision principal"
          end
        end

        def proposal_now
          @proposal_clock.call.utc.iso8601
        end

        def proposal_journal
          @binding.proposal_journal
        rescue NoMethodError
          raise BindingError, "Managed proposal authority is unavailable"
        end

        def proposal_access!(id, requester: false)
          unless id.is_a?(String) && id.match?(/\Aproposal-[0-9a-f]{24}\z/)
            raise StateError, "invalid proposal ID"
          end
          record = proposal_journal.proposal_record(id)
          raise StateError, "unknown proposal" unless record
          if record["requester"] != @identity.username || record["caller_uid"] != @identity.uid
            raise PermissionError, "only proposal requester may revise" if requester
            require_transport!("proposal read", {"project" => record["project_id"]})
          end
          record
        end

        def proposal_for_request!(request)
          unless request.is_a?(String) && request.match?(/\Aproposal-[0-9a-f]{24}-r[1-9][0-9]*\z/)
            raise StateError, "invalid proposal revision request"
          end
          id = request.sub(/-r[1-9][0-9]*\z/, "")
          record = proposal_journal.proposal_history(id).reverse.find { |entry| entry["request_id"] == request }
          raise StateError, "unknown proposal revision" unless record
          record
        end

        def proposal_transition(record, &policy)
          proposal_journal.change_proposal(record["proposal_id"], assignment_id: record["assignment_id"],
            attempt_id: record["attempt_id"]) do |current|
            # A reply to an older revision cannot modify the new decision.
            next current unless current["request_id"] == record["request_id"]
            policy.call(current)
          end
        rescue Ace::Assign::Error => e
          raise StateError, "Proposal transition refused (#{e.message})"
        end

        def proposal_revision(id, revision, assignment:, attempt:, project:, content:)
          request = "#{id}-r#{revision}"
          question = "Proposal #{request}: #{JSON.generate(content)}"
          if request_path(request).exist?
            existing = load_request(request)
            unless existing.values_at("assignment", "attempt", "project", "requester", "kind", "question") ==
                [assignment, attempt, project, @identity.username, "proposal", question]
              raise StateError, "existing proposal revision has different immutable content"
            end
          else
            create(id: request, assignment: assignment, attempt: attempt, project: project, kind: "proposal",
              plan: "second commander exact proposal", question: question, ace_hitl_id: id)
          end
          @binding.with_active(assignment: assignment, attempt: attempt, project: project, requester: @identity.username) do
            proposal_journal.change_proposal(id, assignment_id: assignment, attempt_id: attempt) do |previous|
              unless (revision == 1 && previous.nil?) ||
                  (previous && previous["revision"] == revision - 1 && previous["state"] == "superseded")
                raise StateError, "proposal revision changed concurrently"
              end
              content.merge("schema" => "ace.hitl.proposal/v1", "proposal_id" => id, "revision" => revision,
                "revision_id" => request, "request_id" => request, "assignment_id" => assignment,
                "attempt_id" => attempt, "project_id" => project, "requester" => @identity.username,
                "caller_uid" => @identity.uid, "content_digest" => Digest::SHA256.hexdigest(JSON.generate(content)),
                "state" => "awaiting-delivery", "created_at" => proposal_now,
                "authorization" => request)
            end
          end
        end
      end
    end
  end
end
