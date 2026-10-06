# frozen_string_literal: true

module Ace
  module GitCommit
    module Molecules
      # Read-only inspection of the current worktree's native Git operation state.
      class GitOperationDetector
        MARKERS = {
          "rebase-merge" => ["rebase", "git rebase --continue"],
          "rebase-apply" => ["rebase", "git rebase --continue"],
          "MERGE_HEAD" => ["merge", "git commit"],
          "CHERRY_PICK_HEAD" => ["cherry-pick", "git cherry-pick --continue"],
          "REVERT_HEAD" => ["revert", "git revert --continue"],
          "sequencer" => ["sequencer", "git status and follow its native continuation guidance"]
        }.freeze

        def initialize(git_executor)
          @git = git_executor
        end

        def detect
          MARKERS.each do |marker, operation|
            path = @git.execute("rev-parse", "--git-path", marker).delete_suffix("\n")
            raise GitError, "Git returned an empty metadata path for #{marker}" if path.empty?
            next unless present?(path)

            return ["git-am", "git am --continue"] if marker == "rebase-apply" && present?(File.join(path, "applying"))

            return operation
          rescue GitError, SystemCallError => e
            raise GitError, "Cannot inspect Git operation state (#{marker}): #{e.message}. " \
              "Check metadata access and run git status before retrying."
          end
          nil
        end

        private

        def present?(path)
          File.stat(path)
          true
        rescue Errno::ENOENT
          false
        end
      end
    end
  end
end
