# frozen_string_literal: true
require_relative "campaign_policy"

module Ace
  module Review
    module Atoms
      # Historical search progress is independent of current evidence currency.
      module CampaignProjection
        def self.build(record)
          rounds = record.fetch("rounds")
          findings = CampaignPolicy.canonical_findings(record)
          open = findings.select { |finding| %w[open reopened].include?(finding["disposition"]) }
          policy = record.fetch("policy")
          attempts = record.fetch("attempts")
          streak = CampaignPolicy.clean_streak(record)
          phase = record.fetch("phases").last
          bounds = record.fetch("bounds").merge("maximum_rounds" => phase.fetch("maximum_rounds"))
          decision = CampaignPolicy.decision(profile: record.fetch("profile"), bounds: bounds,
            phase_rounds: rounds.size - phase.fetch("round_start"), completed_rounds: rounds.size,
            clean_streak: streak, accepted: false, recurrence: !CampaignPolicy.recurring_blockers(record).empty?)
          sessions = attempts.flat_map { |attempt| attempt.fetch("sessions") }.uniq { |session| session["path"] }
          {"campaign_id" => record.fetch("id"), "subject" => record.fetch("subject"),
           "contract_identity" => record.fetch("contract_identity"), "effective_policy" => policy,
           "predecessor" => record["predecessor"], "successor_reason" => record["successor_reason"],
           "required_scopes" => policy.fetch("required_scopes"), "completed_rounds" => rounds.size,
           "clean_streak" => streak, "open_findings" => open, "findings" => findings,
           "search_converged" => decision.fetch("search_converged"),
           "profile" => record.fetch("profile"), "phase" => phase, "phases" => record.fetch("phases"),
           "bounds" => record.fetch("bounds"), "decision" => decision,
           "execution_attempts" => record.fetch("execution_attempts"),
           "recurring_blockers" => CampaignPolicy.recurring_blockers(record),
           "counters" => {"recording_attempts" => attempts.size, "execution_attempts" => record.fetch("execution_attempts").size,
             "provider_calls" => sessions.sum { |s| s.fetch("provider_calls") },
             "report_files" => sessions.sum { |s| s.fetch("report_files") }, "completed_rounds" => rounds.size},
           "rounds" => rounds, "attempts" => attempts, "head_transitions" => record.fetch("head_transitions")}
        end
      end
    end
  end
end
