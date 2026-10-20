# frozen_string_literal: true

require "set"

module Ace
  module Coworker
    module Atoms
      # Pure 3/2/10 review-convergence rule (8xg.t.sbz.4.2 / contract):
      # minimum 3 full rounds, the last 2 consecutive completed full rounds
      # without confirmed High/Critical, and no earlier unresolved
      # High/Critical; maximum 10 full rounds - satisfying the rule at
      # round 10 succeeds, otherwise the verdict is :escalate (an explicit
      # outcome for the reviewer role to route via ace-hitl, never an
      # exception). Delta/fix-diff rounds never advance the counters; the
      # caller records a delta round that still reviews every changed part
      # as type "full" (reviewer.wf.md rule 6). Interrupted/aborted rounds
      # are not clean. No IO, no writes.
      module RoundRule
        MIN_FULL_ROUNDS = 3
        MAX_FULL_ROUNDS = 10
        REQUIRED_CLEAN_STREAK = 2
        HIGH_SEVERITIES = %w[high critical].freeze

        # @param records [Array<Hash>] ordered round records, each with:
        #   "type" => "full" | "delta",
        #   "status" => "completed" | "aborted",
        #   "confirmed" => Array<{"id" => String, "severity" => String}>,
        #   "resolved" => Array<String> finding ids resolved by this round
        # @return [Hash] {verdict: :continue | :accept | :escalate,
        #   full_rounds:, completed_full_rounds:, consecutive_clean:,
        #   unresolved_high_critical: [ids]}
        def self.evaluate(records)
          records = Array(records)
          resolved_ids = records.flat_map { |r| list(r["resolved"]) }.to_set
          unresolved = confirmed_high(records).reject { |id| resolved_ids.include?(id) }.uniq

          full_rounds = records.count { |r| full?(r) }
          completed_full = records.count { |r| full?(r) && completed?(r) }
          streak = clean_streak(records)

          # The 10-round cap is terminal: acceptance is possible only at
          # or before round 10, so a satisfying state that materializes
          # at round 11+ escalates instead of flipping back to :accept.
          acceptable = completed_full >= MIN_FULL_ROUNDS &&
                       streak >= REQUIRED_CLEAN_STREAK && unresolved.empty? &&
                       full_rounds <= MAX_FULL_ROUNDS
          verdict = if acceptable
                      :accept
                    elsif full_rounds >= MAX_FULL_ROUNDS
                      :escalate
                    else
                      :continue
                    end

          {verdict: verdict, full_rounds: full_rounds,
           completed_full_rounds: completed_full, consecutive_clean: streak,
           unresolved_high_critical: unresolved}
        end

        # A record is a clean round only when it is a completed full round
        # with no confirmed High/Critical finding; aborted full rounds and
        # full rounds with High/Critical reset the streak. Delta rounds
        # never advance the streak, but a delta that CONFIRMS a
        # High/Critical finding breaks it — even when the same delta (or a
        # later fix delta) resolves the finding: code that just produced a
        # High defect needs renewed clean full-round evidence, never the
        # stale streak from before the finding. Deltas without a confirmed
        # High/Critical (e.g. a pure fix delta) stay transparent.
        def self.clean_streak(records)
          streak = 0
          records.reverse_each do |record|
            unless full?(record)
              break if confirmed_high([record]).any?

              next
            end

            break unless completed?(record) && confirmed_high([record]).empty?

            streak += 1
          end
          streak
        end

        def self.confirmed_high(records)
          records.flat_map { |r| list(r["confirmed"]) }
                 .select { |f| HIGH_SEVERITIES.include?(f["severity"].to_s.downcase) }
                 .map { |f| f["id"].to_s }
        end

        def self.full?(record)
          record["type"].to_s == "full"
        end

        def self.completed?(record)
          record["status"].to_s == "completed"
        end

        def self.list(value)
          Array(value)
        end
      end
    end
  end
end
