# frozen_string_literal: true

require "open3"

module Ace
  module Lab
    module Molecules
      # The fixed merge method executor (spec 8x3.t.xz9.4, merge-method
      # contract). The closed request schema admits literal `method=merge`;
      # the installed executor gives that method FAST-FORWARD-ONLY semantics:
      # the candidate head must be a descendant of the current base head.
      # A non-fast-forwardable candidate is NOT merged silently and never
      # falls back to a merge commit — it reports `:non_fast_forward` so the
      # receiver answers in the moved-target/needs-rebase refusal family.
      # The mutation itself is one atomic compare-and-swap on the base ref
      # (`git update-ref <base> <candidate> <expected>`), so concurrent
      # writers can never both move the ref: the loser provably performed
      # no effect. Under this strategy the resulting base head equals the
      # candidate head, and the receipt joins `merge_commit ==
      # resulting_target_head == merged_candidate_head` — that join is the
      # receipt's fast-forward proof. Any future non-ff strategy is a
      # separate reviewed contract extension, never implicit.
      class OrdinaryFfMerge
        STRATEGY = "ff"

        Result = Struct.new(:outcome, :resulting_head, :previous_head, :reason, keyword_init: true)

        def initialize(repo_path:, base_ref:)
          unless repo_path.is_a?(String) && repo_path.start_with?("/") &&
              base_ref.is_a?(String) && base_ref.start_with?("refs/")
            raise ArgumentError, "ordinary ff merge needs an absolute repo path and a full base ref"
          end
          @repo_path = repo_path
          @base_ref = base_ref
        end

        def base_head
          out, stderr, status = git("rev-parse", @base_ref)
          return out.strip if status.success?
          raise GitUnavailable, "base ref #{@base_ref} is unreadable: #{stderr.strip[0, 200]}"
        end

        def candidate_commit?(sha)
          git("cat-file", "-e", "#{sha}^{commit}").last.success?
        end

        # True only when the candidate is a descendant of (or equal to) the
        # current base head — the fast-forward precondition.
        def fast_forwardable?(candidate_head)
          git("merge-base", "--is-ancestor", @base_ref, candidate_head).last.success?
        end

        # The single effect: one compare-and-swap ref update. Returns a
        # Result with outcome `:merged`, `:already_merged`, or `:race_lost`
        # (the expected head moved before the swap — provably no effect from
        # this invocation). Raises GitUnavailable when git itself fails.
        def merge!(candidate_head, expected_head)
          current = base_head
          return Result.new(outcome: :already_merged, resulting_head: current,
            previous_head: current, reason: nil) if current == candidate_head
          unless current == expected_head
            return Result.new(outcome: :race_lost, resulting_head: current,
              previous_head: current, reason: "base head moved before the swap")
          end
          out, stderr, status = git("update-ref", @base_ref, candidate_head, expected_head)
          unless status.success?
            return Result.new(outcome: :race_lost, resulting_head: base_head,
              previous_head: base_head, reason: "compare-and-swap lost: #{stderr.strip[0, 200]}")
          end
          Result.new(outcome: :merged, resulting_head: candidate_head,
            previous_head: expected_head, reason: nil)
        end

        class GitUnavailable < ::StandardError; end

        private

        def git(*argv)
          Open3.capture3("git", *argv, chdir: @repo_path)
        rescue Errno::ENOENT => e
          raise GitUnavailable, "git is unavailable: #{e.class}"
        end
      end
    end
  end
end
