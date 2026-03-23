# frozen_string_literal: true

require_relative "../atoms/task_id_extractor"

module Ace
  module Git
    module Worktree
      module Models
        # Configuration model for worktree settings
        #
        # Represents the configuration loaded from .ace/git/worktree.yml
        # with defaults, validation, and accessors for all configuration options.
        #
        # @example Create configuration with defaults
        #   config = WorktreeConfig.new
        #   config.root_path # => ".ace-wt"
        #
        # @example Load from configuration hash
        #   config = WorktreeConfig.new({
        #     "git" => {
        #       "worktree" => {
        #         "root_path" => "~/worktrees",
        #         "mise_trust_auto" => false
        #       }
        #     }
        #   })
        class WorktreeConfig
          # Default configuration values
          DEFAULT_CONFIG = {
            "root_path" => ".ace-wt",
            "auto_navigate" => true,
            "tmux" => false,
            "mise_trust_auto" => true,
            "task" => {
              "directory_format" => "t.{task_id}",
              "branch_format" => "{id}-{slug}",
              "auto_mark_in_progress" => true,
              "auto_commit_task" => true,
              "auto_push_task" => true,
              "push_remote" => "origin",
              "commit_message_format" => "chore({task_id}): mark as in-progress, creating worktree for {slug}",
              "add_worktree_metadata" => true,
              "auto_setup_upstream" => false,
              "auto_create_pr" => false,
              "pr_title_format" => "{id} - {slug}",
              "create_current_symlink" => true,
              "current_symlink_name" => "_current"
            },
            "pr" => {
              "directory_format" => "ace-pr-{number}",
              "branch_format" => "pr-{number}-{slug}",
              "remote_name" => "origin",
              "fetch_before_create" => true,
              "configure_push_for_mismatch" => true
            },
            "branch" => {
              "fetch_if_remote" => true,
              "auto_detect_remote" => true
            },
            "cleanup" => {
              "on_merge" => false,
              "on_delete" => true
            },
            "hooks" => {
              "after_create" => []
            }
          }.freeze

          # Configuration namespace paths
          CONFIG_NAMESPACE = ["git", "worktree"].freeze

          attr_reader :root_path, :auto_navigate, :tmux, :mise_trust_auto, :task_config, :pr_config, :branch_config, :cleanup_config, :hooks_config

          # Initialize a new WorktreeConfig
          #
          # @param config_hash [Hash] Configuration hash (typically from ace-core)
          # @param project_root [String] Project root directory for relative paths
          def initialize(config_hash = {}, project_root = Dir.pwd)
            @project_root = project_root
            @raw_config = extract_worktree_config(config_hash)
            @merged_config = merge_with_defaults(@raw_config)

            initialize_attributes
          end

          # Get the directory format for task-based worktrees
          #
          # @return [String] Directory format template
          def directory_format
            @task_config["directory_format"]
          end

          # Get the branch format for task-based worktrees
          #
          # @return [String] Branch format template
          def branch_format
            @task_config["branch_format"]
          end

          # Check if auto-navigation should be performed
          #
          # @return [Boolean] true if auto-navigation should be performed
          def auto_navigate?
            @auto_navigate
          end

          # Check if tmux session should be launched after worktree creation
          #
          # @return [Boolean] true if tmux launch is enabled
          def tmux?
            @tmux
          end

          # Check if mise should automatically trust worktree directories
          #
          # @return [Boolean] true if mise auto-trust is enabled
          def mise_trust_auto?
            @mise_trust_auto
          end

          # Check if tasks should be marked as in-progress automatically
          #
          # @return [Boolean] true if tasks should be marked in-progress
          def auto_mark_in_progress?
            @task_config["auto_mark_in_progress"]
          end

          # Check if task changes should be committed automatically
          #
          # @return [Boolean] true if task changes should be committed
          def auto_commit_task?
            @task_config["auto_commit_task"]
          end

          # Check if task changes should be pushed automatically
          #
          # @return [Boolean] true if task changes should be pushed
          def auto_push_task?
            @task_config["auto_push_task"] != false
          end

          # Get the remote for pushing task changes
          #
          # @return [String] Remote name (default: "origin")
          def push_remote
            @task_config["push_remote"] || "origin"
          end

          # Get the commit message format for task updates
          #
          # @return [String] Commit message template
          def commit_message_format
            @task_config["commit_message_format"]
          end

          # Check if worktree metadata should be added to tasks
          #
          # @return [Boolean] true if metadata should be added
          def add_worktree_metadata?
            @task_config["add_worktree_metadata"]
          end

          # Check if new worktree branch should be pushed to remote with upstream tracking
          #
          # @return [Boolean] true if upstream setup is enabled
          def auto_setup_upstream?
            @task_config["auto_setup_upstream"]
          end

          # Check if draft PR should be created automatically
          #
          # @return [Boolean] true if auto PR creation is enabled
          def auto_create_pr?
            @task_config["auto_create_pr"]
          end

          # Get the PR title format template
          #
          # @return [String] PR title format template
          def pr_title_format
            @task_config["pr_title_format"]
          end

          # Check if _current symlink should be created
          #
          # @return [Boolean] true if symlink should be created
          def create_current_symlink?
            @task_config["create_current_symlink"] != false
          end

          # Get the name for the _current symlink
          #
          # @return [String] Symlink name (default: "_current")
          def current_symlink_name
            @task_config["current_symlink_name"] || "_current"
          end

          # Format a PR title using task data
          #
          # @param task_data [Hash] Task data hash from ace-task
          # @return [String] Formatted PR title
          #
          # @example
          #   config.format_pr_title(task) # => "081 - fix-authentication-bug"
          def format_pr_title(task_data)
            template = pr_title_format
            apply_template_variables(template, task_data)
          end

          # Get the root path for worktrees (expanded and absolute)
          #
          # @return [String] Absolute path to worktree root directory
          def absolute_root_path
            @absolute_root_path ||= expand_root_path
          end

          # Check if worktrees should be cleaned up on branch merge
          #
          # @return [Boolean] true if cleanup on merge
          def cleanup_on_merge?
            @cleanup_config["on_merge"]
          end

          # Check if worktrees should be cleaned up on branch delete
          #
          # @return [Boolean] true if cleanup on delete
          def cleanup_on_delete?
            @cleanup_config["on_delete"]
          end

          # Get after-create hooks configuration
          #
          # @return [Array<Hash>] Array of hook definitions
          def after_create_hooks
            @hooks_config["after_create"] || []
          end

          # Check if push should be configured for PR branches with name mismatches
          #
          # @return [Boolean] true if push should be configured for mismatched branch names
          def configure_push_for_mismatch?
            @pr_config["configure_push_for_mismatch"]
          end

          # Check if hooks are configured
          #
          # @return [Boolean] true if any hooks are configured
          def hooks_enabled?
            hooks = after_create_hooks
            hooks.is_a?(Array) && hooks.any?
          end

          # Format a directory path using task data
          #
          # @param task_data [Hash] Task data hash from ace-task
          # @param counter [Integer, nil] Counter for multiple worktrees of same task
          # @return [String] Formatted directory path
          #
          # @example
          #   config.format_directory(task) # => "t.081"
          #   config.format_directory(task, 2) # => "t.081-2"
          def format_directory(task_data, counter = nil)
            template = directory_format
            formatted = apply_template_variables(template, task_data)

            # Add counter if provided
            formatted = "#{formatted}-#{counter}" if counter

            formatted
          end

          # Format a branch name using task data
          #
          # @param task_data [Hash] Task data hash from ace-task
          # @return [String] Formatted branch name
          #
          # @example
          #   config.format_branch(task) # => "081-fix-authentication-bug"
          def format_branch(task_data)
            template = branch_format
            apply_template_variables(template, task_data)
          end

          # Format a commit message for task updates
          #
          # @param task_data [Hash] Task data hash from ace-task
          # @return [String] Formatted commit message
          #
          # @example
          #   config.format_commit_message(task) # => "chore(task-081): mark as in-progress, creating worktree"
          def format_commit_message(task_data)
            template = commit_message_format
            apply_template_variables(template, task_data)
          end

          # Validate configuration settings
          #
          # @return [Array<String>] Array of validation error messages (empty if valid)
          def validate
            errors = []

            # Validate root_path
            unless root_path.is_a?(String) && !root_path.empty?
              errors << "root_path must be a non-empty string"
            end

            # Validate task template formats
            unless directory_format.is_a?(String) && !directory_format.empty?
              errors << "task.directory_format must be a non-empty string"
            end

            unless branch_format.is_a?(String) && !branch_format.empty?
              errors << "task.branch_format must be a non-empty string"
            end

            # Validate PR template formats
            pr_dir_format = @pr_config["directory_format"]
            unless pr_dir_format.is_a?(String) && !pr_dir_format.empty?
              errors << "pr.directory_format must be a non-empty string"
            end

            pr_branch_format = @pr_config["branch_format"]
            unless pr_branch_format.is_a?(String) && !pr_branch_format.empty?
              errors << "pr.branch_format must be a non-empty string"
            end

            # Validate template variables for task configuration
            task_templates = {
              "task.directory_format" => {template: directory_format, valid_vars: %w[task_id id slug]},
              "task.branch_format" => {template: branch_format, valid_vars: %w[id slug task_id]},
              "task.commit_message_format" => {template: commit_message_format, valid_vars: %w[task_id slug id]}
            }

            task_templates.each do |name, config|
              invalid_vars = find_invalid_template_variables(config[:template], config[:valid_vars])
              if invalid_vars.any?
                errors << "#{name} contains invalid variables: #{invalid_vars.join(", ")}. Valid variables: #{config[:valid_vars].map { |v| "{#{v}}" }.join(", ")}"
              end

              # Warn if template has no variables (except for commit_message_format which is optional)
              unless name == "task.commit_message_format"
                if config[:template] && !config[:template].match?(/\{[^}]+\}/)
                  errors << "#{name} should include at least one template variable from: #{config[:valid_vars].map { |v| "{#{v}}" }.join(", ")}"
                end
              end
            end

            # Validate template variables for PR configuration
            pr_templates = {
              "pr.directory_format" => {template: pr_dir_format, valid_vars: %w[number slug title base_branch]},
              "pr.branch_format" => {template: pr_branch_format, valid_vars: %w[number slug title base_branch]}
            }

            pr_templates.each do |name, config|
              invalid_vars = find_invalid_template_variables(config[:template], config[:valid_vars])
              if invalid_vars.any?
                errors << "#{name} contains invalid variables: #{invalid_vars.join(", ")}. Valid variables: #{config[:valid_vars].map { |v| "{#{v}}" }.join(", ")}"
              end
            end

            errors
          end

          # Get configuration as a hash
          #
          # @return [Hash] Configuration hash
          def to_h
            {
              root_path: root_path,
              auto_navigate: auto_navigate?,
              mise_trust_auto: mise_trust_auto?,
              task: @task_config.dup,
              cleanup: @cleanup_config.dup,
              hooks: @hooks_config.dup
            }
          end

          private

          # Find invalid template variables in a template string
          #
          # @param template [String] Template string with {variable} placeholders
          # @param valid_vars [Array<String>] List of valid variable names
          # @return [Array<String>] List of invalid variable names
          def find_invalid_template_variables(template, valid_vars)
            return [] unless template.is_a?(String)

            # Extract all variables from template
            template_vars = template.scan(/\{(\w+)\}/).flatten

            # Find variables that are not in the valid list
            template_vars.uniq.reject { |var| valid_vars.include?(var) }
          end

          # Extract worktree configuration from nested config hash
          #
          # @param config_hash [Hash] Full configuration hash
          # @return [Hash] Worktree-specific configuration
          def extract_worktree_config(config_hash)
            CONFIG_NAMESPACE.reduce(config_hash) do |current, key|
              current&.dig(key) || {}
            end
          end

          # Merge configuration with defaults
          #
          # @param config [Hash] User configuration
          # @return [Hash] Merged configuration
          def merge_with_defaults(config)
            deep_merge(DEFAULT_CONFIG.dup, config)
          end

          # Deep merge two hashes
          #
          # @param target [Hash] Target hash
          # @param source [Hash] Source hash
          # @return [Hash] Merged hash
          def deep_merge(target, source)
            target.merge(source) do |key, old_val, new_val|
              if old_val.is_a?(Hash) && new_val.is_a?(Hash)
                deep_merge(old_val, new_val)
              else
                new_val.nil? ? old_val : new_val
              end
            end
          end

          # Initialize instance attributes from merged configuration
          def initialize_attributes
            @root_path = @merged_config["root_path"]
            @auto_navigate = @merged_config["auto_navigate"]
            @tmux = @merged_config["tmux"]
            @mise_trust_auto = @merged_config["mise_trust_auto"]
            @task_config = @merged_config["task"] || {}
            @pr_config = @merged_config["pr"] || {}
            @branch_config = @merged_config["branch"] || {}
            @cleanup_config = @merged_config["cleanup"] || {}
            @hooks_config = @merged_config["hooks"] || {}
          end

          # Expand root path to absolute path
          #
          # @return [String] Absolute path
          def expand_root_path
            require_relative "../atoms/path_expander"
            Atoms::PathExpander.expand(@root_path, @project_root)
          end

          # Apply template variables to a format string
          #
          # @param template [String] Template string with {variable} placeholders
          # @param task_data [Hash] Task data hash from ace-task
          # @return [String] Formatted string with variables replaced
          def apply_template_variables(template, task_data)
            formatted = template.dup

            # Extract task number from ID for backward compatibility
            task_id = extract_task_number(task_data)

            # Available template variables
            variables = {
              "id" => task_id,
              "task_id" => task_id,
              "slug" => create_slug(task_data[:title] || "unknown-task")
            }

            # Replace each variable
            variables.each do |key, value|
              formatted = formatted.gsub("{#{key}}", value.to_s)
            end

            formatted
          end

          # Extract task number from task data
          #
          # @param task_data [Hash] Task data hash
          # @return [String] Task number (e.g., "094")
          def extract_task_number(task_data)
            # Use shared extractor that preserves subtask IDs (e.g., "121.01")
            Atoms::TaskIDExtractor.extract(task_data)
          end

          # Create URL-friendly slug from title
          #
          # @param title [String] Task title
          # @return [String] URL-friendly slug
          def create_slug(title)
            return "unknown-task" unless title

            # Convert to lowercase, replace spaces and special chars with hyphens
            title.downcase
              .gsub(/[^a-z0-9\s-]/, "") # Remove special chars except spaces and hyphens
              .gsub(/\s+/, "-").squeeze("-")            # Replace multiple hyphens with single
              .gsub(/^-|-$/, "")          # Remove leading/trailing hyphens
              .tap { |slug| slug.empty? ? "unknown-task" : slug }
          end
        end
      end
    end
  end
end
