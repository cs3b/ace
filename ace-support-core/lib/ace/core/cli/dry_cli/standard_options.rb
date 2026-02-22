# frozen_string_literal: true

module Ace
  module Core
    module CLI
      module DryCli
        # Canonical description strings for standard options shared across all ACE CLIs.
        #
        # Use these constants when defining standard options in dry-cli commands
        # to ensure consistent help text across the entire toolchain.
        #
        # @example Usage in a command
        #   class MyCommand < Dry::CLI::Command
        #     include Ace::Core::CLI::DryCli::Base
        #
        #     option :quiet, type: :boolean, aliases: %w[-q],
        #       desc: Ace::Core::CLI::DryCli::StandardOptions::QUIET_DESC
        #     option :verbose, type: :boolean, aliases: %w[-v],
        #       desc: Ace::Core::CLI::DryCli::StandardOptions::VERBOSE_DESC
        #     option :debug, type: :boolean, aliases: %w[-d],
        #       desc: Ace::Core::CLI::DryCli::StandardOptions::DEBUG_DESC
        #   end
        #
        # @since 0.12.0
        module StandardOptions
          QUIET_DESC   = "Suppress non-essential output"
          VERBOSE_DESC = "Show verbose output"
          DEBUG_DESC   = "Show debug output"
          HELP_DESC    = "Show this help"
        end
      end
    end
  end
end
