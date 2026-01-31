# frozen_string_literal: true

require_relative "../../atoms/config_summary"
require_relative "base"

module Ace
  module Core
    module CLI
      module DryCli
        # Mixin for integrating ConfigSummary with dry-cli commands.
        #
        # This mixin provides methods to display configuration summaries
        # in dry-cli commands, maintaining consistency with the Thor-based
        # CLI patterns.
        #
        # @example Including in a command
        #   require "ace/core/cli/dry_cli/config_summary_mixin"
        #
        #   class MyCommand < Dry::CLI::Command
        #     include Ace::Core::CLI::DryCli::ConfigSummaryMixin
        #
        #     desc "My command description"
        #     option :quiet, type: :boolean, default: false
        #     option :verbose, type: :boolean, default: false
        #
        #     def call(**options)
        #       display_config_summary("my-command", options)
        #       # ... rest of implementation ...
        #     end
        #
        #     private
        #
        #     # Provide gem configuration for ConfigSummary
        #     def gem_config
        #       MyGem.config
        #     end
        #
        #     def gem_defaults
        #       MyGem.default_config
        #     end
        #   end
        #
        # @note Config is displayed unless quiet mode is enabled,
        #       matching Thor-based CLI patterns per docs/ace-gems.g.md.
        module ConfigSummaryMixin
          # Include Base for shared quiet?/verbose?/debug? methods
          include Base

          # Display configuration summary to stderr.
          #
          # Config is shown unless quiet mode is enabled (options[:quiet] == true).
          # This matches the Thor-based CLI pattern documented in docs/ace-gems.g.md.
          #
          # @param command_name [String] Command name for context
          # @param options [Hash] Command options hash
          # @param summary_keys [Array<String>, nil] Optional allowlist of keys to include
          # @return [nil]
          #
          # @example Basic usage
          #   def call(**options)
          #     display_config_summary("create", options)
          #     # ... command implementation ...
          #   end
          #
          # @example With key allowlist
          #   def call(**options)
          #     display_config_summary("review", options, summary_keys: %w[model preset])
          #     # ... only show model and preset in config summary ...
          #   end
          def display_config_summary(command_name, options, summary_keys: nil)
            return if quiet?(options)

            # Call the ConfigSummary atom with gem configuration
            # Subclasses must implement gem_config and gem_defaults methods
            Ace::Core::Atoms::ConfigSummary.display(
              command: command_name,
              config: gem_config,
              defaults: gem_defaults,
              options: options,
              quiet: false, # Already checked above
              summary_keys: summary_keys
            )
          end

          # Check if help was requested for this command.
          #
          # In dry-cli, help is typically handled by the framework itself,
          # but this method is provided for consistency with Thor patterns.
          #
          # @param options [Hash] Command options hash
          # @return [Boolean] true if help was requested
          # @note This is an alias for help?(options) from Base for backwards compatibility
          def help_requested?(options)
            help?(options)
          end

          private

          # NOTE: quiet? and verbose? methods are inherited from Base module
          # This avoids duplication and ensures consistent behavior across
          # all dry-cli based commands.

          # Get the gem's effective configuration.
          #
          # Subclasses MUST implement this method to provide their configuration.
          #
          # @raise [NotImplementedError] if not implemented by subclass
          # @return [Hash] Gem's effective configuration
          def gem_config
            raise NotImplementedError, "#{self.class} must implement #gem_config"
          end

          # Get the gem's default configuration.
          #
          # Subclasses MUST implement this method to provide their defaults.
          #
          # @raise [NotImplementedError] if not implemented by subclass
          # @return [Hash] Gem's default configuration
          def gem_defaults
            raise NotImplementedError, "#{self.class} must implement #gem_defaults"
          end

          # Extended mixin with configurable gem class support.
          #
          # This version allows specifying the gem class directly rather than
          # implementing gem_config and gem_defaults methods.
          #
          # @example Usage with gem class
          #   class MyCommand < Dry::CLI::Command
          #     include Ace::Core::CLI::DryCli::ConfigSummaryMixin::GemClass
          #
          #     # Specify the gem class
          #     def self.gem_class
          #       MyGem
          #     end
          #
          #     def call(**options)
          #       display_config_summary("my-command", options)
          #     end
          #   end
          #
          module GemClassMixin
            include ConfigSummaryMixin

            private

            # Get the gem's effective configuration from the gem class.
            #
            # @return [Hash] Gem's effective configuration
            def gem_config
              self.class.gem_class.config
            end

            # Get the gem's default configuration from the gem class.
            #
            # @return [Hash] Gem's default configuration
            def gem_defaults
              self.class.gem_class.default_config
            end
          end
        end
      end
    end
  end
end
