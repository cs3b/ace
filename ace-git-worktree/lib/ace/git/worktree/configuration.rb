# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      # Configuration module
      #
      # Provides constants and utility methods for the ace-git-worktree gem.
      # Configuration values are loaded from .ace/git/worktree.yml via ace-core cascade.
      # Default values are defined in WorktreeConfig::DEFAULT_CONFIG.
      module Configuration
        # Gem name and identifier
        GEM_NAME = "ace-git-worktree"

        # File and directory names
        MISE_CONFIG_FILE = "mise.toml"
        CONFIG_FILE = "worktree.yml"

        # Configuration paths
        CONFIG_NAMESPACE = ["git", "worktree"].freeze

        # Template variable patterns
        TEMPLATE_VARIABLES = %w[id task_id slug].freeze

        # Git branch name restrictions
        FORBIDDEN_BRANCH_CHARS = /[~\^:*?\[\]]/
        SEPARATOR_CHARS = /[ ._\/\\]+/

        # Task status values
        TASK_STATUSES = %w[pending in-progress done blocked].freeze

        # Task priority values
        TASK_PRIORITIES = %w[high medium low].freeze

        # Output formats
        OUTPUT_FORMATS = %w[table json simple].freeze

        # CLI command names and aliases
        CLI_COMMANDS = {
          "create" => "Create a new worktree",
          "list" => "List all worktrees",
          "switch" => "Switch to a worktree",
          "remove" => "Remove a worktree",
          "prune" => "Clean up deleted worktrees",
          "config" => "Show/manage configuration"
        }.freeze

        CLI_ALIASES = {
          "ls" => "list",
          "rm" => "remove",
          "cd" => "switch"
        }.freeze

        # Help text templates
        HELP_TEMPLATES = {
          usage: "ace-git-worktree <command> [OPTIONS]",
          examples: "See 'ace-git-worktree <command> --help' for examples",
          config_help: "See 'ace-git-worktree config --files' for configuration locations"
        }.freeze

        # Error messages
        ERROR_MESSAGES = {
          not_git_repo: "Not in a git repository",
          task_not_found: "Task not found",
          worktree_not_found: "Worktree not found",
          config_invalid: "Invalid configuration",
          command_failed: "Command failed",
          unexpected_error: "Unexpected error"
        }.freeze

        # Success messages
        SUCCESS_MESSAGES = {
          worktree_created: "Worktree created successfully",
          worktree_removed: "Worktree removed successfully",
          config_valid: "Configuration is valid",
          cleanup_completed: "Cleanup completed successfully"
        }.freeze

        # Warning messages
        WARNING_MESSAGES = {
          mise_trust_failed: "Failed to trust mise configuration",
          task_commit_failed: "Failed to commit task changes",
          metadata_add_failed: "Failed to add worktree metadata",
          uncommitted_changes: "Worktree has uncommitted changes"
        }.freeze

        # Validate template variables
        #
        # @param template [String] Template string to validate
        # @return [Array<String>] Array of missing variables (empty if valid)
        def self.validate_template_variables(template)
          return [] unless template.is_a?(String)

          used_variables = template.scan(/\{([^}]+)\}/).flatten
          TEMPLATE_VARIABLES - used_variables
        end

        # Validate configuration hash
        #
        # @param config [Hash] Configuration to validate
        # @return [Array<String>] Array of error messages (empty if valid)
        def self.validate_configuration(config)
          errors = []

          # Validate root_path
          unless config["root_path"].is_a?(String) && !config["root_path"].empty?
            errors << "root_path must be a non-empty string"
          end

          # Validate task section
          task_config = config["task"] || {}

          unless task_config["directory_format"].is_a?(String) && !task_config["directory_format"].empty?
            errors << "task.directory_format must be a non-empty string"
          end

          unless task_config["branch_format"].is_a?(String) && !task_config["branch_format"].empty?
            errors << "task.branch_format must be a non-empty string"
          end

          # Validate template variables
          [task_config["directory_format"], task_config["branch_format"], task_config["commit_message_format"]].each do |template|
            next unless template.is_a?(String)

            missing = validate_template_variables(template)
            if missing.any?
              errors << "#{template} should include variables: #{missing.join(", ")}"
            end
          end

          errors
        end

        # Get command description
        #
        # @param command_name [String] Command name
        # @return [String] Command description or nil if not found
        def self.get_command_description(command_name)
          CLI_COMMANDS[command_name] || CLI_ALIASES[command_name]
        end

        # Check if command exists
        #
        # @param command_name [String] Command name
        # @return [Boolean] true if command exists
        def self.command_exists?(command_name)
          CLI_COMMANDS.key?(command_name) || CLI_ALIASES.key?(command_name)
        end

        # Resolve command alias
        #
        # @param command_name [String] Command name or alias
        # @return [String] Resolved command name
        def self.resolve_command_alias(command_name)
          CLI_ALIASES[command_name] || command_name
        end

        # Get all available commands
        #
        # @return [Array<String>] Array of command names
        def self.available_commands
          (CLI_COMMANDS.keys + CLI_ALIASES.keys).sort
        end
      end
    end
  end
end
