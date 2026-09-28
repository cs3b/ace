# frozen_string_literal: true

require "json"
require "open3"
require "ace/git"

module Ace
  module Git
    module Worktree
      module Molecules
        # Resolves PR evidence for candidate branches through the registered
        # forge provider to prove safe merge cleanup.
        #
        # Only confirmed remote merge evidence (:merged) can prove removal;
        # object states (:no_pr, :open, :closed_unmerged) and transport
        # failures (:offline, :authentication_error, :malformed) always
        # retain the candidate. Local ancestry proof is handled by the
        # reporter before this resolver is consulted.
        class CleanupPrResolver
          # @param target [String] base ref the PR must have targeted
          # @param target_sha [String] commit SHA of the target
          # @param offline [Boolean] skip provider evidence entirely
          # @param server_name [String, nil] explicit server selection
          # @param use_default [Boolean] resolve the configured default server
          # @param remote_name [String, nil] remote used for fallback resolution
          # @param timeout [Integer, nil] provider timeout
          # @param runner [Proc, nil] injectable provider runner (tests)
          def initialize(target:, target_sha:, offline: false, server_name: nil, use_default: false,
            remote_name: nil, timeout: nil, runner: nil)
            @target = target
            @target_sha = target_sha
            @offline = offline
            @selection = {server_name: server_name, use_default: use_default, remote_name: remote_name}
            @timeout = timeout
            @runner = runner
          end

          # @return [Ace::Git::ResolvedServer, nil] the server resolved for
          #   provider evidence; nil when unresolvable (local proof only)
          def resolved_server
            resolve_provider
            @resolved_server
          end

          # Classify a candidate branch with provider PR evidence.
          #
          # @param branch [String] the branch name (e.g. "feature")
          # @param candidate_sha [String] the commit SHA of the candidate
          # @return [Hash] proof classification; :status is one of
          #   Ace::Git::CLEANUP_PROOF_STATUSES
          def classify(branch, candidate_sha)
            return unproven_result(:no_pr, "provider_disabled") if @offline

            evidence = fetch_merged_evidence(branch)
            return failure_result(evidence) if evidence.is_a?(Hash) # transport failure marker

            return unproven_result(:no_pr) unless evidence
            return unproven_result(:open) if evidence.state == :open
            return unproven_result(:closed_unmerged) if evidence.state == :closed
            return unproven_result(:no_pr, "state_unavailable") unless evidence.state == :merged
            return unproven_result(:merged, "merge_commit_unavailable") unless evidence.merge_commit_sha
            return unproven_result(:merged, "merge_commit_unreachable") unless ancestor?(evidence.merge_commit_sha, @target_sha)

            merge_commit_sha = evidence.merge_commit_sha
            pr_head_sha = evidence.head_sha

            if candidate_sha == pr_head_sha
              proof_result(evidence, "exact_merged_pr_head", candidate_sha, pr_head_sha, merge_commit_sha)
            elsif patch_equivalent?(candidate_sha, merge_commit_sha)
              proof_result(evidence, "stable_patch_equivalence", candidate_sha, pr_head_sha, merge_commit_sha)
            else
              {
                status: :merged,
                proof: nil,
                pr: evidence.number,
                pr_url: evidence.url,
                candidate_head: candidate_sha,
                merged_head: pr_head_sha,
                merge_commit: merge_commit_sha,
                target_reachable: true,
                provider_status: "available",
                action: "retain",
                retention_reason: "patch_mismatch"
              }
            end
          end

          private

          # Fetch the merged PR evidence for a branch, or a failure marker
          # hash {:failure_status => ...} on classified transport failures.
          def fetch_merged_evidence(branch)
            provider = resolve_provider
            return {failure_status: :offline} unless provider

            provider.pull_request_for_branch(branch: branch)
          rescue Ace::Git::ProviderAuthenticationError
            {failure_status: :authentication_error}
          rescue Ace::Git::ProviderMalformedOutputError
            {failure_status: :malformed}
          rescue Ace::Git::Error
            {failure_status: :offline}
          end

          # Resolve the provider lazily, once per resolver. Unresolvable
          # server selection (no config, ambiguous remote, missing provider)
          # means no provider evidence is available.
          def resolve_provider
            return @provider if defined?(@provider)

            @provider = begin
              server = Ace::Git::ServerRegistry.resolve_for(**@selection)
              @resolved_server = server
              Ace::Git::Providers.for(server, timeout: @timeout, runner: @runner)
            rescue Ace::Git::Error
              @resolved_server = nil
              nil
            end
          end

          def proof_result(evidence, proof, candidate_sha, pr_head_sha, merge_commit_sha)
            {
              status: :merged,
              proof: proof,
              pr: evidence.number,
              pr_url: evidence.url,
              candidate_head: candidate_sha,
              merged_head: pr_head_sha,
              merge_commit: merge_commit_sha,
              target_reachable: true,
              provider_status: "available",
              action: "remove",
              retention_reason: nil
            }
          end

          def unproven_result(status, reason = "ancestry_unproven")
            {
              status: status,
              proof: nil,
              pr: nil,
              pr_url: nil,
              candidate_head: nil,
              merged_head: nil,
              merge_commit: nil,
              target_reachable: "unknown",
              provider_status: "available",
              action: "retain",
              retention_reason: reason
            }
          end

          def failure_result(marker)
            status = marker[:failure_status]
            {
              status: status,
              proof: nil,
              pr: nil,
              pr_url: nil,
              candidate_head: nil,
              merged_head: nil,
              merge_commit: nil,
              target_reachable: "unknown",
              provider_status: status.to_s,
              action: "retain",
              retention_reason: "provider_evidence_unavailable"
            }
          end

          def ancestor?(candidate, target)
            _out, status = Open3.capture2("git", "merge-base", "--is-ancestor", candidate, target)
            status.success?
          end

          def patch_equivalent?(candidate_sha, merge_commit_sha)
            # 1. Candidate patch inventory
            # We want the diff between the candidate's merge-base with target, and the candidate itself
            base, status = Open3.capture2("git", "merge-base", candidate_sha, @target_sha)
            return false unless status.success?
            base = base.strip

            # Candidate inventory: path, type, mode changes
            cand_inv = tree_diff_inventory(base, candidate_sha)
            return false unless cand_inv

            # 2. Merged commit patch inventory
            # We want the diff between the merge commit's first parent, and the merge commit itself
            mc_inv = tree_diff_inventory("#{merge_commit_sha}^1", merge_commit_sha)
            return false unless mc_inv

            cand_inv == mc_inv
          end

          def tree_diff_inventory(tree_a, tree_b)
            # git diff-tree -r raw mode carries exact mode and type information
            # :100644 100644 e69de29... 000000... M  file
            out, status = Open3.capture2("git", "diff-tree", "-r", "--no-commit-id", tree_a, tree_b)
            return nil unless status.success?

            inventory = {}
            out.each_line do |line|
              # Format: :src_mode dst_mode src_sha dst_sha status\tpath
              parts = line.strip.split("\t", 2)
              next if parts.length < 2

              meta = parts[0].split(" ")
              path = parts[1]

              inventory[path] = {
                mode: meta[1],
                sha: meta[3],
                status: meta[4][0] # handle R100 etc by taking first char
              }
            end

            inventory
          end
        end
      end
    end
  end
end
