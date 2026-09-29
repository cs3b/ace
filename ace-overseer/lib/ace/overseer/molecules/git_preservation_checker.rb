# frozen_string_literal: true

require "open3"

module Ace
  module Overseer
    module Molecules
      # Executes Git preservation proofs for prune candidates.
      #
      # A candidate is preserved only through an executed identity:
      #
      # 1. Accepted ancestry — the candidate HEAD is contained in the current
      #    tip of a distinct surviving accepted base branch.
      # 2. Declared destination — a verified manifest record whose
      #    destination branch accepted both the declared base and head, and
      #    whose content matches by full-tree equality or by an exact
      #    path-by-path transition (modes, symlinks, binary content) between
      #    separate source and destination bases. Patch-range proof requires
      #    the independently recorded creation baseline (qjl base_head); a
      #    missing or mismatching baseline disables it. The baseline itself
      #    must be preserved on a surviving accepted ref.
      #
      # Everything else — missing, failed or ambiguous evidence — blocks.
      # All Git access is argv-based; no refs are fetched into any repo.
      class GitPreservationChecker
        DEFAULT_GIT_RUNNER = ->(repo, *args) { Open3.capture3("git", "-C", repo, *args) }

        attr_reader :git_runner

        def initialize(git_runner: DEFAULT_GIT_RUNNER)
          @git_runner = git_runner
        end

        # The surviving accepted base of the repository: the main checkout's
        # current branch and its live tip.
        #
        # @param repo_root [String] Common repository root
        # @return [Hash, nil] `{branch:, head:}` or nil when unresolvable
        def accepted_base_for(repo_root)
          branch = rev_parse(repo_root, "--abbrev-ref", "HEAD")
          return nil if branch.nil? || branch.empty? || branch == "HEAD"

          head = rev_parse(repo_root, "--verify", "HEAD")
          return nil if head.nil?

          {branch: branch, head: head}
        end

        # The common repository of a worktree candidate.
        #
        # @param worktree_path [String]
        # @return [String, nil] Absolute repository root or nil
        def source_repo_for(worktree_path)
          common_dir = rev_parse(worktree_path, "--path-format=absolute", "--git-common-dir")
          return nil if common_dir.nil? || common_dir.empty?

          File.dirname(common_dir)
        end

        # Prove preservation for one candidate.
        #
        # @param worktree_path [String] Candidate worktree
        # @param accepted_base [Hash, nil] `{branch:, head:}` surviving base
        # @param manifest_record [PreservationManifest::Record, nil] Declared
        #   destination (a claim; verified here)
        # @param recorded_base [String, nil] Independently recorded creation
        #   baseline (attempt base_head), outside the manifest
        # @param candidate_branch [String, nil] The candidate's own branch,
        #   scheduled for deletion with the worktree
        # @return [Models::PreservationProof]
        def proof(worktree_path:, accepted_base:, manifest_record: nil, recorded_base: nil, candidate_branch: nil)
          live_head = rev_parse(worktree_path, "--verify", "HEAD")
          return blocked("cannot resolve candidate HEAD") if live_head.nil?

          if accepted_base && accepted_base[:head] == live_head
            return blocked("candidate HEAD equals the accepted base tip; no distinct work to preserve")
          end

          if ancestry?(worktree_path, live_head, accepted_base[:head])
            return Models::PreservationProof.preserved(:accepted_ancestor, head: live_head)
          end
          return blocked("HEAD #{live_head[0, 12]} is not contained in accepted base " \
            "#{accepted_base[:branch]} (#{accepted_base[:head][0, 12]}) and no destination is declared") if manifest_record.nil?

          proof_via_destination(worktree_path, live_head, accepted_base, manifest_record, recorded_base, candidate_branch)
        end

        # Prove preservation for a static identity that has no local
        # checkout (e.g. a Lab Work documenting repo/head/branch): the head
        # must be contained in the current tip of the surviving accepted
        # base branch.
        #
        # @param repo [String] Repository root
        # @param head [String] Commit whose preservation is in question
        # @param accepted_base [Hash] `{branch:, head:}` surviving base
        # @return [Models::PreservationProof]
        def ancestry_proof(repo:, head:, accepted_base:)
          if accepted_base.nil? || head.to_s.empty?
            return blocked("cannot resolve an accepted surviving base to prove preservation")
          end

          if ancestry?(repo, head, accepted_base[:head])
            Models::PreservationProof.preserved(:accepted_ancestor)
          else
            blocked("documented head #{head[0, 12]} is not contained in accepted base #{accepted_base[:branch]}")
          end
        end

        private

        def proof_via_destination(worktree_path, live_head, accepted_base, record, recorded_base, candidate_branch)
          identity_failure = verify_source_identity(worktree_path, live_head, record)
          return identity_failure if identity_failure

          destination_failure = verify_destination_survival(record, candidate_branch)
          return destination_failure if destination_failure

          acceptance_failure = verify_destination_acceptance(record)
          return acceptance_failure if acceptance_failure

          tree_proof = tree_equality_proof(record)
          return tree_proof if tree_proof&.preserved?

          unless patch_proof_allowed?(record, recorded_base)
            if recorded_base.nil?
              return blocked("patch-range proof is disabled: no independently recorded creation baseline " \
                "(attempt base_head) is available to authorize the declared source range")
            end

            return blocked("declared source_base does not match the recorded creation baseline " \
              "#{recorded_base[0, 12]}")
          end

          range_failure = verify_range(record)
          return range_failure if range_failure

          unless ancestry?(record.source_repo, record.resolved_source_base, accepted_base[:head])
            return blocked("declared source baseline #{record.source_base[0, 12]} itself is not preserved on " \
              "accepted base #{accepted_base[:branch]}; patch-range proof cannot discard it")
          end

          transition_proof(record)
        end

        # The manifest is only a claim: the declared source identity must
        # match the candidate as it exists right now.
        def verify_source_identity(worktree_path, live_head, record)
          actual_repo = source_repo_for(worktree_path)
          if actual_repo.nil? || !same_path?(actual_repo, record.source_repo)
            return blocked("declared source_repo #{record.source_repo} is not the candidate's common repository")
          end

          if record.resolved_source_head != live_head
            return blocked("declared source_head #{record.source_head[0, 12]} does not match the candidate's " \
              "current HEAD #{live_head[0, 12]}")
          end

          nil
        end

        # @return [Models::PreservationProof, nil] Proof when trees match
        def tree_equality_proof(record)
          source_tree = rev_parse(record.source_repo, "--verify", "#{record.resolved_source_head}^{tree}")
          destination_tree = rev_parse(record.destination_repo, "--verify", "#{record.resolved_destination_head}^{tree}")
          if source_tree.nil? || destination_tree.nil?
            return blocked("cannot resolve source/destination trees for tree comparison")
          end

          if source_tree == destination_tree
            Models::PreservationProof.preserved(:tree_equality, head: record.resolved_source_head)
          end
        end

        def patch_proof_allowed?(record, recorded_base)
          return false if recorded_base.nil?

          recorded_base == record.resolved_source_base
        end

        # A destination that IS the candidate's own branch ref is scheduled
        # for deletion with the worktree and cannot survive as the place the
        # work was preserved. Identity is by ref name, not tip: two distinct
        # refs may legitimately point at the same commit, and deleting the
        # candidate ref leaves the other intact.
        def verify_destination_survival(record, candidate_branch)
          return nil unless same_path?(record.source_repo, record.destination_repo)

          if !candidate_branch.to_s.empty? && record.destination_branch_name == candidate_branch
            return blocked("declared destination branch #{record.destination_branch} is the candidate's own " \
              "branch scheduled for deletion and cannot be its surviving destination")
          end

          nil
        end

        def verify_destination_acceptance(record)
          branch_tip = rev_parse(record.destination_repo, "--verify", record.destination_branch)
          if branch_tip.nil?
            return blocked("declared destination branch #{record.destination_branch} does not exist in " \
              "#{record.destination_repo}")
          end

          unless ancestry?(record.destination_repo, record.resolved_destination_head, branch_tip)
            return blocked("declared destination_head #{record.destination_head[0, 12]} is not accepted on " \
              "#{record.destination_branch}")
          end

          unless ancestry?(record.destination_repo, record.resolved_destination_base, branch_tip)
            return blocked("declared destination_base #{record.destination_base[0, 12]} is not accepted on " \
              "#{record.destination_branch}")
          end

          nil
        end

        # The declared ranges must be non-empty: a caller selected empty or
        # truncated range is not evidence. Content correspondence is proven
        # by the exact transition comparison itself — a squash that lands
        # the same content in fewer commits compares equal, a different
        # content never does.
        def verify_range(record)
          source_range = commit_count(record.source_repo, record.resolved_source_base, record.resolved_source_head)
          destination_range = commit_count(
            record.destination_repo, record.resolved_destination_base, record.resolved_destination_head
          )
          if source_range.nil? || destination_range.nil?
            return blocked("cannot count the declared source/destination ranges")
          end

          if source_range.zero? || destination_range.zero?
            blocked("empty-range identity is not proof; full-tree equality or accepted ancestry required")
          end
        end

        # Exact path-by-path comparison of the base..head transition on both
        # sides: identical changed paths, modes and blob SHAs. Blob SHAs are
        # content addresses, so equality covers binary content and symlinks;
        # renames compare as delete plus add (--no-renames).
        def transition_proof(record)
          source_transition = transition_map(record.source_repo, record.resolved_source_base, record.resolved_source_head)
          destination_transition = transition_map(
            record.destination_repo, record.resolved_destination_base, record.resolved_destination_head
          )
          if source_transition.nil? || destination_transition.nil?
            return blocked("cannot compare source/destination transitions")
          end

          if source_transition == destination_transition
            Models::PreservationProof.preserved(:content_transition, head: record.resolved_source_head)
          else
            blocked("declared destination content differs from the source transition")
          end
        end

        # @return [Hash, nil] `{path => [src_mode, dst_mode, src_blob, dst_blob]}`
        def transition_map(repo, base, head)
          stdout, _stderr, status = git_runner.call(
            repo, "diff-tree", "-r", "--no-renames", "--raw", "-z", base, head
          )
          return nil unless status.success?

          entries = stdout.to_s.split("\0")
          map = {}
          index = 0
          while index < entries.length
            meta = entries[index]
            index += 1
            break if meta.nil? || meta.empty?

            path = entries[index]
            index += 1
            next if path.nil?

            _colon, src_mode, dst_mode, src_blob, dst_blob = meta.split(" ")
            map[path] = [src_mode, dst_mode, src_blob, dst_blob]
          end
          map
        end

        def commit_count(repo, base, head)
          stdout, _stderr, status = git_runner.call(repo, "rev-list", "--count", "#{base}..#{head}")
          status.success? ? stdout.to_s.strip.to_i : nil
        end

        def ancestry?(repo, revision, base)
          _stdout, _stderr, status = git_runner.call(repo, "merge-base", "--is-ancestor", revision, base)
          status.success?
        end

        def rev_parse(repo, *args)
          stdout, _stderr, status = git_runner.call(repo, "rev-parse", *args)
          status.success? ? stdout.to_s.strip : nil
        end

        def same_path?(left, right)
          File.realpath(left) == File.realpath(right)
        rescue Errno::ENOENT, Errno::EACCES
          false
        end

        def blocked(reason)
          Models::PreservationProof.blocked(reason)
        end
      end
    end
  end
end
