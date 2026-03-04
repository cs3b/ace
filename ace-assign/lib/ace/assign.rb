# frozen_string_literal: true

require_relative "assign/version"
require "ace/support/config"
require "ace/support/fs"
require "ace/core/cli/error"
require "pathname"

# CLI and commands
require_relative "assign/cli"

module Ace
  module Assign
    # Base error class for all ace-assign exceptions.
    # Inherits from Ace::Core::CLI::Error to support exception-based
    # exit code pattern (per ADR-023).
    #
    # Subclasses should call super with appropriate exit_code.
    class Error < Ace::Core::CLI::Error
      def initialize(message, exit_code: 1)
        super(message, exit_code: exit_code)
      end
    end

    # Assignment-related errors
    module AssignmentErrors
      class NotFound < Error
        def initialize(message = "Assignment not found")
          super(message, exit_code: 2)
        end
      end

      class NoActive < Error
        def initialize(message = "No active assignment")
          super(message, exit_code: 2)
        end
      end
    end

    # Config-related errors
    module ConfigErrors
      class NotFound < Error
        def initialize(message = "Configuration not found")
          super(message, exit_code: 3)
        end
      end
    end

    # Phase-related errors
    module PhaseErrors
      class NotFound < Error
        def initialize(message = "Phase not found")
          super(message, exit_code: 4)
        end
      end

      class InvalidState < Error; end
    end

    # Aliases for backward compatibility
    AssignmentNotFoundError = AssignmentErrors::NotFound
    NoActiveAssignmentError = AssignmentErrors::NoActive
    ConfigNotFoundError = ConfigErrors::NotFound
    PhaseNotFoundError = PhaseErrors::NotFound
    InvalidPhaseStateError = PhaseErrors::InvalidState

    # Define module namespaces
    module Commands; end

    # Check if debug mode is enabled
    # @return [Boolean] True if debug mode is enabled
    def self.debug?
      ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
    end

    # Configuration
    # Follows ADR-022: Configuration Default and Override Pattern
    # Uses Ace::Support::Config.create() for configuration cascade resolution
    def self.config
      @config ||= begin
        gem_root = Gem.loaded_specs["ace-assign"]&.gem_dir ||
                   File.expand_path("../..", __dir__)

        resolver = Ace::Support::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        # Resolve config for assign namespace
        config = resolver.resolve_namespace("assign")
        config.data
      rescue StandardError => e
        warn "ace-assign: Could not load config: #{e.class} - #{e.message}" if debug?
        load_gem_defaults_fallback
      end
    end

    # Reset config cache (useful for testing)
    def self.reset_config!
      @config = nil
    end

    # Default cache directory for assignments
    # Returns an absolute path resolved from project root.
    # Respects CACHE_BASE environment variable for sandboxed/isolated testing.
    # Respects PROJECT_ROOT_PATH environment variable for sandboxed/isolated testing.
    # @return [String] Cache directory path (absolute)
    def self.cache_dir
      # Allow explicit CACHE_BASE override for testing/sandboxing
      cache_base = ENV["CACHE_BASE"]
      if cache_base && !cache_base.empty?
        return File.expand_path(cache_base)
      end

      relative_path = config["cache_dir"] || ".ace-local/assign"

      # If already absolute, return as-is
      return relative_path if Pathname.new(relative_path).absolute?

      # Resolve relative to project root (respects PROJECT_ROOT_PATH)
      project_root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
      File.join(project_root, relative_path)
    end

    # Load gem defaults from .ace-defaults/assign/config.yml
    # @return [Hash] Gem defaults hash
    def self.load_gem_defaults
      gem_root = Gem.loaded_specs["ace-assign"]&.gem_dir ||
                 File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace-defaults", "assign", "config.yml")

      return {} unless File.exist?(defaults_path)

      YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
    end

    # Load gem defaults directly as fallback
    # @return [Hash] Defaults hash or empty hash if defaults also fail
    def self.load_gem_defaults_fallback
      load_gem_defaults
    rescue StandardError
      {}
    end
    private_class_method :load_gem_defaults_fallback
  end
end
