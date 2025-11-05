# frozen_string_literal: true

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
            "mise_trust_auto" => true,
            "auto_navigate" => true,
            "task" => {
              "directory_format" => "task.{task_id}",
              "branch_format" => "{id}-{slug}",
              "auto_mark_in_progress" => true,
              "auto_commit_task" => true,
              "commit_message_format" => "chore({release}-{task_id}): mark as in-progress, creating worktree for {slug}",
              "add_worktree_metadata" => true
            },
            "cleanup" => {
              "on_merge" => false,
              "on_delete" => true
            }
          }.freeze

          # Configuration namespace paths
          CONFIG_NAMESPACE = ["git", "worktree"].freeze

          attr_reader :root_path, :mise_trust_auto, :auto_navigate, :task_config, :cleanup_config

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

          # Check if mise trust should be automatic
          #
          # @return [Boolean] true if mise trust should run automatically
          def mise_trust_auto?
            @mise_trust_auto
          end

          # Check if auto-navigation should be performed
          #
          # @return [Boolean] true if auto-navigation should be performed
          def auto_navigate?
            @auto_navigate
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

          # Format a directory path using task metadata
          #
          # @param task_metadata [TaskMetadata] Task metadata
          # @param counter [Integer, nil] Counter for multiple worktrees of same task
          # @return [String] Formatted directory path
          #
          # @example
          #   config.format_directory(task) # => "task.081"
          #   config.format_directory(task, 2) # => "task.081-2"
          def format_directory(task_metadata, counter = nil)
            template = directory_format
            formatted = apply_template_variables(template, task_metadata)

            # Add counter if provided
            formatted = "#{formatted}-#{counter}" if counter

            formatted
          end

          # Format a branch name using task metadata
          #
          # @param task_metadata [TaskMetadata] Task metadata
          # @return [String] Formatted branch name
          #
          # @example
          #   config.format_branch(task) # => "081-fix-authentication-bug"
          def format_branch(task_metadata)
            template = branch_format
            apply_template_variables(template, task_metadata)
          end

          # Format a commit message for task updates
          #
          # @param task_metadata [TaskMetadata] Task metadata
          # @return [String] Formatted commit message
          #
          # @example
          #   config.format_commit_message(task) # => "chore(task-081): mark as in-progress, creating worktree"
          def format_commit_message(task_metadata)
            template = commit_message_format
            apply_template_variables(template, task_metadata)
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

            # Validate template formats
            unless directory_format.is_a?(String) && !directory_format.empty?
              errors << "directory_format must be a non-empty string"
            end

            unless branch_format.is_a?(String) && !branch_format.empty?
              errors << "branch_format must be a non-empty string"
            end

            # Validate template variables
            templates_with_requirements = {
              directory_format => [%w[task_id], directory_format],
              branch_format => [%w[id slug], branch_format],
              commit_message_format => [%w[release task_id slug], commit_message_format]
            }

            templates_with_requirements.each do |template_key, (required_vars, template_value)|
              missing_vars = required_vars.reject { |var| template_value.include?("{#{var}}") }
              if missing_vars.any?
                errors << "#{template_value} should include common template variables: #{missing_vars.join(', ')}"
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
              mise_trust_auto: mise_trust_auto?,
              task: @task_config.dup,
              cleanup: @cleanup_config.dup
            }
          end

          private

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
            @mise_trust_auto = @merged_config["mise_trust_auto"]
            @auto_navigate = @merged_config["auto_navigate"]
            @task_config = @merged_config["task"] || {}
            @cleanup_config = @merged_config["cleanup"] || {}
          end

          # Expand root path to absolute path
          #
          # @return [String] Absolute path
          def expand_root_path
            require_relative "../atoms/path_expander"
            Atoms::PathExpander.expand(@root_path)
          end

          # Apply template variables to a format string
          #
          # @param template [String] Template string with {variable} placeholders
          # @param task_metadata [TaskMetadata] Task metadata
          # @return [String] Formatted string with variables replaced
          def apply_template_variables(template, task_metadata)
            formatted = template.dup

            # Available template variables
            variables = {
              "id" => task_metadata.id,
              "task_id" => task_metadata.task_id,
              "release" => task_metadata.release,
              "slug" => task_metadata.slug
            }

            # Replace each variable
            variables.each do |key, value|
              formatted = formatted.gsub("{#{key}}", value.to_s)
            end

            formatted
          end
        end
      end
    end
  end
end