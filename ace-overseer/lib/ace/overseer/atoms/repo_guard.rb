# frozen_string_literal: true

module Ace
  module Overseer
    module Atoms
      module RepoGuard
        MESSAGE = "ace-overseer must be run inside a git repository or worktree. Change into your project repo and retry."

        def self.ensure_repo!(cwd: Dir.pwd)
          return true if inside_repo?(cwd: cwd)

          raise Ace::Support::Cli::Error.new(MESSAGE)
        end

        def self.inside_repo?(cwd: Dir.pwd)
          system(
            "git", "-C", cwd.to_s, "rev-parse", "--is-inside-work-tree",
            out: File::NULL, err: File::NULL
          )
        rescue SystemCallError
          false
        end
      end
    end
  end
end
