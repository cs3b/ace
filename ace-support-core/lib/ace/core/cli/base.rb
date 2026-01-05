# frozen_string_literal: true

require "thor"

module Ace
  module Core
    module CLI
      # Base class for ACE CLI commands built on Thor.
      #
      # Provides common patterns used across all ace-* gems:
      # - exit_on_failure? returns true for proper error handling
      # - Standard --quiet and --verbose class options
      # - Version command helper
      # - Common patterns for default task delegation
      #
      # @example Usage in a gem's CLI
      #   require "ace/core/cli/base"
      #
      #   class CLI < Ace::Core::CLI::Base
      #     default_task :my_command
      #
      #     desc "my_command", "Description"
      #     def my_command
      #       # implementation
      #     end
      #
      #     # Define version with the gem's VERSION constant
      #     version_command "my-gem", Ace::MyGem::VERSION
      #   end
      #
      # @example ConfigSummary usage in command classes
      #   # ConfigSummary only displays when --verbose is used.
      #   # This keeps normal command output clean and readable.
      #   #
      #   # Normal command (no config shown):
      #   #   $ ace-gem command
      #   #   (output only, no config summary)
      #   #
      #   # With --verbose flag (config shown):
      #   #   $ ace-gem --verbose command
      #   #   Config: key=value key2=value2
      #   #   (output...)
      #   #
      #   def execute(args = [])
      #     # Check for --help flag BEFORE displaying config
      #     return show_help if args.include?("--help") || args.include?("-h")
      #
      #     # Config is NOT shown by default (only when --verbose is used)
      #     Ace::Core::Atoms::ConfigSummary.display_if_needed(
      #       command: "mycommand",
      #       config: MyGem.config,
      #       defaults: MyGem.default_config,
      #       options: @options,
      #       args: args
      #     )
      #     # ... rest of implementation
      #   end
      #   #
      #   # Note: display_if_needed automatically checks both --help and --verbose,
      #   # so config is only shown when verbose is true AND help was not requested.
      #
      class Base < Thor
        def self.exit_on_failure?
          true
        end

        class_option :quiet, type: :boolean, aliases: "-q", desc: "Suppress config summary output"
        class_option :verbose, type: :boolean, aliases: "-v", desc: "Enable verbose output"
        class_option :debug, type: :boolean, aliases: "-d", desc: "Enable debug output"

        # Helper to define a standard version command
        #
        # @param gem_name [String] Name of the gem (e.g., "ace-review")
        # @param version [String] Version string (e.g., "0.1.0")
        # @example
        #   version_command "ace-review", Ace::Review::VERSION
        def self.version_command(gem_name, version)
          desc "version", "Show version"
          define_method(:version) do
            puts "#{gem_name} #{version}"
            0
          end
          map "--version" => :version
          # Note: -v is reserved for --verbose; version only via --version
        end

        # Common respond_to_missing? implementation for CLIs that delegate
        # unknown commands to their default task.
        #
        # Override this method if you need conditional delegation (like ace-git).
        def respond_to_missing?(_method_name, _include_private = false)
          true
        end
      end
    end
  end
end
