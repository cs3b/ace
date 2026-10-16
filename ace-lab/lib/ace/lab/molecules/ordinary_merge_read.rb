# frozen_string_literal: true

require_relative "ordinary_worktree_read"

module Ace
  module Lab
    module Molecules
      # Local checks are bounded read-only observations. Only the forge provider
      # executes merge; moving a local ref can never prove a delivered merge.
      class OrdinaryMergeRead
        STRATEGY = "ff"

        def initialize(repo_path:, base_ref:, root: repo_path, common_dir: File.join(repo_path, ".git"),
          deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30)
          unless repo_path.is_a?(String) && repo_path.start_with?("/") &&
              base_ref.is_a?(String) && base_ref.start_with?("refs/")
            raise ArgumentError, "ordinary merge read needs an absolute repository and full base ref"
          end
          @repo_path, @base_ref = repo_path, base_ref
          @reader = OrdinaryWorktreeRead.new(root: root, common_dir: common_dir, deadline: deadline)
        end

        def base_head
          @reader.ref_head(@repo_path, @base_ref)
        rescue Ace::Assign::Error => error
          raise GitUnavailable, error.message
        end

        def candidate_commit?(head)
          @reader.commit?(@repo_path, head)
        rescue Ace::Assign::Error => error
          raise GitUnavailable, error.message
        end

        def fast_forwardable?(head)
          @reader.ancestor?(@repo_path, base_head, head)
        rescue Ace::Assign::Error => error
          raise GitUnavailable, error.message
        end

        class GitUnavailable < StandardError; end
      end
    end
  end
end
