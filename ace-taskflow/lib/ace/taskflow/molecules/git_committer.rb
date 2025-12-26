# frozen_string_literal: true

require "ace/git"

module Ace
  module Taskflow
    module Molecules
      # Thin wrapper around ace-git for commit operations
      # Provides backward-compatible interface matching GitExecutor::Result
      class GitCommitter
        # Result structure for git operations - maintains backward compatibility
        Result = Struct.new(:success, :message, :error) do
          def success?
            success
          end
        end

        def initialize(debug: false)
          @debug = debug
        end

        # Execute git add and commit for a file or directory
        # @param path [String] Path to the file or directory to commit
        # @param message [String] Commit message
        # @return [Result] Operation result
        def execute_commit(path, message)
          return Result.new(false, nil, "Path does not exist: #{path}") unless path_exists?(path)

          # Check if we're in a git repository
          unless Ace::Git::Atoms::RepositoryChecker.in_git_repo?
            return Result.new(false, nil, "Not in a git repository")
          end

          # Stage the path
          add_result = git_add(path)
          return add_result unless add_result.success?

          # Commit with message
          commit_result = git_commit(message)
          commit_result
        rescue StandardError => e
          Result.new(false, nil, "Git operation failed: #{e.message}")
        end

        protected

        # Protected methods for easier testing with stubs
        def path_exists?(path)
          File.exist?(path) || Dir.exist?(path)
        end

        private

        def git_add(path)
          result = Ace::Git::Atoms::CommandExecutor.execute("git", "add", path)

          if result[:success]
            debug_log("Git add successful: #{path}")
            Result.new(true, "Path staged: #{path}", nil)
          else
            debug_log("Git add failed: #{result[:error]}")
            Result.new(false, nil, "Failed to stage path: #{result[:error].strip}")
          end
        end

        def git_commit(message)
          result = Ace::Git::Atoms::CommandExecutor.execute("git", "commit", "-m", message)

          if result[:success]
            debug_log("Git commit successful")
            Result.new(true, "Committed: #{message}", nil)
          else
            # Check if there's nothing to commit - git may return various messages
            if nothing_to_commit?(result[:output], result[:error])
              debug_log("Nothing to commit")
              Result.new(true, "Nothing to commit", nil)
            else
              debug_log("Git commit failed: #{result[:error]}")
              Result.new(false, nil, "Failed to commit: #{result[:error].strip}")
            end
          end
        end

        # Check for various "nothing to commit" messages from git
        # Git may return different messages depending on the state:
        # - "nothing to commit" - clean working directory
        # - "no changes added to commit" - staged files but nothing new to commit
        # - "nothing added to commit" - similar to above (some git versions)
        # Note: These patterns assume English locale output (LC_ALL=C enforced by ace-git's CommandExecutor)
        def nothing_to_commit?(output, error)
          combined = "#{output}\n#{error}".downcase
          combined.include?("nothing to commit") ||
            combined.include?("no changes added to commit") ||
            combined.include?("nothing added to commit")
        end

        def debug_log(message)
          $stderr.puts "Debug [GitCommitter]: #{message}" if @debug
        end
      end
    end
  end
end
