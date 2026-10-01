# frozen_string_literal: true

module Ace
  module Review
    module Atoms
      # Historical search progress is independent of current evidence currency.
      module CampaignProjection
        def self.build(record)
          rounds = record.fetch("rounds")
          findings = record.fetch("inherited_findings").to_h { |finding| [finding.fetch("id"), finding] }
          record.fetch("assessments").each { |finding| findings[finding.fetch("id")] = finding }
          open = findings.values.select { |finding| %w[open reopened].include?(finding["disposition"]) }
          streak = rounds.reverse.take_while { |round| round["clean"] }.size
          policy = record.fetch("policy")
          attempts = record.fetch("attempts")
          sessions = attempts.flat_map { |attempt| attempt.fetch("sessions") }.uniq { |session| session["path"] }
          {"campaign_id" => record.fetch("id"), "subject" => record.fetch("subject"),
           "contract_identity" => record.fetch("contract_identity"), "effective_policy" => policy,
           "predecessor" => record["predecessor"], "successor_reason" => record["successor_reason"],
           "required_scopes" => policy.fetch("required_scopes"), "completed_rounds" => rounds.size,
           "clean_streak" => streak, "open_findings" => open, "findings" => findings.values,
           "search_converged" => rounds.size >= policy.fetch("minimum_rounds") &&
             streak >= policy.fetch("clean_rounds"),
           "counters" => {"recording_attempts" => attempts.size,
             "provider_calls" => sessions.sum { |s| s.fetch("provider_calls") },
             "report_files" => sessions.sum { |s| s.fetch("report_files") }, "completed_rounds" => rounds.size},
           "rounds" => rounds, "attempts" => attempts, "head_transitions" => record.fetch("head_transitions")}
        end
      end
    end
  end
end
