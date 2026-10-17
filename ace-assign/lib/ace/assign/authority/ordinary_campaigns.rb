# frozen_string_literal: true

require_relative "ordinary_campaign_owner"
require_relative "ordinary_campaign_execution"

module Ace
  module Assign
    module Authority
      module OrdinaryCampaigns
        include OrdinaryCampaignExecution
        CAMPAIGN_OPERATIONS = %w[campaign_start campaign_pin campaign_status campaign_begin].freeze
        CAMPAIGN_COMMON = %w[assignment_id attempt_id head candidate_generation].freeze
        CAMPAIGN_PARAMETERS = {
          "campaign_start" => CAMPAIGN_COMMON + %w[pane expected_generation contract profile],
          "campaign_pin" => CAMPAIGN_COMMON + %w[pane expected_generation round_id scope_identity],
          "campaign_begin" => CAMPAIGN_COMMON + %w[pane expected_generation review_id],
          "campaign_status" => CAMPAIGN_COMMON
        }.freeze

        private

        def ordinary_campaign_operation(request, peer, role, deadline, transfer)
          raise ArgumentError, "ordinary campaign control forbids transfer" if transfer
          raise AttemptErrors::EvidenceUnavailable, "ordinary campaign owner is not installed" unless @campaign
          operation, params = request.values_at("operation", "params")
          strict!(params, CAMPAIGN_PARAMETERS.fetch(operation))
          %w[assignment_id attempt_id].each { |key| token!(params.fetch(key)) }
          unless params["head"].is_a?(String) && CandidateTransfer::SHA.match?(params["head"]) &&
              params["candidate_generation"].is_a?(Integer) && params["candidate_generation"].positive?
            raise ArgumentError, "ordinary campaign candidate differs"
          end
          read = operation == "campaign_status"
          if read
            raise ArgumentError, "campaign status mutation must be null" unless request["mutation_id"].nil?
          else
            token!(request.fetch("mutation_id"))
            unless params["expected_generation"].is_a?(Integer) && params["expected_generation"].positive?
              raise ArgumentError, "ordinary campaign generation differs"
            end
          end
          validate_campaign_control!(operation, params)
          with_scope(assignment: params.fetch("assignment_id"), attempt: params.fetch("attempt_id"), deadline: deadline) do
            current = ->(events, commit) { authorize_campaign_control!(request, peer, role, deadline, events, commit) }
            if read
              prefix = @journal.ref_value
              events = result_events(params, prefix)
              current.call(events, prefix)
              value = with_ordinary_campaign(events, prefix, params, current) do |manager, _profiles, _guard|
                selected = ordinary_campaign_selection!(events, prefix)
                campaign_projection(manager.status(selected.fetch("campaign_id")))
              end
              return {data: value.merge("journal_commit" => prefix), replayed: false}
            end
            digest = Atoms::EvidenceDigest.digest("project_id" => @project, "params" => params, "peer_uid" => peer.fetch("uid"))
            @journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: request.fetch("mutation_id"), operation: operation, parameters_digest: digest,
              expected_generation: params.fetch("expected_generation"), with_replay: true, deadline: deadline,
              replay_authorizer: -> { prefix = @journal.ref_value; current.call(result_events(params, prefix), prefix) }) do |events, commit, _generation|
              current.call(events, commit)
              with_ordinary_campaign(events, commit, params, current) do |manager, profiles, guard|
                if operation == "campaign_start"
                  if events.any? { |event| event.dig("payload", "operation") == "campaign_start" }
                    raise AttemptErrors::Conflict, "ordinary producer already has its canonical campaign"
                  end
                  policy = profiles.fetch(params.fetch("profile"))
                  raise AttemptErrors::EvidenceUnavailable, "ordinary campaign profile is disabled" unless policy
                  subject = {"repository" => "local:#{@campaign.repository}", "local_candidate_id" =>
                    "ordinary-#{Atoms::EvidenceDigest.digest(params.slice('assignment_id', 'attempt_id').merge('project_id' => @project))}"}
                  value = manager.start(subject: subject, contract: params.fetch("contract"), profile: params.fetch("profile"), policy: policy)
                  guard.call
                  {events: [], data: {"campaign_id" => value.fetch("campaign_id"), "subject" => subject,
                    "contract_identity" => Digest::SHA256.hexdigest(params.fetch("contract")), "profile" => params.fetch("profile"),
                    "policy" => policy, "producer_origin" => origin_at!(events: events, commit: commit)}}
                elsif operation == "campaign_begin"
                  ordinary_campaign_begin_plan!(manager, profiles, guard, params, events, commit)
                else
                  selected = ordinary_campaign_selection!(events, commit)
                  input = {"attempt_id" => request.fetch("mutation_id"), "round_id" => params.fetch("round_id"),
                    "head" => params.fetch("head"), "base" => selected.fetch("producer_origin").fetch("base_head"),
                    "required_scopes" => selected.fetch("policy").fetch("required_scopes"),
                    "scope_identity" => params.fetch("scope_identity"), "sessions" => [], "dispositions" => []}
                  value = manager.record_round(selected.fetch("campaign_id"), input,
                    expected_campaign: selected.slice("campaign_id", "subject", "contract_identity", "policy"),
                    consumer_profiles: profiles, before_record: guard)
                  guard.call
                  {events: [], data: campaign_projection(value).merge("round_id" => params.fetch("round_id"),
                    "candidate_reference" => candidate_reference_at!(events: events, commit: commit,
                      head: params.fetch("head"), generation: params.fetch("candidate_generation")))}
                end
              end
            end
          end
        rescue Ace::Review::Atoms::CampaignContract::Invalid, KeyError, TypeError => error
          raise AttemptErrors::EvidenceUnavailable, "ordinary canonical campaign is unavailable: #{error.message}"
        end

        def validate_campaign_control!(operation, params)
          case operation
          when "campaign_start"
            token!(params["profile"])
            unless params["contract"].is_a?(String) && params["contract"].encoding == Encoding::UTF_8 &&
                params["contract"].valid_encoding? && !params["contract"].include?("\0") && params["contract"].strip.bytesize.between?(1, 8192)
              raise ArgumentError, "ordinary campaign requirements are unavailable or oversized"
            end
          when "campaign_pin"
            token!(params["round_id"])
            raise ArgumentError, "ordinary campaign scope identity differs" unless params["scope_identity"].is_a?(Hash)
          when "campaign_begin"
            token!(params.fetch("review_id"))
          end
        end

        def authorize_campaign_control!(request, peer, role, deadline, events, commit)
          authorize!(request, peer, role, deadline)
          origin_at!(events: events, commit: commit)
          return if request.fetch("operation") == "campaign_status"
          identity = @admission.identity!(peer: peer, pane: request.fetch("params").fetch("pane"), deadline: deadline)
          if request.fetch("operation") == "campaign_begin"
            assigned = ordinary_review_selection!(events, request.fetch("params").fetch("review_id")).fetch("payload").fetch("data")
            _, reviewer = ordinary_review_origins!(events, commit, assigned, reviewer_running: true)
            observed = @admission.execution!(peer: peer, pane: request.fetch("params").fetch("pane"), head: assigned.fetch("head"), deadline: deadline)
            unless identity.runtime_binding == reviewer.fetch("runtime_binding") && identity.actor == assigned.fetch("reviewer_actor") &&
                peer.fetch("uid") == assigned.fetch("reviewer_uid") && observed.fetch(:identity) == identity
              raise AttemptErrors::UnauthorizedIdentity, "campaign dispatch belongs to its actual selected reviewer"
            end
            return
          end
          registered = registration(request.fetch("params").fetch("assignment_id"), commit: commit)
          unless role == :supervisor && identity.role == "coordinator" &&
              identity.runtime_binding == supervisor_selection(registered, commit).fetch("binding")
            raise AttemptErrors::UnauthorizedIdentity, "ordinary campaign belongs to the current canonical supervisor"
          end
        end

        def with_ordinary_campaign(events, commit, params, current)
          candidate = candidate_at!(events: events, commit: commit, head: params.fetch("head"), generation: params.fetch("candidate_generation"))
          origin = origin_at!(events: events, commit: commit)
          bytes = @journal.bounded_blob(candidate.fetch("bundle_ref"), commit: commit, max_bytes: CandidateTransfer::MAX_BYTES)
          guard = -> { current.call(events, commit); candidate_at!(events: events, commit: commit,
            head: params.fetch("head"), generation: params.fetch("candidate_generation")) }
          @campaign.with(candidate: candidate, bundle: bytes, base: origin.fetch("base_head"), guard: guard) { |*args| yield(*args) }
        end

        def ordinary_campaign_selection!(events, commit)
          selected = events.select { |event| event.dig("payload", "operation") == "campaign_start" }
          unless selected.one? && selected.first.dig("payload", "data", "producer_origin") == origin_at!(events: events, commit: commit)
            raise AttemptErrors::EvidenceUnavailable, "ordinary campaign association is unavailable"
          end
          selected.first.fetch("payload").fetch("data")
        end

        def campaign_projection(value)
          value.slice("campaign_id", "completed_rounds", "clean_streak", "accepted", "outcome", "recorded_complete", "decision", "result_identity")
        end
      end
    end
  end
end
