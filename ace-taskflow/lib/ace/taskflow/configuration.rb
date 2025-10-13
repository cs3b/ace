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
        config.dig("directories", "ideas") || "backlog/ideas"
      end

      # Get release ideas subdirectory name (for use within release directories)
      # This extracts just the subdirectory name, separate from the full ideas_dir path
      def release_ideas_subdir
        config.dig("directories", "release_ideas") || "ideas"
      end

      # Get done directory name
      def done_dir
        config.dig("directories", "done") || "done"
      end

      # Get backlog directory name
      def backlog_dir
        config.dig("directories", "backlog") || "backlog"
      end

      # Get pending directory name
      def pending_dir
        config.dig("directories", "pending") || "pending"
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

      # Get idea-specific configuration
      def idea_config
        config["idea"] || default_idea_config
      end

      # Get task-specific configuration
      def task_config
        config["task"] || default_task_config
      end

      # Get release-specific configuration
      def release_config
        config["release"] || default_release_config
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
        taskflow_dir = File.join(Dir.pwd, ".ace", "taskflow")
        FileUtils.mkdir_p(taskflow_dir)

        config_file = File.join(taskflow_dir, "config.yml")
        unless File.exist?(config_file)
          File.write(config_file, default_config_yaml)
        end

        true
      end

      private

      def default_idea_config
        {
          "directory" => "ideas",
          "template" => "# %{title}\n\n%{content}\n\n---\nCaptured: %{timestamp}",
          "file_naming" => {
            "pattern" => "%{timestamp}-%{title}",
            "timestamp_format" => "%Y%m%d-%H%M%S"
          }
        }
      end

      def default_task_config
        {
          "directory" => ".",
          "use_release_dirs" => true,
          "tasks_subdir" => "t"
        }
      end

      def default_release_config
        {
          "current" => ".",
          "completed" => "done"
        }
      end

      def default_config_yaml
        <<~YAML
          # ace-taskflow configuration

          taskflow:
            # Root directory for all taskflow data
            root: ".ace-taskflow"

            # Task directory name
            task_dir: "t"

            # Release management
            active_strategy: "lowest"          # How to pick primary active release
            allow_multiple_active: true        # Allow multiple active releases

            # Qualified references
            references:
              allow_qualified: true            # Enable v.0.9.0+018 syntax
              allow_cross_release: true        # Can reference other releases

            # Default contexts
            defaults:
              idea_location: "active"          # Where ideas go by default
              task_location: "active"          # Where new tasks go by default

            # Idea configuration
            idea:
              directory: "ideas"
              template: |
                # %{title}

                ## Description
                %{content}

                ## Metadata
                - **Captured**: %{timestamp}
                - **Author**: %{author}
                - **Status**: unprocessed
              file_naming:
                pattern: "%{timestamp}-%{title}"
                timestamp_format: "%Y%m%d-%H%M%S"
        YAML
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