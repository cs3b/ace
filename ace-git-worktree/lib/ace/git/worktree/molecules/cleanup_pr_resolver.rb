# frozen_string_literal: true

require "json"
require "open3"
require "ace/git/molecules/pr_metadata_fetcher"

module Ace
  module Git
    module Worktree
      module Molecules
        # Resolves PR evidence for candidate branches to prove safe squash-merge cleanup.
        class CleanupPrResolver
          def initialize(target:, target_sha:, offline: false)
            @target = target
            @target_sha = target_sha
            @offline = offline
            
            # Cache gh availability to avoid repeated checks
            @gh_available = Ace::Git::Molecules::PrMetadataFetcher.gh_installed? && 
                            Ace::Git::Molecules::PrMetadataFetcher.gh_authenticated?
          end

          # Classify a candidate branch with GitHub PR evidence.
          #
          # @param branch [String] The branch name (e.g. "feature")
          # @param candidate_sha [String] The commit SHA of the candidate
          # @return [Hash] Proof classification result
          def classify(branch, candidate_sha)
            return offline_result unless @gh_available && !@offline

            prs = fetch_merged_prs_for_branch(branch)
            return unproven_result if prs.nil? || prs.empty?

            # Find a PR that targets the configured base and is actually reachable
            valid_pr = prs.find do |pr|
              pr["baseRefName"] == @target && 
              pr["state"] == "MERGED" && 
              pr["mergeCommit"] && 
              pr["mergeCommit"]["oid"] &&
              ancestor?(pr["mergeCommit"]["oid"], @target_sha)
            end

            return ambiguous_result(prs) if prs.length > 1 && !valid_pr
            return unproven_result unless valid_pr

            merge_commit_sha = valid_pr["mergeCommit"]["oid"]
            pr_head_sha = valid_pr["headRefOid"]

            if candidate_sha == pr_head_sha
              {
                proof: "exact_merged_pr_head",
                pr: valid_pr["number"],
                candidate_head: candidate_sha,
                merged_head: pr_head_sha,
                merge_commit: merge_commit_sha,
                target_reachable: true,
                path_type_mode_match: true,
                provider_status: "available",
                action: "remove"
              }
            elsif patch_equivalent?(candidate_sha, merge_commit_sha)
              {
                proof: "stable_patch_equivalence",
                pr: valid_pr["number"],
                candidate_head: candidate_sha,
                merged_head: pr_head_sha,
                merge_commit: merge_commit_sha,
                target_reachable: true,
                path_type_mode_match: true,
                provider_status: "available",
                action: "remove"
              }
            else
              {
                proof: "none",
                pr: valid_pr["number"],
                candidate_head: candidate_sha,
                merged_head: pr_head_sha,
                merge_commit: merge_commit_sha,
                target_reachable: true,
                path_type_mode_match: false,
                provider_status: "available",
                action: "retain",
                retention_reason: "patch_mismatch"
              }
            end
          rescue Ace::Git::GhNotInstalledError, Ace::Git::GhAuthenticationError, Ace::Git::TimeoutError
            # Provider failure degradation
            offline_result("unavailable")
          end

          private

          def fetch_merged_prs_for_branch(branch)
            # Use `gh pr list --head <branch> --state merged` to find the exact PR
            cmd = [
              "gh", "pr", "list", "--state", "merged", "--head", branch,
              "--json", "number,state,headRefOid,mergeCommit,baseRefName"
            ]
            
            # Using Open3 directly to avoid circular dependencies if we don't want to augment ace-git too heavily for just this
            # but we can rely on LC_ALL=C for safety.
            env = {"LC_ALL" => "C"}
            out, err, status = Open3.capture3(env, *cmd)
            
            return nil unless status.success?
            
            JSON.parse(out)
          rescue JSON::ParserError, Errno::ENOENT
            nil
          end

          def ancestor?(candidate, target)
            out, status = Open3.capture2("git", "merge-base", "--is-ancestor", candidate, target)
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
            # git diff-tree -r --name-status or raw mode
            # using raw mode to get exact mode and type
            # :100644 100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 0000000000000000000000000000000000000000 M  file
            out, status = Open3.capture2("git", "diff-tree", "-r", "--no-commit-id", tree_a, tree_b)
            return nil unless status.success?

            inventory = {}
            out.each_line do |line|
              # Format: :src_mode dst_mode src_sha dst_sha status\tpath
              parts = line.strip.split("\t", 2)
              meta = parts[0].split(" ")
              path = parts[1]
              
              dst_mode = meta[1]
              dst_sha = meta[3]
              status_char = meta[4]
              
              inventory[path] = {
                mode: dst_mode,
                sha: dst_sha,
                status: status_char[0] # handle R100 etc by taking first char
              }
            end
            
            inventory
          end

          def offline_result(status = "offline")
            {
              proof: "none",
              pr: nil,
              candidate_head: nil,
              merged_head: nil,
              merge_commit: nil,
              target_reachable: "unknown",
              path_type_mode_match: "unknown",
              provider_status: status,
              action: "retain",
              retention_reason: "ancestry_unproven"
            }
          end

          def unproven_result
            {
              proof: "none",
              pr: nil,
              candidate_head: nil,
              merged_head: nil,
              merge_commit: nil,
              target_reachable: "unknown",
              path_type_mode_match: "unknown",
              provider_status: "available",
              action: "retain",
              retention_reason: "ancestry_unproven"
            }
          end

          def ambiguous_result(prs)
            {
              proof: "none",
              pr: nil,
              candidate_head: nil,
              merged_head: nil,
              merge_commit: nil,
              target_reachable: "unknown",
              path_type_mode_match: "unknown",
              provider_status: "ambiguous",
              action: "retain",
              retention_reason: "ambiguous_prs"
            }
          end
        end
      end
    end
  end
end
