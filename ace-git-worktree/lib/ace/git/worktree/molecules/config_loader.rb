# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Molecules
        # Configuration loader molecule
        #
        # Loads and merges worktree configuration using the ace-core cascade system.
        # Handles configuration validation and provides access to merged configuration.
        #
        # @example Load configuration for current project
        #   loader = ConfigLoader.new(Dir.pwd)
        #   config = loader.load
        #
        # @example Load with custom project root
        #   loader = ConfigLoader.new("/path/to/project")
        #   config = loader.load
        class ConfigLoader
          # Configuration namespace for ace-core
          CONFIG_NAMESPACE = ["git", "worktree"].freeze

          # Initialize a new ConfigLoader
          #
          # @param project_root [String] Project root directory
          def initialize(project_root = Dir.pwd)
            @project_root = project_root
          end

          # Load and merge worktree configuration
          #
          # @return [WorktreeConfig] Loaded and validated configuration
          #
          # @example
          #   loader = ConfigLoader.new
          #   config = loader.load
          #   config.root_path # => ".ace-wt"
          #   config.mise_trust_auto? # => true
          def load
            # Load configuration from ace-core cascade
            config_hash = load_from_ace_core

            # Create configuration object
            config = Models::WorktreeConfig.new(config_hash, @project_root)

            # Validate configuration
            validate_config(config)

            config
          end

          # Load configuration without validation (for testing)
          #
          # @return [WorktreeConfig] Configuration without validation
          def load_without_validation
            config_hash = load_from_ace_core
            Models::WorktreeConfig.new(config_hash, @project_root)
          end

          # Check if configuration exists
          #
          # @return [Boolean] true if configuration files exist
          def config_exists?
            # Check for configuration files in expected locations
            config_files.each.any? { |file| File.exist?(file) }
          end

          # Get list of configuration files that would be checked
          #
          # @return [Array<String>] List of configuration file paths
          def config_files
            [
              File.join(@project_root, ".ace", "git", "worktree.yml"),
              File.join(@project_root, ".ace.example", "git", "worktree.yml"),
              File.expand_path("~/.ace/git/worktree.yml")
            ]
          end

          # Reset configuration cache
          def reset_cache!
            @config_hash = nil
          end

          private

          # Load configuration using ace-core cascade
          #
          # @return [Hash] Configuration hash from ace-core
          def load_from_ace_core
            return @config_hash if @config_hash

            begin
              require "ace/core"
              config_hash = Ace::Core.get(*CONFIG_NAMESPACE)
              @config_hash = config_hash || {}
            rescue LoadError
              # ace-core not available, return empty config
              @config_hash = {}
            rescue StandardError => e
              # Error loading configuration, log and return empty
              warn "Warning: Error loading worktree configuration: #{e.message}"
              @config_hash = {}
            end
          end

          # Validate loaded configuration
          #
          # @param config [WorktreeConfig] Configuration to validate
          # @raise [ArgumentError] If configuration is invalid
          def validate_config(config)
            errors = config.validate

            if errors.any?
              raise ArgumentError, "Invalid worktree configuration:\n#{errors.map { |e| "  - #{e}" }.join("\n")}"
            end
          end
        end
      end
    end
  end
end