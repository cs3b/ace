# frozen_string_literal: true

module Ace
  module Coworker
    module Atoms
      # Pure pre-merge integration gate (8xg.t.sbz.4.3 / contract): the
      # integrator merges only a candidate whose (a) dependencies are
      # integrated predecessors, (b) current head matches the reviewed
      # head (no drift), (c) tests were executed and passed, and (d) a
      # fresh independent review verdict accepts the EXACT candidate
      # head. Any unknown or contradictory fact is a blocking reason -
      # uncertainty must be verified against the real worktree/reports,
      # never guessed or retried blind. Explicit :blocked outcome with
      # reasons, never an exception. No IO, no writes, no merges: the
      # gate decides readiness only; the role drives git/ace-git.
      module IntegrationGate
        ACCEPT_VERDICTS = %w[accept].freeze

        # @param input [Hash] string-keyed facts:
        #   "candidate_head" => String (current head of the candidate)
        #   "review" => {"head" => String reviewed head, "verdict" => String}
        #   "tests" => {"executed" => bool, "passed" => bool}
        #   "dependencies" => {name => bool (integrated predecessor)}
        # @return [Hash] {verdict: :ready | :blocked, reasons: [String],
        #   failed_checks: [:dependencies|:candidate|:review|:tests]}
        def self.evaluate(input)
          unless input.is_a?(Hash) && input.keys.all? { |k| k.is_a?(String) }
            return {verdict: :blocked, reasons: ["gate input must be a Hash with string keys, got #{input.class}"],
                    failed_checks: [:candidate]}
          end

          reasons = []
          failed = []

          candidate_head = str(input["candidate_head"])
          if candidate_head.empty?
            reasons << "candidate head unknown: verify the actual worktree head instead of guessing"
            failed << :candidate
          end

          dependencies = hash(input["dependencies"])
          unsatisfied = dependencies.reject { |_, integrated| integrated == true }
          unless unsatisfied.empty?
            reasons << "dependencies not integrated: #{unsatisfied.keys.sort.join(', ')}"
            failed << :dependencies
          end

          review = hash(input["review"])
          review_head = str(review["head"])
          verdict = str(review["verdict"]).downcase
          if review_head.empty?
            reasons << "review evidence missing: no reviewed head recorded - the verdict covers no verifiable candidate"
            failed << :review
          elsif !candidate_head.empty? && review_head != candidate_head
            reasons << "stale review: candidate #{candidate_head} is not the reviewed head #{review_head}"
            failed << :review
          end
          unless ACCEPT_VERDICTS.include?(verdict)
            reasons << "review verdict is '#{verdict.empty? ? 'unknown' : verdict}', not accept"
            failed << :review
          end

          tests = hash(input["tests"])
          unless tests["executed"] == true
            reasons << "tests not executed: real executed-test evidence is required before merge"
            failed << :tests
          end
          unless tests["passed"] == true
            reasons << "tests not passing: executed tests failed or their outcome is unknown"
            failed << :tests
          end

          {verdict: reasons.empty? ? :ready : :blocked,
           reasons: reasons, failed_checks: failed.uniq}
        end

        class << self
          private

          def str(value)
            value.to_s.strip
          end

          def hash(value)
            value.is_a?(Hash) ? value : {}
          end
        end
      end
    end
  end
end
