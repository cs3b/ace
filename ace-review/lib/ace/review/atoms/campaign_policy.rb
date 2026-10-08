# frozen_string_literal: true
require_relative "campaign_contract"

module Ace
  module Review
    module Atoms
      # Exploration budgets are independent of the current-head acceptance gate.
      module CampaignPolicy
        Contract = CampaignContract
        DEFAULTS = {
          "discovery" => {"minimum_rounds" => 2, "clean_rounds" => 1, "maximum_rounds" => 2},
          "delivery" => {"minimum_rounds" => 3, "clean_rounds" => 2, "maximum_rounds" => 5}
        }.transform_values(&:freeze).freeze
        TERMINAL_FAILURES = %w[authentication authorization model_unavailable unclassified].freeze
        TRANSIENT_FAILURES = %w[timeout transport rate_limit unavailable].freeze
        INFRASTRUCTURE_RETRIES = 2

        def self.bounds!(profile:, policy:)
          defaults = DEFAULTS[profile]
          raise Contract::Invalid, "unsupported campaign profile #{profile}" unless defaults
          Contract.object!(policy, "campaign policy")
          result = defaults.merge(policy.slice("minimum_rounds", "clean_rounds", "maximum_rounds"))
          unless result.values.all? { |value| value.is_a?(Integer) && value.positive? } &&
              result["minimum_rounds"] <= result["maximum_rounds"] &&
              result["clean_rounds"] <= result["maximum_rounds"] &&
              result["maximum_rounds"] <= defaults["maximum_rounds"]
            raise Contract::Invalid, "campaign policy conflicts with its finite execution budget"
          end
          if profile == "delivery" &&
              (result["minimum_rounds"] < 3 || result["clean_rounds"] < 2)
            raise Contract::Invalid, "delivery policy cannot weaken its search requirements"
          end
          result.freeze
        end

        def self.next_phase(record:, phase_id:, reason:, route:, additional_rounds:)
          Contract.id!(phase_id, "phase ID")
          Contract.string!(reason, "next phase reason")
          Contract.string!(route, "next phase route")
          unless additional_rounds.is_a?(Integer) && additional_rounds.positive?
            raise Contract::Invalid, "next phase requires an explicit finite positive budget"
          end
          existing = record.fetch("phases").find { |phase| phase["id"] == phase_id }
          if existing
            unless existing.values_at("reason", "route", "maximum_rounds") == [reason, route, additional_rounds]
              raise Contract::Invalid, "conflicting replay of authorized next phase"
            end
            return existing
          end
          {"id" => phase_id, "profile" => record.fetch("profile"), "round_start" => record.fetch("rounds").size,
            "maximum_rounds" => additional_rounds, "reason" => reason, "route" => route}.freeze
        end

        def self.decision(profile:, bounds:, phase_rounds:, completed_rounds:, clean_streak:,
          accepted:, recurrence: false, execution_failure: nil)
          raise Contract::Invalid, "unsupported campaign profile #{profile}" unless DEFAULTS.key?(profile)
          unless [phase_rounds, completed_rounds, clean_streak].all? { |n| n.is_a?(Integer) && n >= 0 } &&
              phase_rounds <= completed_rounds && clean_streak <= completed_rounds && phase_rounds <= bounds.fetch("maximum_rounds") &&
              [true, false].include?(accepted) && [true, false].include?(recurrence)
            raise Contract::Invalid, "campaign counters or acceptance differ"
          end
          converged = profile == "delivery" && completed_rounds >= bounds.fetch("minimum_rounds") &&
            clean_streak >= bounds.fetch("clean_rounds")
          remaining = bounds.fetch("maximum_rounds") - phase_rounds
          outcome, action = if profile == "discovery" && remaining.zero?
            ["discovery_complete", "export_candidate"]
          elsif execution_failure
            ["execution_failed", "resolve_execution_failure"]
          elsif profile == "delivery" && accepted && converged && !recurrence
            ["accepted", "finish"]
          elsif remaining.zero?
            ["needs_escalation", "authorize_next_phase"]
          elsif recurrence
            ["needs_diagnosis", "diagnose_canonical_defect"]
          elsif converged
            ["search_converged", "satisfy_acceptance"]
          else
            ["in_progress", "review"]
          end
          {"profile" => profile, "outcome" => outcome, "next_action" => action,
            "remaining_rounds" => remaining, "phase_rounds" => phase_rounds,
            "search_converged" => converged, "accepted" => outcome == "accepted",
            "execution_failure" => execution_failure}.freeze
        end

        # Severity corrections target the exact observation. A successful fix
        # never retroactively changes the severity of the original round.
        def self.clean_streak(record)
          corrections = record.fetch("assessments").select { |item| item["kind"] == "severity_correction" }
            .to_h { |item| [item.fetch("source_id"), item] }
          rounds = record.fetch("rounds").to_h { |item| [item.fetch("attempt_id"), item] }
          streak = 0
          record.fetch("attempts").each do |attempt|
            blocked = attempt.fetch("assessments").any? do |item|
              correction = corrections[item.fetch("source_id")]
              priority = correction ? correction.fetch("priority") : item.fetch("priority")
              disposition = correction ? correction.fetch("disposition") : item.fetch("disposition")
              item["observed_in_round"] && %w[high critical].include?(priority) && disposition != "invalid"
            end
            streak = 0 if blocked
            if rounds.key?(attempt.fetch("attempt_id"))
              round_observations = record.fetch("attempts").select { |item| attempt["round_id"] ? item["round_id"] == attempt["round_id"] : item["attempt_id"] == attempt["attempt_id"] }
                .flat_map { |item| item.fetch("assessments") }
              round_blocked = round_observations.any? do |item|
                correction = corrections[item.fetch("source_id")]
                priority = correction ? correction.fetch("priority") : item.fetch("priority")
                disposition = correction ? correction.fetch("disposition") : item.fetch("disposition")
                item["observed_in_round"] && %w[high critical].include?(priority) && disposition != "invalid"
              end
              streak = round_blocked ? 0 : streak + 1
            end
          end
          streak
        end

        def self.canonical_findings(record)
          findings = {}
          (record.fetch("inherited_findings") + record.fetch("assessments")).each do |item|
            next if item["kind"] == "repair_attempt"
            id = item.fetch("id")
            prior = findings[id]
            sources = prior ? prior.fetch("sources") : item.fetch("sources", []).dup
            source = item.slice("source_id", "artifact", "source_artifact", "priority", "disposition", "reason")
            sources = sources + [source] unless sources.include?(source)
            findings[id] = item.merge("sources" => sources)
          end
          findings.values
        end

        def self.recurring_blockers(record)
          fixes = {}
          recurring = {}
          observed = []
          record.fetch("assessments").each do |item|
            id = item.fetch("id")
            observation = item.slice("source_id", "artifact")
            fresh_observation = !observed.include?(observation)
            observed << observation if item["observed_in_round"] && fresh_observation
            if item["kind"] == "repair_attempt"
              fixes[id] = item
            elsif %w[resolved invalid].include?(item["disposition"])
              fixes.delete(id)
              recurring.delete(id)
            elsif item["observed_in_round"] && fresh_observation &&
                %w[high critical].include?(item["priority"]) && fixes.key?(id)
              recurring[id] = {"finding_id" => id, "repair_attempt" => fixes.fetch(id), "recurrence" => item}
            end
          end
          recurring.values
        end

        # Entries are the durable before-call reservations, not report imports.
        # An unanswered original call requires resolution, never a fresh retry.
        def self.retry_decision(attempts:, round_id:, scope:, provider:)
          [round_id, scope, provider].each { |value| Contract.string!(value, "execution selection") }
          raise Contract::Invalid, "execution attempts must be an array" unless attempts.is_a?(Array)
          attempts.each { |entry| Contract.object!(entry, "execution attempt") }
          selected = attempts.select do |entry|
            entry.values_at("round_id", "scope", "provider") == [round_id, scope, provider]
          end
          selected.each do |entry|
            unless %w[running uncertain succeeded failed].include?(entry["status"]) &&
                (entry["status"] != "failed" || (TERMINAL_FAILURES + TRANSIENT_FAILURES).include?(entry["failure"]))
              raise Contract::Invalid, "execution attempt disposition differs"
            end
          end
          state = if selected.any? { |entry| %w[running uncertain].include?(entry["status"]) }
            "resolve_original_attempt"
          elsif selected.any? { |entry| entry["status"] == "succeeded" }
            "already_completed"
          elsif selected.any? { |entry| TERMINAL_FAILURES.include?(entry["failure"]) }
            "terminal_failure"
          elsif selected.size >= INFRASTRUCTURE_RETRIES + 1
            "retries_exhausted"
          else
            "execute"
          end
          {"next_action" => state, "execution_attempts" => selected.size,
            "remaining_attempts" => [INFRASTRUCTURE_RETRIES + 1 - selected.size, 0].max}.freeze
        end
      end
    end
  end
end
