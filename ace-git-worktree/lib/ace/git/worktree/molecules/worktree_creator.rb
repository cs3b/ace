# frozen_string_literal: true

require_relative "../atoms/git_command"
require_relative "../atoms/path_expander"

module Ace
  module Git
    module Worktree
      module Molecules
        # Creates git worktrees
        class WorktreeCreator
          # Create a new worktree
          # @param path [String] Directory path for the worktree
          # @param branch [String] Branch name to create
          # @param options [Hash] Additional options
          # @return [Hash] Result with :success, :path, :branch, :error
          def self.create(path:, branch:, options = {})
            # Validate inputs
            return error_result("Path cannot be empty") if path.nil? || path.empty?
            return error_result("Branch cannot be empty") if branch.nil? || branch.empty?

            # Get repository root
            repo_root = Atoms::GitCommand.repo_root
            return error_result("Not in a git repository") unless repo_root

            # Expand the path relative to repo root
            full_path = if path.start_with?("/")
                         path
                       else
                         File.join(repo_root, path)
                       end

            # Check if directory already exists
            if File.exist?(full_path) && !options[:force]
              return error_result("Worktree directory already exists: #{full_path}")
            end

            # Create parent directory if needed
            parent_dir = File.dirname(full_path)
            unless Atoms::PathExpander.ensure_directory(parent_dir)
              return error_result("Failed to create parent directory: #{parent_dir}")
            end

            # Build git worktree add command
            git_args = ["worktree", "add", full_path]

            # Add branch creation flag
            if options[:create_branch] != false # default to creating branch
              git_args << "-b" << branch
            else
              git_args << branch
            end

            # Add base branch/commit if specified
            git_args << options[:base] if options[:base]

            # Execute git worktree add
            result = Atoms::GitCommand.execute(*git_args, timeout: options[:timeout] || 30)

            if result[:success]
              {
                success: true,
                path: full_path,
                branch: branch,
                output: result[:output]
              }
            else
              # Check if error is about branch already existing
              if result[:error] =~ /already exists/i && result[:error] =~ /branch/i
                # Try without creating branch
                git_args_retry = ["worktree", "add", full_path, branch]
                result_retry = Atoms::GitCommand.execute(*git_args_retry, timeout: options[:timeout] || 30)

                if result_retry[:success]
                  {
                    success: true,
                    path: full_path,
                    branch: branch,
                    output: result_retry[:output]
                  }
                else
                  error_result("Failed to create worktree: #{result_retry[:error]}")
                end
              else
                error_result("Failed to create worktree: #{result[:error]}")
              end
            end
          end

          # Remove a worktree
          # @param path [String] Worktree path to remove
          # @param options [Hash] Options (force: true to force removal)
          # @return [Hash] Result with :success, :output, :error
          def self.remove(path:, options = {})
            return error_result("Path cannot be empty") if path.nil? || path.empty?

            git_args = ["worktree", "remove", path]
            git_args << "--force" if options[:force]

            result = Atoms::GitCommand.execute(*git_args)

            if result[:success]
              {
                success: true,
                output: result[:output]
              }
            else
              error_result("Failed to remove worktree: #{result[:error]}")
            end
          end

          # List all worktrees
          # @return [Array<Hash>] List of worktree info
          def self.list
            result = Atoms::GitCommand.execute("worktree", "list", "--porcelain")

            return [] unless result[:success]

            parse_worktree_list(result[:output])
          end

          # Prune worktrees
          # @return [Hash] Result with :success, :output, :error
          def self.prune
            result = Atoms::GitCommand.execute("worktree", "prune", "--verbose")

            if result[:success]
              {
                success: true,
                output: result[:output]
              }
            else
              error_result("Failed to prune worktrees: #{result[:error]}")
            end
          end

          private

          def self.error_result(message)
            {
              success: false,
              error: message
            }
          end

          def self.parse_worktree_list(output)
            worktrees = []
            current = {}

            output.lines.each do |line|
              line = line.strip
              next if line.empty?

              case line
              when /^worktree (.+)$/
                # Save previous worktree if exists
                worktrees << current unless current.empty?
                current = { path: $1 }
              when /^HEAD ([a-f0-9]+)$/
                current[:commit] = $1
              when /^branch refs\/heads\/(.+)$/
                current[:branch] = $1
              when /^detached$/
                current[:branch] = "HEAD (detached)"
              when /^locked$/
                current[:locked] = true
              when /^prunable$/
                current[:prunable] = true
              end
            end

            # Don't forget the last one
            worktrees << current unless current.empty?

            worktrees
          end
        end
      end
    end
  end
end