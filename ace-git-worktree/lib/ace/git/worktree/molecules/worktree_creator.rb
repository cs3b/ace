# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Molecules
        # Worktree creator molecule
        #
        # Creates git worktrees with proper validation, naming, and error handling.
        # Integrates with git commands and provides task-aware creation capabilities.
        #
        # @example Create a task-aware worktree
        #   creator = WorktreeCreator.new
        #   task_data = fetch_task_data("081")
        #   config = WorktreeConfig.new
        #   result = creator.create_for_task(task_data, config)
        #
        # @example Create a traditional worktree
        #   result = creator.create_traditional("feature-branch", "/path/to/worktree")
        class WorktreeCreator
          # Default timeout for git commands
          DEFAULT_TIMEOUT = 60

          # Initialize a new WorktreeCreator
          #
          # @param timeout [Integer] Command timeout in seconds
          def initialize(timeout: DEFAULT_TIMEOUT)
            @timeout = timeout
          end

          # Create a worktree for a specific task
          #
          # @param task_data [Hash] Task data hash from ace-taskflow
          # @param config [WorktreeConfig] Worktree configuration
          # @param counter [Integer, nil] Counter for multiple worktrees of same task
          # @param git_root [String, nil] Git repository root (auto-detected if nil)
          # @return [Hash] Result with :success, :worktree_path, :branch, :error
          #
          # @example
          #   creator = WorktreeCreator.new
          #   task_data = fetch_task_data("081")
          #   config = ConfigLoader.new.load
          #   result = creator.create_for_task(task_data, config)
          #   # => { success: true, worktree_path: "/project/.ace-wt/task.081", branch: "081-fix-auth", error: nil }
          def create_for_task(task_data, config, counter: nil, git_root: nil)
            return error_result("Task data is required") unless task_data
            return error_result("Configuration is required") unless config

            begin
              # Determine git repository root
              git_root ||= detect_git_root
              return error_result("Not in a git repository") unless git_root

              # Generate names based on configuration
              directory_name = config.format_directory(task_data, counter)
              branch_name = config.format_branch(task_data)

              # Build full path
              worktree_path = File.join(config.absolute_root_path, directory_name)

              # Validate worktree path
              validation = validate_worktree_path(worktree_path, git_root)
              return error_result(validation[:error]) unless validation[:valid]

              # Create the worktree
              result = create_worktree(worktree_path, branch_name, git_root)
              return result unless result[:success]

              # Success - return worktree information
              {
                success: true,
                worktree_path: worktree_path,
                branch: branch_name,
                directory_name: directory_name,
                task_id: extract_task_id_from_data(task_data),
                git_root: git_root,
                error: nil
              }
            rescue StandardError => e
              error_result("Unexpected error: #{e.message}")
            end
          end

          # Create a traditional worktree (not task-aware)
          #
          # @param branch_name [String] Branch name
          # @param worktree_path [String, nil] Worktree path (auto-generated if nil)
          # @param git_root [String, nil] Git repository root (auto-detected if nil)
          # @return [Hash] Result with :success, :worktree_path, :branch, :error
          #
          # @example
          #   result = creator.create_traditional("feature-branch", "/tmp/worktree")
          def create_traditional(branch_name, worktree_path = nil, git_root: nil)
            return error_result("Branch name is required") if branch_name.nil? || branch_name.empty?

            begin
              # Determine git repository root
              git_root ||= detect_git_root
              return error_result("Not in a git repository") unless git_root

              # Auto-generate worktree path if not provided
              if worktree_path.nil?
                worktree_path = generate_default_worktree_path(branch_name, git_root)
              end

              # Validate worktree path
              validation = validate_worktree_path(worktree_path, git_root)
              return error_result(validation[:error]) unless validation[:valid]

              # Validate branch name
              return error_result("Invalid branch name") unless valid_branch_name?(branch_name)

              # Create the worktree
              create_worktree(worktree_path, branch_name, git_root)
            rescue StandardError => e
              error_result("Unexpected error: #{e.message}")
            end
          end

          # Check if a worktree already exists for the given criteria
          #
          # @param task_data [Hash, nil] Task data hash from ace-taskflow
          # @param branch_name [String, nil] Branch name
          # @param worktree_path [String, nil] Worktree path
          # @return [WorktreeInfo, nil] Existing worktree info or nil
          #
          # @example
          #   existing = creator.worktree_exists_for_task?(task_data)
          #   existing = creator.worktree_exists_for_branch?("feature-branch")
          def worktree_exists?(task_data: nil, branch_name: nil, worktree_path: nil)
            require_relative "worktree_lister"
            lister = WorktreeLister.new
            worktrees = lister.list_all

            # Check by task ID
            if task_data
              task_id = extract_task_id_from_data(task_data)
              existing = Models::WorktreeInfo.find_by_task_id(worktrees, task_id)
              return existing if existing
            end

            # Check by branch name
            if branch_name
              existing = Models::WorktreeInfo.find_by_branch(worktrees, branch_name)
              return existing if existing
            end

            # Check by path
            if worktree_path
              expanded_path = File.expand_path(worktree_path)
              existing = worktrees.find { |wt| File.expand_path(wt.path) == expanded_path }
              return existing if existing
            end

            nil
          end

          # Generate a unique worktree path for a task (handles conflicts)
          #
          # @param task_data [Hash] Task data hash from ace-taskflow
          # @param config [WorktreeConfig] Worktree configuration
          # @param git_root [String] Git repository root
          # @return [String] Unique worktree path
          #
          # @example
          #   path = creator.generate_unique_path(task_data, config, git_root)
          #   # => "/project/.ace-wt/task.081-2"
          def generate_unique_path(task_data, config, git_root)
            counter = 1
            loop do
              directory_name = config.format_directory(task_data, counter > 1 ? counter : nil)
              worktree_path = File.join(config.absolute_root_path, directory_name)

              # Check if path already exists
              existing = worktree_exists?(worktree_path: worktree_path)
              break worktree_path unless existing

              counter += 1
            end
          end

          # Validate a worktree path for creation
          #
          # @param worktree_path [String] Path to validate
          # @param git_root [String] Git repository root
          # @return [Hash] Validation result with :valid, :error, :expanded_path
          #
          # @example
          #   validation = creator.validate_worktree_path("/tmp/worktree", "/project")
          #   # => { valid: true, error: nil, expanded_path: "/tmp/worktree" }
          def validate_worktree_path(worktree_path, git_root)
            require_relative "../atoms/path_expander"
            Atoms::PathExpander.validate_for_worktree(worktree_path, git_root)
          end

          private

          # Create a worktree using git commands
          #
          # @param worktree_path [String] Path for the worktree
          # @param branch_name [String] Branch name
          # @param git_root [String] Git repository root
          # @return [Hash] Result with :success, :worktree_path, :branch, :error
          def create_worktree(worktree_path, branch_name, git_root)
            require_relative "../atoms/git_command"

            # Ensure parent directory exists
            parent_dir = File.dirname(worktree_path)
            FileUtils.mkdir_p(parent_dir) unless File.exist?(parent_dir)

            # Create the worktree
            result = Atoms::GitCommand.worktree("add", worktree_path, "-b", branch_name, timeout: @timeout)

            if result[:success]
              {
                success: true,
                worktree_path: worktree_path,
                branch: branch_name,
                git_root: git_root,
                error: nil
              }
            else
              error_result("Failed to create worktree: #{result[:error]}")
            end
          end

          # Detect the git repository root
          #
          # @return [String, nil] Git repository root or nil
          def detect_git_root
            require_relative "../atoms/git_command"
            Atoms::GitCommand.git_root
          end

          # Generate a default worktree path based on branch name
          #
          # @param branch_name [String] Branch name
          # @param git_root [String] Git repository root
          # @return [String] Generated worktree path
          def generate_default_worktree_path(branch_name, git_root)
            # Sanitize branch name for directory use
            sanitized_branch = branch_name.gsub(/[^a-zA-Z0-9\-_]/, "-")
            File.join(git_root, ".ace-wt", sanitized_branch)
          end

          # Validate if a branch name is valid for git
          #
          # @param branch_name [String] Branch name to validate
          # @return [Boolean] true if valid
          def valid_branch_name?(branch_name)
            return false if branch_name.nil? || branch_name.empty?
            return false if branch_name.length > 255

            # Git branch name restrictions (following git's actual rules)
            invalid_patterns = [
              /\.\./,           # Cannot contain ..
              /^@{/,           # Cannot start with @{
              /\s/,            # Cannot contain whitespace
              /[~^:?*\[\]]/,   # Cannot contain these special characters
              /\.$/,           # Cannot end with .
              /^\.$/,          # Cannot be just .
              /\.lock$/,       # Cannot end with .lock
              /^$/,            # Cannot be empty
              /^\. /           # Cannot start with dot followed by space
            ]

            # Check for invalid patterns
            return false if invalid_patterns.any? { |pattern| branch_name.match?(pattern) }

            # Cannot be HEAD or other reserved names that conflict with git's internal refs
            reserved_names = %w[HEAD]
            return false if reserved_names.include?(branch_name)

            # Additional validation: branch name cannot contain sequences that would be invalid
            # in file system paths (since git stores branches as files)
            return false if branch_name.include?('.git')

            true
          end

          # Extract task ID from task data
          #
          # @param task_data [Hash] Task data hash from ace-taskflow
          # @return [String] Task ID (e.g., "094")
          def extract_task_id_from_data(task_data)
            # Use task_number if available, otherwise extract from id
            return task_data[:task_number] if task_data[:task_number]

            # Extract from id field (e.g., "v.0.9.0+task.094" -> "094")
            if task_data[:id]
              match = task_data[:id].match(/task\.(\d+)$/)
              return match[1] if match
            end

            "unknown"
          end

          # Create an error result hash
          #
          # @param message [String] Error message
          # @return [Hash] Error result hash
          def error_result(message)
            {
              success: false,
              worktree_path: nil,
              branch: nil,
              error: message
            }
          end
        end
      end
    end
  end
end