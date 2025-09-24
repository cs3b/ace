# frozen_string_literal: true

require "open3"

module Ace
  module Taskflow
    module Molecules
      # Handles git operations for ideas and tasks
      class GitExecutor
        # Result structure for git operations
        Result = Struct.new(:success, :message, :error) do
          def success?
            success
          end
        end

        def initialize(debug: false)
          @debug = debug
        end

        # Execute git add and commit for a file
        # @param file_path [String] Path to the file to commit
        # @param message [String] Commit message
        # @return [Result] Operation result
        def execute_commit(file_path, message)
          return Result.new(false, nil, "File does not exist: #{file_path}") unless File.exist?(file_path)

          # Check if we're in a git repository
          unless git_repository?
            return Result.new(false, nil, "Not in a git repository")
          end

          # Stage the file
          add_result = git_add(file_path)
          return add_result unless add_result.success?

          # Commit with message
          commit_result = git_commit(message)
          commit_result
        rescue => e
          Result.new(false, nil, "Git operation failed: #{e.message}")
        end

        private

        def git_repository?
          _, _, status = Open3.capture3("git", "rev-parse", "--git-dir")
          status.success?
        end

        def git_add(file_path)
          stdout, stderr, status = Open3.capture3("git", "add", file_path)

          if status.success?
            debug_log("Git add successful: #{file_path}")
            Result.new(true, "File staged: #{file_path}", nil)
          else
            debug_log("Git add failed: #{stderr}")
            Result.new(false, nil, "Failed to stage file: #{stderr.strip}")
          end
        end

        def git_commit(message)
          stdout, stderr, status = Open3.capture3("git", "commit", "-m", message)

          if status.success?
            debug_log("Git commit successful")
            Result.new(true, "Committed: #{message}", nil)
          else
            # Check if there's nothing to commit
            if stderr.include?("nothing to commit") || stdout.include?("nothing to commit")
              debug_log("Nothing to commit")
              Result.new(true, "Nothing to commit", nil)
            else
              debug_log("Git commit failed: #{stderr}")
              Result.new(false, nil, "Failed to commit: #{stderr.strip}")
            end
          end
        end

        def debug_log(message)
          puts "Debug [GitExecutor]: #{message}" if @debug
        end
      end
    end
  end
end