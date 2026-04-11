# frozen_string_literal: true

require "fileutils"
require "tmpdir"

module Ace
  module TestSupport
    module Fixtures
      # Shared mock fixtures for Git command testing
      # Extracted from ace-git-worktree/test/test_helper.rb to promote reusability
      module GitMocks
        # Mock git repository for fast unit tests without subprocess calls
        # Provides a temp directory with files but no actual git init
        # Use this for testing code that reads files but doesn't need real git commands
        #
        # @example
        #   repo = MockGitRepo.new
        #   repo.add_file("secret.txt", "TOKEN=ghp_abc123")
        #   repo.add_commit("abc1234", message: "Add secret")
        #   # Test code that examines repo structure
        #   repo.cleanup
        class MockGitRepo
          attr_reader :path, :commits, :files

          # Create a mock git repository
          # @yield [self] Optionally yields self for one-line setup patterns
          # @example Block initializer for concise setup
          #   repo = MockGitRepo.new do |r|
          #     r.add_file("secret.txt", "TOKEN=abc123")
          #     r.add_commit("abc1234", message: "Add secret")
          #   end
          def initialize
            @path = Dir.mktmpdir("ace-mock-git-repo")
            @commits = []
            @files = {}
            # Create a fake .git directory to pass validation checks
            # This is much faster than running `git init` (~150ms savings)
            FileUtils.mkdir_p(File.join(@path, ".git"))

            yield self if block_given?
          end

          # Add a file to the mock repo (instant, no git add)
          # @param filename [String] Relative path within repo
          # @param content [String] File content
          def add_file(filename, content)
            full_path = File.join(@path, filename)
            FileUtils.mkdir_p(File.dirname(full_path))
            File.write(full_path, content)
            @files[filename] = content
          end

          # Record a mock commit (no subprocess)
          # @param hash [String] Commit hash
          # @param message [String] Commit message
          # @param files [Array<String>] Files in this commit
          def add_commit(hash, message: "Test commit", files: nil)
            @commits << {
              hash: hash,
              message: message,
              files: files || @files.keys.dup
            }
          end

          # Simulate git status output (mock repos are always "clean")
          # @return [Boolean] Always true for mock repos
          def status_clean?
            true
          end

          # Get the latest commit hash (or nil if no commits)
          # @return [String, nil] Last commit hash
          def head
            @commits.last&.dig(:hash)
          end

          # Clean up the temp directory
          def cleanup
            FileUtils.rm_rf(@path) if @path && Dir.exist?(@path)
          end

          # Reset the mock repo state without destroying the temp directory
          # Useful for reusing the same mock repo across multiple test assertions
          def reset!
            @commits = []
            @files = {}
            # Clear files but keep .git directory
            Dir.glob(File.join(@path, "*")).each do |f|
              next if File.basename(f) == ".git"

              FileUtils.rm_rf(f)
            end
          end
        end

        # Creates a mock git command result
        # @param output [String] The command output
        # @param error [String] The error output
        # @param exit_status [Integer] The exit status code (default: 0)
        # @return [Hash] Mock result with success, output, error, and exit_code
        def self.mock_command_result(output: "", error: "", exit_status: 0)
          {
            success: exit_status == 0,
            output: output,
            error: error,
            exit_code: exit_status
          }
        end

        # Stub git command execution via ace-git CommandExecutor
        # @param output [String] The command output
        # @param error [String] The error output
        # @param exit_status [Integer] The exit status code
        # @yield Block where the stub is active
        def self.stub_git_command(output: "", error: "", exit_status: 0)
          return unless defined?(Ace::Git::Atoms::CommandExecutor)

          mock_result = mock_command_result(output: output, error: error, exit_status: exit_status)

          Ace::Git::Atoms::CommandExecutor.stub(:execute, mock_result) do
            yield
          end
        end

        # Stub ace-core configuration
        # @param config_data [Hash] The configuration data to return
        # @yield Block where the stub is active
        def self.stub_ace_core_config(config_data = {})
          return yield unless defined?(Ace::Core)
          return yield unless Ace::Core.respond_to?(:get)

          original = Ace::Core.method(:get)
          Ace::Core.define_singleton_method(:get) { |*| config_data }
          yield
        ensure
          Ace::Core.define_singleton_method(:get, original) if original
        end

        # Stub ace-task CLI output
        # @param task_id [String] The task ID
        # @param output [String] The taskflow output
        # @yield Block where the stub is active
        def self.stub_ace_taskflow_output(task_id, output)
          require "open3"

          Open3.stub(:capture3, [output.to_s, "", 0]) do
            yield
          end
        end

        # Common git worktree list output
        MOCK_WORKTREE_LIST = <<~OUTPUT
          /Users/test/project              abc123 [main]
          /Users/test/project-task-081     def456 [task-081]
          /Users/test/project-task-082     ghi789 [task-082]
        OUTPUT

        # Common git branch list output
        MOCK_BRANCH_LIST = <<~OUTPUT
          * main
            task-081
            task-082
            feature/new-feature
        OUTPUT

        # Common git status output (clean)
        MOCK_STATUS_CLEAN = <<~OUTPUT
          On branch main
          nothing to commit, working tree clean
        OUTPUT

        # Common git status output (dirty)
        MOCK_STATUS_DIRTY = <<~OUTPUT
          On branch task-081
          Changes not staged for commit:
            modified:   lib/example.rb

          Untracked files:
            new_file.rb
        OUTPUT

        # Creates a mock WorktreeManager.create_task result
        # @param task_id [String] The task ID
        # @param task_title [String] The task title
        # @param worktree_path [String] The worktree path
        # @param branch [String] The branch name
        # @param dry_run [Boolean] Whether this is a dry run
        # @return [Hash] Mock result matching WorktreeManager API
        def self.mock_create_task_result(task_id:, task_title:, worktree_path:, branch:, dry_run: false)
          if dry_run
            {
              success: true,
              task_id: task_id,
              task_title: task_title,
              would_create: {
                worktree_path: worktree_path,
                branch: branch
              },
              steps_planned: [
                "Would fetch task details for #{task_id}",
                "Would create worktree at #{worktree_path}",
                "Would create and checkout branch #{branch}",
                "Would copy untracked files",
                "Would stash and apply changes"
              ]
            }
          else
            {
              success: true,
              task_id: task_id,
              task_title: task_title,
              worktree_path: worktree_path,
              branch: branch,
              steps_completed: [
                "Fetched task details for #{task_id}",
                "Created worktree at #{worktree_path}",
                "Created and checked out branch #{branch}",
                "Copied untracked files",
                "Stashed and applied changes"
              ]
            }
          end
        end

        # Creates a mock WorktreeManager error result
        # @param error_message [String] The error message
        # @return [Hash] Mock error result
        def self.mock_error_result(error_message)
          {
            success: false,
            error: error_message
          }
        end
      end
    end
  end
end
