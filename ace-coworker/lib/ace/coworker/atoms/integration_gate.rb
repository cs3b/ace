# frozen_string_literal: true

module Ace
  module Coworker
    module Atoms
      # Pure pre-merge integration gate (8xg.t.sbz.4.3 / contract, HEAD
      # binding per 8xs.t.pu0.8): the integrator merges only a candidate
      # whose (a) dependencies are integrated predecessors, (b) current
      # head matches the reviewed head (no drift), (c) tests were
      # executed, passed, AND BOUND TO THE EXACT CANDIDATE HEAD (bare
      # executed/passed without a head covers nothing), (d) a fresh
      # independent review verdict accepts the EXACT candidate head, and
      # (e) the formal approval — when required — also names this head
      # and was given by a DIFFERENT account than the author. Any
      # unknown or contradictory fact is a blocking reason - a code
      # change or rebase after tests or review invalidates those bases
      # for the old candidate; uncertainty must be verified against the
      # real worktree/reports, never guessed or retried blind. Explicit
      # :blocked outcome with reasons, never an exception. No IO, no
      # writes, no merges: the gate decides readiness only; the role
      # drives git/ace-git (the merge adapter's expected-head condition
      # refuses a candidate that moved between gate and merge).
      module IntegrationGate
        ACCEPT_VERDICTS = %w[accept].freeze

        # @param input [Hash] string-keyed facts:
        #   "candidate_head" => String (current head of the candidate)
        #   "review" => {"head" => String reviewed head, "verdict" => String}
        #   "tests" => {"executed" => bool, "passed" => bool,
        #               "head" => String head the test run covered}
        #   "approval" => {"head" => String, "by" => String account} (a
        #     nil/empty approval skips the formal-approval check; lanes
        #     that require it must supply it)
        #   "author" => String candidate author account (optional)
        #   "dependencies" => {name => bool (integrated predecessor)}
        # @return [Hash] {verdict: :ready | :blocked, reasons: [String],
        #   failed_checks: [:dependencies|:candidate|:review|:tests|:approval|:input]}
        def self.evaluate(input)
          unless input.is_a?(Hash) && input.keys.all? { |k| k.is_a?(String) }
            return {verdict: :blocked,
                    reasons: ["gate input must be a Hash with string keys, got #{input.class}"],
                    failed_checks: [:input]}
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
          elsif !candidate_head.empty? && review_head.downcase != candidate_head.downcase
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
          tests_head = str(tests["head"])
          if tests_head.empty?
            reasons << "test evidence not bound to a candidate head: executed/passed covers no " \
              "verifiable candidate - re-run the tests on the current head and record it"
            failed << :tests
          elsif !candidate_head.empty? && tests_head.downcase != candidate_head.downcase
            reasons << "stale test evidence: candidate #{candidate_head} is not the tested head #{tests_head}"
            failed << :tests
          end

          approval = hash(input["approval"])
          unless approval.empty?
            approval_head = str(approval["head"])
            approved_by = str(approval["by"])
            if approval_head.empty?
              reasons << "formal approval not bound to a candidate head: the approval covers no " \
                "verifiable candidate"
              failed << :approval
            elsif !candidate_head.empty? && approval_head.downcase != candidate_head.downcase
              reasons << "stale formal approval: candidate #{candidate_head} is not the approved " \
                "head #{approval_head}"
              failed << :approval
            end
            author = str(input["author"])
            if !approved_by.empty? && !author.empty? && approved_by.downcase == author.downcase
              reasons << "formal approval by the author's own account '#{approved_by}': the formal " \
                "approver must be a different configured lane account"
              failed << :approval
            end
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
