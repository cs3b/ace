# frozen_string_literal: true

require_relative "../proposals/policy"

module Ace
  module Hitl
    module Lifecycle
      module Proposals
        def proposal_create(id:, assignment:, attempt:, project:, document:)
          require_proposer!(project)
          content = Ace::Hitl::Proposals::Policy.document(document)
          unless id.is_a?(String) && id.match?(/\Aproposal-[0-9a-f]{24}\z/)
            raise StateError, "create requires a stable proposal ID"
          end
          existing = proposal_journal.proposal_record(id)
          if existing && existing.values_at("assignment_id", "attempt_id", "project_id", "requester", "caller_uid", "content_digest") !=
              [assignment, attempt, project, @identity.username, @identity.uid, Digest::SHA256.hexdigest(JSON.generate(content))]
            raise StateError, "proposal retry changed immutable content or caller"
          end
          proposal_revision(id, 1, assignment: assignment, attempt: attempt, project: project, content: content)
        end

        def proposal_revise(id, expected_revision:, operation_id:, document:)
          old = proposal_access!(id, requester: true)
          require_proposer!(old["project_id"])
          unless expected_revision.is_a?(Integer) && expected_revision.positive? &&
              operation_id.is_a?(String) && operation_id.match?(/\Arevision-[0-9a-f]{24}\z/)
            raise StateError, "revise requires an expected source revision and stable revision operation ID"
          end
          content = Ace::Hitl::Proposals::Policy.document(document)
          replay = proposal_revision_replay(id, expected_revision, operation_id, content)
          if replay
            project_proposal_request(replay)
            return replay
          end
          proposal_revision(id, expected_revision + 1, assignment: old["assignment_id"],
            attempt: old["attempt_id"], project: old["project_id"], content: content,
            expected_revision: expected_revision, operation_id: operation_id)
        rescue Ace::Assign::AttemptErrors::ReceiptRejected => e
          raise StateError, "Proposal revision refused (#{e.message})"
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
            applied = proposal_journal.proposal_history(current["proposal_id"]).find do |entry|
              entry["revision_id"] == current["revision_id"] && entry["reply_sequence"] == sequence
            end
            Ace::Hitl::Proposals::Policy.reply(current, applied: applied, answer: answer, received_at: received_at,
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

        def proposal_wake(project:, after: nil)
          raise StateError, "invalid proposal wake project" unless project.is_a?(String) && Kinds::SAFE_LABEL.match?(project)
          require_proposer!(project)
          records = proposal_journal.proposals.sort_by { |record| record["proposal_id"] }.select do |record|
            record["project_id"] == project && (!after || record["proposal_id"] > after) &&
              record["state"] == "awaiting-decision" && record["deadline"] <= proposal_now
          end
          selected = records.first(8)
          items = selected.map do |record|
            proposal_transition(record) { |current| current["reconcile_requested_at"] ? current : current.merge("reconcile_requested_at" => proposal_now) }
            {"proposal_id" => record["proposal_id"], "status" => "queued-for-transport"}
          end
          {"items" => items, "next" => records.length > 8 ? selected.last["proposal_id"] : nil}
        end

        def proposal_due(after: nil)
          require_transport!("proposal deadlines")
          records = proposal_journal.proposals.sort_by { |record| record["proposal_id"] }.select do |record|
            (!after || record["proposal_id"] > after) &&
              @policy.transport?(@identity, project: record["project_id"]) &&
              record["state"] == "awaiting-decision" && record["deadline"] <= proposal_now && record["reconcile_requested_at"]
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
            visible = (record["requester"] == @identity.username && record["caller_uid"] == @identity.uid &&
              @policy.respond_to?(:proposal?) && @policy.proposal?(@identity, project: project)) ||
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
          if record["requester"] == @identity.username && record["caller_uid"] == @identity.uid &&
              @policy.respond_to?(:proposal?) && @policy.proposal?(@identity, project: record["project_id"])
            return record
          end
          if record["requester"] != @identity.username || record["caller_uid"] != @identity.uid
            raise PermissionError, "only proposal requester may revise" if requester
            require_transport!("proposal read", {"project" => record["project_id"]})
          else
            raise PermissionError, "proposal read requires current project authority" if requester
            require_transport!("proposal read", {"project" => record["project_id"]})
          end
          record
        end

        def proposal_for_request!(request)
          unless request.is_a?(String) && request.match?(/\Aproposal-[0-9a-f]{24}-r[1-9][0-9]*\z/)
            raise StateError, "invalid proposal revision request"
          end
          id = request.sub(/-r[1-9][0-9]*\z/, "")
          proposal_access!(id)
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

        def proposal_revision(id, revision, assignment:, attempt:, project:, content:, expected_revision: nil, operation_id: nil)
          request = "#{id}-r#{revision}"
          question = "Proposal #{request}: #{JSON.generate(content)}"
          replay = nil
          record = @binding.with_active(assignment: assignment, attempt: attempt, project: project, requester: @identity.username) do
            proposal_journal.change_proposal(id, assignment_id: assignment, attempt_id: attempt) do |previous|
              if operation_id
                replay = proposal_revision_replay(id, expected_revision, operation_id, content)
                next previous if replay
                unless previous && previous["revision"] == expected_revision
                  raise StateError, "proposal source revision changed concurrently"
                end
              end
              if previous && previous["revision"] == revision
                unless previous.values_at("assignment_id", "attempt_id", "project_id", "requester", "caller_uid", "content_digest") ==
                    [assignment, attempt, project, @identity.username, @identity.uid, Digest::SHA256.hexdigest(JSON.generate(content))]
                  raise StateError, "proposal retry changed immutable content or caller"
                end
                next previous
              end
              unless (revision == 1 && previous.nil?) ||
                  (operation_id && previous && previous["revision"] == expected_revision)
                raise StateError, "proposal revision changed concurrently"
              end
              projection = prepare_request(id: request, assignment: assignment, attempt: attempt, project: project,
                kind: "proposal", plan: "second commander exact proposal", question: question, ace_hitl_id: id)
              content.merge("schema" => "ace.hitl.proposal/v1", "proposal_id" => id, "revision" => revision,
                "revision_id" => request, "request_id" => request, "assignment_id" => assignment,
                "attempt_id" => attempt, "project_id" => project, "requester" => @identity.username,
                "caller_uid" => @identity.uid, "content_digest" => Digest::SHA256.hexdigest(JSON.generate(content)),
                "state" => "awaiting-delivery", "created_at" => proposal_now,
                "authorization" => request, "lifecycle_request" => projection).tap do |value|
                  if operation_id
                    value["revision_operation_id"] = operation_id
                    value["expected_source_revision"] = expected_revision
                  end
                end
            end
          end
          record = replay || record
          project_proposal_request(record)
          record
        end

        def proposal_revision_replay(id, expected_revision, operation_id, content)
          replay = proposal_journal.proposal_operation_record(operation_id)
          return unless replay
          unless replay.values_at("proposal_id", "expected_source_revision", "requester", "caller_uid", "content_digest") ==
              [id, expected_revision, @identity.username, @identity.uid, Digest::SHA256.hexdigest(JSON.generate(content))]
            raise StateError, "revision retry changed immutable source, content or caller"
          end
          replay
        end

        def project_proposal_request(record)
          value = record.fetch("lifecycle_request")
          if request_path(value.fetch("id")).exist?
            unless load_request(value.fetch("id")) == value
              raise StateError, "canonical proposal projection differs from lifecycle request"
            end
            initialize_projection!(value)
          else
            begin
              persist_request(value)
            rescue StateError => e
              raise unless e.message == "HITL request already exists" && load_request(value.fetch("id")) == value
              initialize_projection!(value)
            end
          end
        end

        def recover_proposal_projections(project:)
          return unless @binding.respond_to?(:proposal_journal)
          proposal_journal.proposals.each do |record|
            next if project && record["project_id"] != project
            next unless @policy.transport?(@identity, project: record["project_id"])
            project_proposal_request(record)
          end
        end
      end
    end
  end
end
