# frozen_string_literal: true

require "yaml"
require "ace/support/config"

module Ace
  module Git
    module Worktree
      module Molecules
        # Configuration loader molecule
        #
        # Loads and merges worktree configuration using ace-config cascade system.
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
            # Load configuration using ace-config cascade
            config_hash = load_config

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
            config_hash = load_config
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
              File.join(@project_root, ".ace-defaults", "git", "worktree.yml"),
              File.expand_path("~/.ace/git/worktree.yml")
            ]
          end

          # Reset configuration cache
          def reset_cache!
            @config_hash = nil
          end

          private

          # Load configuration using ace-config cascade
          #
          # @return [Hash] Configuration hash from ace-config
          def load_config
            return @config_hash if @config_hash

            gem_root = Gem.loaded_specs["ace-git-worktree"]&.gem_dir ||
              File.expand_path("../../../../..", __dir__)

            resolver = Ace::Support::Config.create(
              config_dir: ".ace",
              defaults_dir: ".ace-defaults",
              gem_path: gem_root
            )

            # Resolve config for git/worktree namespace
            config = resolver.resolve_namespace("git", filename: "worktree")

            @config_hash = config.data
          rescue => e
            warn "Warning: Error loading worktree configuration: #{e.message}"
            @config_hash = {}
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
