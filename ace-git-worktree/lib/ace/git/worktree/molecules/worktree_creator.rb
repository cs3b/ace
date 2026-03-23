# frozen_string_literal: true

require_relative "../atoms/task_id_extractor"

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
          # @param config [WorktreeConfig, nil] Worktree configuration
          # @param timeout [Integer] Command timeout in seconds
          def initialize(config: nil, timeout: DEFAULT_TIMEOUT)
            @config = config
            @timeout = timeout
          end

          # Create a worktree for a specific task
          #
          # @param task_data [Hash] Task data hash from ace-task
          # @param config [WorktreeConfig] Worktree configuration
          # @param counter [Integer, nil] Counter for multiple worktrees of same task
          # @param git_root [String, nil] Git repository root (auto-detected if nil)
          # @param source [String, nil] Git ref to use as start-point for the new branch
          #   If nil, uses current branch (default behavior - fixes the branch source bug)
          # @param target_branch [String, nil] PR target branch (for subtasks)
          # @return [Hash] Result with :success, :worktree_path, :branch, :error
          #
          # @example
          #   creator = WorktreeCreator.new
          #   task_data = fetch_task_data("081")
          #   config = ConfigLoader.new.load
          #   result = creator.create_for_task(task_data, config)
          #   # => { success: true, worktree_path: "/project/.ace-wt/task.081", branch: "081-fix-auth", error: nil }
          #
          # @example With explicit source
          #   result = creator.create_for_task(task_data, config, source: "main")
          #   # => Creates branch based on 'main' instead of current branch
          #
          # @example Subtask with target branch
          #   result = creator.create_for_task(subtask_data, config, target_branch: "202-orchestrator")
          #   # => { success: true, target_branch: "202-orchestrator", ... }
          def create_for_task(task_data, config, counter: nil, git_root: nil, source: nil, target_branch: nil)
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

              # Ensure parent directory exists before validation
              # (PathExpander rejects paths whose parent doesn't exist yet)
              parent_dir = File.dirname(worktree_path)
              FileUtils.mkdir_p(parent_dir) unless File.exist?(parent_dir)

              # Validate worktree path
              validation = validate_worktree_path(worktree_path, git_root)
              return error_result(validation[:error]) unless validation[:valid]

              # Create the worktree with source as start-point
              result = create_worktree(worktree_path, branch_name, git_root, start_point: source)
              return result unless result[:success]

              # Success - return worktree information
              {
                success: true,
                worktree_path: worktree_path,
                branch: branch_name,
                start_point: result[:start_point],
                directory_name: directory_name,
                task_id: extract_task_id_from_data(task_data),
                git_root: git_root,
                target_branch: target_branch,
                error: nil
              }
            rescue => e
              error_result("Unexpected error: #{e.message}")
            end
          end

          # Create a worktree for a Pull Request
          #
          # @param pr_data [Hash] PR data hash from PrFetcher
          # @param config [WorktreeConfig] Worktree configuration
          # @param git_root [String, nil] Git repository root (auto-detected if nil)
          # @return [Hash] Result with :success, :worktree_path, :branch, :error
          #
          # @example
          #   pr_data = { number: 26, title: "Add feature", head_branch: "feature/auth", base_branch: "main" }
          #   result = creator.create_for_pr(pr_data, config)
          #   # => { success: true, worktree_path: "/project/.ace-wt/pr-26", branch: "pr-26", tracking: "origin/feature/auth" }
          def create_for_pr(pr_data, config, git_root: nil)
            return error_result("PR data is required") unless pr_data
            return error_result("Configuration is required") unless config

            begin
              # Determine git repository root
              git_root ||= detect_git_root
              return error_result("Not in a git repository") unless git_root

              # Get PR-specific configuration (fallback to defaults)
              pr_config = config.pr_config || {}
              remote_name = pr_config[:remote_name] || "origin"
              directory_format = pr_config[:directory_format] || "ace-pr-{number}"
              branch_format = pr_config[:branch_format] || "pr-{number}-{slug}"

              # Format directory and branch names
              directory_name = format_pr_name(directory_format, pr_data)
              local_branch_name = format_pr_name(branch_format, pr_data)

              # Build full path
              worktree_path = File.join(config.absolute_root_path, directory_name)

              # Validate worktree path
              validation = validate_worktree_path(worktree_path, git_root)
              return error_result(validation[:error]) unless validation[:valid]

              # Fetch the remote branch
              head_branch = pr_data[:head_branch]
              fetch_result = fetch_remote_branch(remote_name, head_branch, git_root)
              return error_result(fetch_result[:error]) unless fetch_result[:success]

              # Create worktree with remote tracking
              result = create_worktree_with_tracking(
                worktree_path,
                local_branch_name,
                "#{remote_name}/#{head_branch}",
                git_root,
                configure_push: config.configure_push_for_mismatch?
              )
              return result unless result[:success]

              # Success - return worktree information
              {
                success: true,
                worktree_path: worktree_path,
                branch: local_branch_name,
                tracking: "#{remote_name}/#{head_branch}",
                directory_name: directory_name,
                pr_number: pr_data[:number],
                pr_title: pr_data[:title],
                git_root: git_root,
                error: nil
              }
            rescue => e
              error_result("Unexpected error: #{e.message}")
            end
          end

          # Create a worktree for a specific branch (local or remote)
          #
          # @param branch_name [String] Branch name (e.g., "feature" or "origin/feature")
          # @param config [WorktreeConfig] Worktree configuration
          # @param git_root [String, nil] Git repository root (auto-detected if nil)
          # @return [Hash] Result with :success, :worktree_path, :branch, :error
          #
          # @example Remote branch
          #   result = creator.create_for_branch("origin/feature/auth", config)
          #   # => { success: true, worktree_path: "/project/.ace-wt/feature-auth", branch: "feature/auth", tracking: "origin/feature/auth" }
          #
          # @example Local branch
          #   result = creator.create_for_branch("local-feature", config)
          #   # => { success: true, worktree_path: "/project/.ace-wt/local-feature", branch: "local-feature", tracking: nil }
          def create_for_branch(branch_name, config, git_root: nil)
            return error_result("Branch name is required") if branch_name.nil? || branch_name.empty?
            return error_result("Configuration is required") unless config

            begin
              # Determine git repository root
              git_root ||= detect_git_root
              return error_result("Not in a git repository") unless git_root

              # Detect if this is a remote branch
              remote_info = detect_remote_branch(branch_name)

              if remote_info
                # Remote branch - create with tracking
                create_for_remote_branch(branch_name, remote_info, config, git_root)
              else
                # Local branch - create without tracking
                create_for_local_branch(branch_name, config, git_root)
              end
            rescue => e
              error_result("Unexpected error: #{e.message}")
            end
          end

          # Create a traditional worktree (not task-aware)
          #
          # @param branch_name [String] Branch name
          # @param worktree_path [String, nil] Worktree path (auto-generated if nil)
          # @param git_root [String, nil] Git repository root (auto-detected if nil)
          # @param source [String, nil] Git ref to use as start-point for the new branch
          #   If nil, uses current branch (default behavior)
          # @return [Hash] Result with :success, :worktree_path, :branch, :error
          #
          # @example
          #   result = creator.create_traditional("feature-branch", "/tmp/worktree")
          #
          # @example With explicit source
          #   result = creator.create_traditional("feature-branch", nil, source: "main")
          def create_traditional(branch_name, worktree_path = nil, git_root: nil, source: nil)
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

              # Check if branch already exists (locally or remotely)
              if branch_exists?(branch_name)
                # Branch exists - create worktree for existing branch
                create_worktree_for_existing_branch(worktree_path, branch_name, git_root)
              else
                # Branch doesn't exist - create new branch with worktree
                create_worktree(worktree_path, branch_name, git_root, start_point: source)
              end
            rescue => e
              error_result("Unexpected error: #{e.message}")
            end
          end

          # Check if a worktree already exists for the given criteria
          #
          # @param task_data [Hash, nil] Task data hash from ace-task
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
          # @param task_data [Hash] Task data hash from ace-task
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
              directory_name = config.format_directory(task_data, (counter > 1) ? counter : nil)
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
          # @param start_point [String, nil] Git ref to use as start-point for the new branch
          #   If nil, uses current branch (or commit SHA if in detached HEAD state)
          # @return [Hash] Result with :success, :worktree_path, :branch, :error
          def create_worktree(worktree_path, branch_name, git_root, start_point: nil)
            require_relative "../atoms/git_command"

            # Ensure parent directory exists
            parent_dir = File.dirname(worktree_path)
            FileUtils.mkdir_p(parent_dir) unless File.exist?(parent_dir)

            # Default to current branch if no start_point provided
            # This ensures new branches are based on the current branch, not main worktree HEAD
            start_point ||= Atoms::GitCommand.current_branch
            return error_result("Cannot determine current branch for start-point") unless start_point

            # Validate start_point exists
            unless Atoms::GitCommand.ref_exists?(start_point)
              return error_result("Source ref '#{start_point}' does not exist")
            end

            # Create the worktree with explicit start-point
            result = Atoms::GitCommand.worktree("add", worktree_path, "-b", branch_name, start_point, timeout: @timeout)

            if result[:success]
              {
                success: true,
                worktree_path: worktree_path,
                branch: branch_name,
                start_point: start_point,
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

          # Check if a branch exists locally or as a remote-tracking branch
          #
          # Checks local and remote refs separately since git show-ref --verify
          # requires ALL refs to exist when given multiple refs. This ensures we
          # correctly detect local-only branches (which have no remote tracking ref).
          #
          # @param branch_name [String] Branch name to check
          # @return [Boolean] true if branch exists locally or as origin remote-tracking ref
          def branch_exists?(branch_name)
            require_relative "../atoms/git_command"

            # Check local branch first (short-circuit if found)
            local_result = Atoms::GitCommand.execute(
              "show-ref", "--verify", "--quiet",
              "refs/heads/#{branch_name}",
              timeout: 5
            )
            return true if local_result[:success]

            # Check remote tracking branch
            remote_result = Atoms::GitCommand.execute(
              "show-ref", "--verify", "--quiet",
              "refs/remotes/origin/#{branch_name}",
              timeout: 5
            )
            remote_result[:success]
          end

          # Create a worktree for an existing branch
          #
          # @param worktree_path [String] Path for the worktree
          # @param branch_name [String] Existing branch name
          # @param git_root [String] Git repository root
          # @return [Hash] Result with :success, :worktree_path, :branch, :error
          def create_worktree_for_existing_branch(worktree_path, branch_name, git_root)
            require_relative "../atoms/git_command"

            # Ensure parent directory exists
            parent_dir = File.dirname(worktree_path)
            FileUtils.mkdir_p(parent_dir) unless File.exist?(parent_dir)

            # Create the worktree without -b flag (uses existing branch)
            result = Atoms::GitCommand.worktree("add", worktree_path, branch_name, timeout: @timeout)

            if result[:success]
              {
                success: true,
                worktree_path: worktree_path,
                branch: branch_name,
                start_point: nil,
                git_root: git_root,
                error: nil
              }
            else
              error_result("Failed to create worktree: #{result[:error]}")
            end
          end

          # Generate a default worktree path based on branch name
          #
          # @param branch_name [String] Branch name
          # @param git_root [String] Git repository root
          # @return [String] Generated worktree path
          def generate_default_worktree_path(branch_name, git_root)
            require_relative "../atoms/slug_generator"
            # Sanitize branch name for directory use
            sanitized_branch = Atoms::SlugGenerator.to_directory_name(branch_name)

            # Use config's root_path if available, otherwise default to .ace-wt
            if @config
              File.join(@config.absolute_root_path, sanitized_branch)
            else
              File.join(git_root, ".ace-wt", sanitized_branch)
            end
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
            return false if branch_name.include?(".git")

            true
          end

          # Extract task ID from task data
          #
          # @param task_data [Hash] Task data hash from ace-task
          # @return [String] Task ID (e.g., "094")
          def extract_task_id_from_data(task_data)
            # Use shared extractor that preserves subtask IDs (e.g., "121.01")
            Atoms::TaskIDExtractor.extract(task_data)
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

          # Detect if a branch name refers to a remote branch
          #
          # Only returns a remote/branch hash if the first part is actually a configured
          # git remote. This prevents branches like "feature/login" from being incorrectly
          # treated as remote branches (where "feature" would be the remote).
          #
          # @param branch_name [String] Branch name to check
          # @return [Hash, nil] { remote: "origin", branch: "feature/auth" } or nil if local
          #
          # @example
          #   detect_remote_branch("origin/feature/auth")
          #   # => { remote: "origin", branch: "feature/auth" }
          #
          #   detect_remote_branch("feature/login")
          #   # => nil (when "feature" is not a configured remote)
          #
          #   detect_remote_branch("local-branch")
          #   # => nil
          def detect_remote_branch(branch_name)
            # Check if branch name contains a slash (remote/branch pattern)
            return nil unless branch_name.include?("/")

            # Split on first slash only
            parts = branch_name.split("/", 2)
            return nil if parts.length != 2

            potential_remote = parts[0]
            branch = parts[1]

            # Basic validation
            return nil if potential_remote.empty? || branch.empty?
            # Invalid if branch starts with / or ends with /
            return nil if branch.start_with?("/") || branch.end_with?("/")
            # Invalid if remote ends with / or starts with /
            return nil if potential_remote.start_with?("/") || potential_remote.end_with?("/")

            # Verify the potential remote is actually configured
            remote_check = validate_remote_exists(potential_remote, Dir.pwd)
            return nil unless remote_check[:exists]

            {remote: potential_remote, branch: branch}
          end

          # Validate that a git remote exists
          #
          # @param remote [String] Remote name (e.g., "origin")
          # @param git_root [String] Git repository root
          # @return [Hash] Result with :exists (Boolean) and :remotes (Array) for helpful error messages
          def validate_remote_exists(remote, git_root)
            require_relative "../atoms/git_command"

            # Get list of remotes
            result = Atoms::GitCommand.execute(
              "remote",
              timeout: 5
            )

            if result[:success]
              remotes = result[:output].strip.split("\n")
              exists = remotes.include?(remote)
              {exists: exists, remotes: remotes}
            else
              # If we can't list remotes, assume it doesn't exist
              {exists: false, remotes: []}
            end
          end

          # Fetch a remote branch
          #
          # @param remote [String] Remote name (e.g., "origin")
          # @param branch [String] Branch name
          # @param git_root [String] Git repository root
          # @return [Hash] Result with :success, :error
          def fetch_remote_branch(remote, branch, git_root)
            require_relative "../atoms/git_command"

            # Validate remote exists first
            validation = validate_remote_exists(remote, git_root)
            unless validation[:exists]
              available = validation[:remotes].empty? ? "no remotes configured" : validation[:remotes].join(", ")
              return {
                success: false,
                error: "Remote '#{remote}' not found. Available remotes: #{available}"
              }
            end

            result = Atoms::GitCommand.execute(
              "fetch", remote, branch,
              timeout: @timeout
            )

            if result[:success]
              {success: true, error: nil}
            else
              {success: false, error: "Failed to fetch #{remote}/#{branch}: #{result[:error]}"}
            end
          end

          # Create a worktree with remote tracking
          #
          # @param worktree_path [String] Path for the worktree
          # @param local_branch_name [String] Local branch name
          # @param remote_branch [String] Remote branch reference (e.g., "origin/feature")
          # @param git_root [String] Git repository root
          # @param configure_push [Boolean] Whether to configure push behavior for branch name mismatches
          # @return [Hash] Result with :success, :worktree_path, :branch, :error
          def create_worktree_with_tracking(worktree_path, local_branch_name, remote_branch, git_root, configure_push: true)
            require_relative "../atoms/git_command"

            # Ensure parent directory exists
            parent_dir = File.dirname(worktree_path)
            FileUtils.mkdir_p(parent_dir) unless File.exist?(parent_dir)

            # Create worktree with tracking: git worktree add <path> -b <local> <remote>
            result = Atoms::GitCommand.worktree(
              "add", worktree_path, "-b", local_branch_name, remote_branch,
              timeout: @timeout
            )

            unless result[:success]
              return error_result("Failed to create worktree: #{result[:error]}")
            end

            # Configure push behavior if local and remote branch names differ
            if configure_push && local_branch_name != extract_remote_branch_name(remote_branch)
              configure_push_for_worktree(worktree_path, local_branch_name, remote_branch)
            end

            {
              success: true,
              worktree_path: worktree_path,
              branch: local_branch_name,
              tracking: remote_branch,
              git_root: git_root,
              error: nil
            }
          end

          # Create a worktree for a remote branch
          #
          # @param branch_name [String] Full branch name (e.g., "origin/feature/auth")
          # @param remote_info [Hash] Remote info from detect_remote_branch
          # @param config [WorktreeConfig] Configuration
          # @param git_root [String] Git repository root
          # @return [Hash] Result hash
          def create_for_remote_branch(branch_name, remote_info, config, git_root)
            remote = remote_info[:remote]
            branch = remote_info[:branch]

            # Fetch the remote branch
            fetch_result = fetch_remote_branch(remote, branch, git_root)
            return error_result(fetch_result[:error]) unless fetch_result[:success]

            # Generate local branch name (use full branch path to avoid collisions)
            # For "feature/auth/v1" -> keep as "feature/auth/v1"
            # For "feature/auth" -> keep as "feature/auth"
            local_branch_name = branch

            # Generate directory name by sanitizing branch for directory use
            # "feature/auth/v1" -> "feature-auth-v1"
            require_relative "../atoms/slug_generator"
            directory_name = Atoms::SlugGenerator.to_directory_name(branch)

            # Build worktree path
            worktree_path = File.join(config.absolute_root_path, directory_name)

            # Validate worktree path
            validation = validate_worktree_path(worktree_path, git_root)
            return error_result(validation[:error]) unless validation[:valid]

            # Create worktree with tracking
            # Check if we should configure push for branch name mismatches
            configure_push = if config.respond_to?(:configure_push_for_mismatch?)
              config.configure_push_for_mismatch?
            else
              # For backward compatibility or when config is not available
              # Default to true for branch creation
              true
            end

            result = create_worktree_with_tracking(
              worktree_path,
              local_branch_name,
              branch_name,
              git_root,
              configure_push: configure_push
            )
            return result unless result[:success]

            # Success
            {
              success: true,
              worktree_path: worktree_path,
              branch: local_branch_name,
              tracking: branch_name,
              directory_name: directory_name,
              git_root: git_root,
              error: nil
            }
          end

          # Create a worktree for a local branch
          #
          # @param branch_name [String] Local branch name
          # @param config [WorktreeConfig] Configuration
          # @param git_root [String] Git repository root
          # @return [Hash] Result hash
          def create_for_local_branch(branch_name, config, git_root)
            # Verify branch exists locally
            require_relative "../atoms/git_command"
            check_result = Atoms::GitCommand.execute(
              "show-ref", "--verify", "--quiet", "refs/heads/#{branch_name}",
              timeout: @timeout
            )

            unless check_result[:success]
              return error_result("Local branch '#{branch_name}' not found")
            end

            # Generate directory name
            require_relative "../atoms/slug_generator"
            directory_name = Atoms::SlugGenerator.to_directory_name(branch_name)

            # Build worktree path
            worktree_path = File.join(config.absolute_root_path, directory_name)

            # Validate worktree path
            validation = validate_worktree_path(worktree_path, git_root)
            return error_result(validation[:error]) unless validation[:valid]

            # Create worktree (no tracking for local branches)
            result = create_worktree(worktree_path, branch_name, git_root)
            return result unless result[:success]

            # Success
            {
              success: true,
              worktree_path: worktree_path,
              branch: branch_name,
              tracking: nil,
              directory_name: directory_name,
              git_root: git_root,
              error: nil
            }
          end

          # Format PR name using template
          #
          # @param template [String] Template string with {variables}
          # @param pr_data [Hash] PR data hash
          # @return [String] Formatted string
          #
          # @example
          #   format_pr_name("pr-{number}-{slug}", { number: 26, title: "Add Feature" })
          #   # => "pr-26-add-feature"
          def format_pr_name(template, pr_data)
            require_relative "../atoms/slug_generator"

            result = template.dup

            # Replace {number}
            result.gsub!("{number}", pr_data[:number].to_s)

            # Replace {slug} with slugified title
            if pr_data[:title]
              slug = Atoms::SlugGenerator.from_title(pr_data[:title])
              result.gsub!("{slug}", slug)
            end

            # Replace {title_slug} (alias for slug)
            if pr_data[:title]
              slug = Atoms::SlugGenerator.from_title(pr_data[:title])
              result.gsub!("{title_slug}", slug)
            end

            # Replace {base_branch}
            result.gsub!("{base_branch}", pr_data[:base_branch].to_s) if pr_data[:base_branch]

            result
          end

          # Extract just the branch name from a remote branch reference
          #
          # @param remote_branch [String] Remote branch reference (e.g., "origin/feature")
          # @return [String] Branch name (e.g., "feature")
          def extract_remote_branch_name(remote_branch)
            remote_info = detect_remote_branch(remote_branch)
            remote_info ? remote_info[:branch] : remote_branch
          end

          # Configure push behavior for a worktree when local and remote branch names differ
          #
          # @param worktree_path [String] Path to the worktree
          # @param local_branch_name [String] Local branch name
          # @param remote_branch [String] Remote branch reference
          def configure_push_for_worktree(worktree_path, local_branch_name, remote_branch)
            require_relative "../atoms/git_command"

            # Run git config commands within the worktree
            Dir.chdir(worktree_path) do
              # Set push.default to "upstream" to push to the configured upstream regardless of name
              Atoms::GitCommand.execute("config", "push.default", "upstream", timeout: 5)

              # Set push.autoSetupRemote to true for convenience
              Atoms::GitCommand.execute("config", "push.autoSetupRemote", "true", timeout: 5)
            end
          end
        end
      end
    end
  end
end
