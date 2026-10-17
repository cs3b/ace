# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      module OrdinaryCampaignExecution
        CAMPAIGN_PROVIDER = "role:review-default"

        private

        def ordinary_campaign_review_selection!(params:, events:, commit:, deadline:, mutation_id:, prior:)
          association = events.any? { |event| event.dig("payload", "operation") == "campaign_start" }
          return nil unless association || params.key?("campaign")
          unless association && @campaign && params["campaign"].is_a?(Hash) && params["campaign"].keys.sort == %w[round_id scope]
            raise AttemptErrors::EvidenceUnavailable, "campaign review requires its canonical association and pinned scope"
          end
          selected = ordinary_campaign_selection!(events, commit)
          selection = params.fetch("campaign")
          selection.each_value { |value| token!(value) }
          origin = origin_at!(events: events, commit: commit)
          current = ->(current_events, prefix) { origin_at!(events: current_events, commit: prefix) }
          with_ordinary_campaign(events, commit, params, current) do |manager, profiles, guard|
            if prior
              previous = prior.fetch("payload").fetch("data")
              if previous["campaign"].nil? || previous.dig("campaign", "campaign_id") != selected.fetch("campaign_id")
                raise AttemptErrors::Conflict, "previous ordinary review is not owned by this campaign"
              end
              # A new scope/round cannot abandon an unresolved reviewer. The
              # existing terminal collection owner supplies this disposition.
              # A supervisor-revoked selection settles its reservation as a
              # transient unavailable failure: cancellation is never a
              # successful execution, and only the campaign's existing retry
              # budget governs whether a further selection is admitted.
              revoked = events.any? do |event|
                event["type"] == "authority_mutation" && event.dig("payload", "operation") == "cancel_review" &&
                  event.dig("payload", "data", "review_id") == previous.fetch("review_id")
              end
              if revoked
                manager.complete_execution(selected.fetch("campaign_id"),
                  execution_id: previous.fetch("campaign").fetch("execution_id"), status: "failed", failure: "unavailable")
              else
                result = ordinary_terminal_collection_reference!(previous, commit)
                with_review_collection!(events: events, commit: commit, reference: result) do |_proof, _reader|
                  manager.complete_execution(selected.fetch("campaign_id"), execution_id: previous.fetch("campaign").fetch("execution_id"), status: "succeeded")
                end
              end
            end
            binding = nil
            manager.with_execution_round!(selected.fetch("campaign_id"), round_id: selection.fetch("round_id"), consumer_profiles: profiles) do |round, round_guard|
              unless round.slice("campaign_id", "subject", "contract_identity", "policy") == selected.slice("campaign_id", "subject", "contract_identity", "policy") &&
                  round.fetch("binding").values_at("head", "base") == [params.fetch("head"), origin.fetch("base_head")]
                raise AttemptErrors::EvidenceUnavailable, "campaign review pin differs from canonical producer"
              end
              binding = round.fetch("binding")
              round_guard.call
              guard.call
            end
            scope = binding.fetch("scope_identity").fetch(selection.fetch("scope"))
            session = manager.session_binding(selected.fetch("campaign_id"), round_id: selection.fetch("round_id"),
              scope: selection.fetch("scope"), preset: scope.fetch("preset"), subjects: scope.fetch("subjects"),
              head: params.fetch("head"), base: origin.fetch("base_head"))
            entry = manager.reserve_execution(selected.fetch("campaign_id"), round_id: selection.fetch("round_id"),
              scope: selection.fetch("scope"), provider: CAMPAIGN_PROVIDER, request_id: mutation_id)
            unless entry.fetch("status") == "running"
              raise AttemptErrors::Conflict, "campaign execution reservation is already settled"
            end
            guard.call
            {"campaign_id" => selected.fetch("campaign_id"), "round_id" => selection.fetch("round_id"),
              "scope" => selection.fetch("scope"), "provider" => CAMPAIGN_PROVIDER,
              "execution_id" => entry.fetch("id"), "request_id" => mutation_id, "session_binding" => session}
          end
        end

        def ordinary_terminal_collection_reference!(assigned, commit)
          params = assigned.slice("reviewer_assignment_id", "reviewer_attempt_id")
            .transform_keys { |key| key.delete_prefix("reviewer_") }
          result = retained_ordinary_result(params, result_events(params, commit), commit)
          raise AttemptErrors::EvidenceUnavailable, "previous campaign collection is unresolved" unless result
          assigned.slice("review_id", "reviewer_assignment_id", "reviewer_attempt_id").merge(
            "result_id" => result.fetch("result_id"), "receipt_digest" => result.fetch("receipt").fetch("digest"))
        end

        def ordinary_campaign_begin_plan!(manager, profiles, guard, params, events, commit)
          selected = ordinary_review_selection!(events, params.fetch("review_id")).fetch("payload").fetch("data")
          campaign = selected.fetch("campaign")
          association = ordinary_campaign_selection!(events, commit)
          unless campaign.fetch("campaign_id") == association.fetch("campaign_id") &&
              selected.values_at("head", "candidate_generation") == params.values_at("head", "candidate_generation")
            raise AttemptErrors::ReceiptRejected, "campaign execution review selection differs"
          end
          if events.any? { |event| event.dig("payload", "operation") == "campaign_begin" &&
              event.dig("payload", "data", "review_id") == selected.fetch("review_id") }
            raise AttemptErrors::Conflict, "campaign provider dispatch already began; inspect original request"
          end
          manager.with_execution_round!(campaign.fetch("campaign_id"), round_id: campaign.fetch("round_id"), consumer_profiles: profiles) { |_round, check| check.call; guard.call }
          original = manager.reserve_execution(campaign.fetch("campaign_id"), round_id: campaign.fetch("round_id"),
            scope: campaign.fetch("scope"), provider: campaign.fetch("provider"), request_id: campaign.fetch("request_id"))
          unless original.values_at("id", "status") == [campaign.fetch("execution_id"), "running"]
            raise AttemptErrors::Conflict, "campaign original provider execution is not awaiting dispatch"
          end
          guard.call
          {events: [], data: campaign.merge("review_id" => selected.fetch("review_id"),
            "reviewer_origin" => selected.fetch("reviewer_origin"), "producer_origin" => selected.fetch("producer_origin"))}
        end
      end
    end
  end
end
