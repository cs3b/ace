# frozen_string_literal: true

require_relative "ordinary_effect_settlement"
require_relative "../organisms/attempt_coordinator"

module Ace
  module Assign
    module Authority
      # Terminal acceptance consumes the submitted canonical receipt. The
      # supervisor cannot replace its bytes, worker, scope or candidate.
      module OrdinaryCompletion
        FINISH_KEYS = %w[assignment_id attempt_id expected_generation pane head result_id receipt_digest].freeze

        private

        def finish_result(request, peer, role, deadline)
          params = request.fetch("params")
          strict!(params, FINISH_KEYS)
          %w[assignment_id attempt_id result_id].each { |key| token!(params.fetch(key)) }
          token!(request.fetch("mutation_id"))
          unless role == :supervisor
            raise AttemptErrors::UnauthorizedIdentity, "ordinary completion requires the installed supervisor"
          end
          unless params.fetch("expected_generation").is_a?(Integer) && params.fetch("expected_generation").positive? &&
              params.fetch("head").is_a?(String) && params.fetch("head").match?(/\A[0-9a-f]{40}\z/) &&
              params.fetch("receipt_digest").is_a?(String) && params.fetch("receipt_digest").match?(/\A[0-9a-f]{64}\z/)
            raise ArgumentError, "ordinary completion selection is invalid"
          end
          registered = registration(params.fetch("assignment_id"), commit: @journal.ref_value)
          raise AttemptErrors::NotFound, "ordinary work is not registered" unless registered
          digest = Atoms::EvidenceDigest.digest({"params" => params, "project_id" => @project, "peer_uid" => peer.fetch("uid")})
          @exclusion.with_shared_multi([@exclusion.task_key(registered.fetch("task_id"))], deadline: deadline) do
            @exclusion.with_exclusive(@exclusion.assignment_key(params.fetch("assignment_id")), deadline: deadline) do
              authorize!(request, peer, role, deadline)
              with_result_transport(request, deadline) do |transport|
                @journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
                  mutation_id: request.fetch("mutation_id"), operation: "finish", parameters_digest: digest,
                  expected_generation: params.fetch("expected_generation"), with_replay: true, deadline: deadline,
                  replay_authorizer: -> { authorize!(request, peer, role, deadline) }) do |events, prefix, _generation|
                  authorize!(request, peer, role, deadline)
                  unless Molecules::CanonicalAttemptState.derive(events) == "running"
                    raise AttemptErrors::Conflict, "ordinary completion requires a running attempt"
                  end
                  result = retained_ordinary_result(params, events, prefix)
                  unless result && result.fetch("result_id") == params.fetch("result_id") &&
                      result.dig("receipt", "digest") == params.fetch("receipt_digest") && result.dig("binding", "head") == params.fetch("head")
                    raise AttemptErrors::ReceiptRejected, "ordinary completion requires its exact submitted result"
                  end
                  binding = result.fetch("binding")
                  observed = @admission.recorded_execution!(binding: binding.fetch("runtime_binding"), head: binding.fetch("head"), deadline: deadline)
                  unless observed.fetch(:runtime_binding) == binding.fetch("runtime_binding") && observed.fetch(:checkout) == binding.fetch("checkout")
                    raise AttemptErrors::UnauthorizedIdentity, "ordinary result worker checkout changed"
                  end
                  references = events.select { |event| event["type"] == "inbox_binding" }.map { |event| event.fetch("payload") }
                  delivery = transport.call(references: references, attempt_id: params.fetch("attempt_id"), owner: binding.fetch("runtime_binding"))
                  scope = events.find { |event| event["type"] == "intent" }.fetch("payload").fetch("scope")
                  work = registered_work(registered, prefix, deadline)
                  queue = OrdinaryQueue.new(work: work, root: @input_root, bytes: queue_bytes(current_queue_record(registered, prefix), prefix))
                  verdict = result.dig("receipt", "verdict")
                  complete = verdict == "succeeded" ? queue.status.subtree_complete?(scope) : queue.status.subtree_failed?(scope)
                  raise AttemptErrors::Conflict, "ordinary result scope has unfinished progress" unless complete
                  settlement = OrdinaryEffectSettlement.new(journal: @journal).verify!(project: @project,
                    assignment: params.fetch("assignment_id"), attempt: params.fetch("attempt_id"), events: events, commit: prefix)
                  authorize!(request, peer, role, deadline)
                  plan = Organisms::AttemptCoordinator.finished_transition_plan(events: events, receipt: result.fetch("receipt"), authority: :ordinary)
                  plan.merge(data: params.slice("assignment_id", "attempt_id", "result_id", "head", "receipt_digest").merge(
                    "authority" => "ordinary", "scope" => scope, "state" => verdict, "settlement" => settlement, "inbox_deliveries" => delivery))
                end
              end
            end
          end
        rescue Ace::Herdr::Error => error
          raise AttemptErrors::EvidenceUnavailable, "ordinary transport settlement is unavailable: #{error.message}"
        end

        def with_result_transport(request, deadline)
          if @journal.mutation_result(request.fetch("mutation_id"), commit: @journal.ref_value)
            # A terminal reply is immutable. Current peer authority is still
            # checked by mutate, but retired transport files are not replay input.
            return yield nil
          end
          if @inbox
            @inbox.with_delivery_settlement(deadline: deadline) { |verify| yield verify }
          else
            yield lambda { |references:, **_|
              raise AttemptErrors::EvidenceUnavailable, "ordinary Inbox owner is not installed" unless references.empty?
              []
            }
          end
        end
      end
    end
  end
end
