# frozen_string_literal: true

require "open3"

module Ace
  module Coworker
    module Molecules
      # Resolves the current project root (Git worktree top) with an
      # injectable runner (ADR-031 argv contract).
      class ProjectRoot
        DEFAULT_GIT_RUNNER = ->(*args) { Open3.capture3("git", *args) }

        def initialize(git_runner: DEFAULT_GIT_RUNNER)
          @git_runner = git_runner
        end

        # @return [String] absolute project root; falls back to Dir.pwd
        def resolve(from: Dir.pwd)
          out, _err, _status = @git_runner.call("-C", from, "rev-parse", "--show-toplevel")
          root = out.to_s.strip
          root.empty? ? File.expand_path(from) : root
        end
      end
    end
  end
end
