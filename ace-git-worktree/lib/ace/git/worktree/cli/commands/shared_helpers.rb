# frozen_string_literal: true

require "ace/core"

module Ace
  module Git
    module Worktree
      module CLI
        module Commands
          # Shared helper methods for CLI commands
          #
          # Include this module in CLI command classes to avoid code duplication
          # of common patterns like config summary display and options conversion.
          module SharedHelpers
            include Ace::Support::Cli::Base

            private

            # Display config summary unless quiet mode is enabled
            #
            # @param command [String] Command name for display
            # @param options [Hash] CLI options hash
            def display_config_summary(command, options)
              return if quiet?(options)

              Ace::Core::Atoms::ConfigSummary.display(
                command: command,
                config: Ace::Git::Worktree.config,
                defaults: {},
                options: options
              )
            end

            # Convert ace-support-cli options hash to args array format for legacy commands
            #
            # @param options [Hash] CLI options hash
            # @return [Array<String>] Arguments array
            #
            # @note Boolean false values are skipped (not converted to --no-flag).
            #   This means there's no distinction between "not specified" and "explicitly
            #   set to false". If a command needs to distinguish these cases, it should
            #   handle the option directly rather than using this converter.
            def options_to_args(options)
              args = []
              options.each do |key, value|
                next if value.nil? || %i[quiet verbose debug].include?(key)

                arg_key = key.to_s.tr("_", "-")
                if value == true
                  args << "--#{arg_key}"
                elsif value == false
                  # Skip boolean false options - no distinction between unset and false
                  next
                elsif value.is_a?(String)
                  args << "--#{arg_key}"
                  args << value
                end
              end
              args
            end
          end
        end
      end
    end
  end
end
