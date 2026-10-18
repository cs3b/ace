# frozen_string_literal: true

require "ace/git"

module Ace
  module Task
    module Molecules
      # Detects whether a task path is ignored by Git.
      #
      # ace-task is a universal task tool: it does not know which folders a lab
      # or a role reserves. When behavior has to differ for a path that is not
      # committed, the decision comes from Git's own ignore rules for the actual
      # path — never from a folder-name list. The same query covers the task
      # directory or its spec file, from any working directory, and with a
      # custom task root: Git resolves the repository from the path itself.
      class GitIgnoredPath
        # @param path [String] Task directory or spec file path
        # @return [Boolean] true when Git ignores the path (a commit would skip it)
        def self.ignored?(path)
          absolute = File.expand_path(path.to_s)
          working_dir = File.directory?(absolute) ? absolute : File.dirname(absolute)
          return false unless Dir.exist?(working_dir)

          result = Ace::Git::Atoms::CommandExecutor.execute(
            "git", "-C", working_dir, "check-ignore", "-q", "--", absolute
          )
          result[:success] == true
        rescue StandardError
          false
        end
      end
    end
  end
end
