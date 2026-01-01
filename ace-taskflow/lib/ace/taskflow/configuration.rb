# frozen_string_literal: true

require_relative "molecules/config_loader"

module Ace
  module Taskflow
    # Central configuration management for ace-taskflow
    class Configuration
      attr_reader :config

      def initialize
        @config = Molecules::ConfigLoader.load
      end

      # Get root directory for taskflow
      def root_directory
        @root_directory ||= Molecules::ConfigLoader.find_root
      end

      # Get task directory name
      def task_dir
        config.dig("directories", "tasks") || config["task_dir"] || "t"
      end

      # Get retrospectives directory name
      def retro_dir
        config.dig("directories", "retros") || "retros"
      end

      # Get ideas directory name
      def ideas_dir
        config.dig("directories", "ideas") || "ideas"
      end

      # Get release ideas subdirectory name (for use within release directories)
      # This extracts just the subdirectory name, separate from the full ideas_dir path
      def release_ideas_subdir
        config.dig("directories", "release_ideas") || "ideas"
      end

      # Get done directory name (completed tasks folder)
      # Reads from "completed" key, with backward compatibility for "done"
      def done_dir
        config.dig("directories", "completed") ||
          config.dig("directories", "done") ||
          "_archive"
      end

      # Get backlog directory name
      def backlog_dir
        config.dig("directories", "backlog") || "_backlog"
      end

      # Get maybe directory name (GTD: ideas that might happen)
      def maybe_dir
        config.dig("directories", "maybe") || "_maybe"
      end

      # Get anyday directory name (GTD: tasks for anytime, no urgency)
      def anyday_dir
        config.dig("directories", "anyday") || "_anyday"
      end

      # Get default glob pattern for all spec files
      # This is the single source of truth for spec file matching
      def default_glob_pattern
        ['**/*.s.md']
      end

      # Get active release selection strategy
      def active_strategy
        config["active_strategy"] || "lowest"
      end

      # Check if multiple active releases are allowed
      def allow_multiple_active?
        config["allow_multiple_active"] != false
      end

      # Check if qualified references are allowed
      def allow_qualified_references?
        config.dig("references", "allow_qualified") != false
      end

      # Check if cross-release references are allowed
      def allow_cross_release?
        config.dig("references", "allow_cross_release") != false
      end

      # Get default idea location
      def default_idea_location
        config.dig("defaults", "idea_location") || "active"
      end

      # Get default task location
      def default_task_location
        config.dig("defaults", "task_location") || "active"
      end

      # Get subtasks display mode
      # @return [String] "enabled" or "disabled"
      def subtasks_display_mode
        config.dig("params", "subtasks") || "enabled"
      end

      # Get terminal statuses for orchestrator auto-completion
      # @return [Array<String>] List of statuses that indicate task completion
      def terminal_statuses
        config["terminal_statuses"] || %w[done cancelled suspended superseded]
      end

      # Status command activity settings (ADR-022 compliant)
      # These are used by TaskActivityAnalyzer for the "ace-taskflow status" command
      #
      # Config key path uses "status" to match the command name.
      #   config.dig("status", "activity", ...) → used for status command settings

      # Get recently done limit for status activity display
      # @return [Integer] Maximum number of recently completed tasks to show (0 to disable)
      def recently_done_limit
        value = config.dig("status", "activity", "recently_done_limit")
        value.nil? ? 3 : [value.to_i, 0].max
      end

      # Get up next limit for status activity display
      # @return [Integer] Maximum number of upcoming tasks to show (0 to disable)
      def up_next_limit
        value = config.dig("status", "activity", "up_next_limit")
        value.nil? ? 3 : [value.to_i, 0].max
      end

      # Check if draft tasks should be included in "Up Next" section
      # @return [Boolean] Whether to include drafts in up next
      def include_drafts_in_up_next?
        config.dig("status", "activity", "include_drafts") || false
      end

      # Get idea-specific configuration
      # Defaults come from .ace-defaults/taskflow/config.yml via ConfigLoader
      def idea_config
        config["idea"] || {}
      end

      # Get task-specific configuration
      # Defaults come from .ace-defaults/taskflow/config.yml via ConfigLoader
      def task_config
        config["task"] || {}
      end

      # Get release-specific configuration
      # Defaults come from .ace-defaults/taskflow/config.yml via ConfigLoader
      def release_config
        config["release"] || {}
      end

      # Reload configuration
      def reload!
        @config = Molecules::ConfigLoader.load
        @root_directory = nil
        self
      end

      # Get configuration value by path
      def get(path)
        Molecules::ConfigLoader.get(path)
      end

      # Check if configuration exists
      def configured?
        File.directory?(root_directory)
      end

      # Initialize root directory structure
      def initialize_structure!
        require "fileutils"

        # Create root directory
        FileUtils.mkdir_p(root_directory)

        # Create standard directories using configured names
        config_obj = self.class.new
        FileUtils.mkdir_p(File.join(root_directory, config_obj.backlog_dir))
        FileUtils.mkdir_p(File.join(root_directory, config_obj.backlog_dir, "ideas"))
        FileUtils.mkdir_p(File.join(root_directory, config_obj.backlog_dir, config_obj.task_dir))
        FileUtils.mkdir_p(File.join(root_directory, config_obj.done_dir))

        # Create initial .ace/taskflow/config.yml if not exists
        # Copy from gem's .ace-defaults/ as the source of truth (ADR-022)
        taskflow_dir = File.join(Dir.pwd, ".ace", "taskflow")
        FileUtils.mkdir_p(taskflow_dir)

        config_file = File.join(taskflow_dir, "config.yml")
        unless File.exist?(config_file)
          # Copy from gem's .ace-defaults/ directory
          gem_root = File.expand_path("../../..", __dir__)
          example_config = File.join(gem_root, ".ace-defaults", "taskflow", "config.yml")

          if File.exist?(example_config)
            FileUtils.cp(example_config, config_file)
          else
            warn "Warning: Default config template not found at #{example_config} for ace-taskflow. " \
                 "This may indicate a gem packaging issue."
          end
        end

        true
      end
    end

    # Module-level configuration accessor
    def self.configuration
      @configuration ||= Configuration.new
    end

    # Configure block
    def self.configure
      yield(configuration)
    end

    # Reset configuration
    def self.reset_configuration!
      @configuration = Configuration.new
    end
  end
end