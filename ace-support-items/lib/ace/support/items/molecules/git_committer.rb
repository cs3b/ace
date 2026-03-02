# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Molecules
        # Shells out to ace-git-commit for auto-committing after mutations.
        # Pure CLI invocation — no gem dependency on ace-git-commit.
        class GitCommitter
          # @param paths [Array<String>] File/directory paths to commit
          # @param intention [String] Commit intention for LLM message generation
          # @return [Boolean] true if commit succeeded
          def self.commit(paths:, intention:)
            cmd = ["ace-git-commit"] + paths + ["-i", intention]
            system(*cmd)
          end
        end
      end
    end
  end
end
