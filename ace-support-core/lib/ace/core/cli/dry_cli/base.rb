# frozen_string_literal: true

require "dry/cli"

module Ace
  module Core
    module CLI
      module DryCli
        # Base module providing common patterns for dry-cli based CLIs.
        #
        # This module contains shared utilities and helpers for building
        # CLI commands using the dry-cli framework. It provides:
        #
        # - Standard option definitions (quiet, verbose, debug)
        # - Exit code handling patterns
        # - Common command utilities
        #
        # @example Creating a command registry
        #   require "ace/core/cli/dry_cli/base"
        #
        #   module MyGem
        #     module CLI
        #       extend Dry::CLI::Registry
        #       include Ace::Core::CLI::DryCli::Base
        #
        #       class MyCommand < Dry::CLI::Command
        #         include Ace::Core::CLI::DryCli::Base
        #
        #         desc "My command description"
        #
        #         option :quiet, type: :boolean, default: false
        #         option :verbose, type: :boolean, default: false
        #         option :debug, type: :boolean, default: false
        #
        #         def call(**options)
        #           # implementation
        #           0 # Success exit code
        #         rescue StandardError => e
        #           warn "Error: #{e.message}"
        #           1 # Failure exit code
        #         end
        #       end
        #
        #       register "my-command", MyCommand
        #     end
        #   end
        #
        # @example Creating a version command
        #   require "ace/core/cli/dry_cli/version_command"
        #
        #   # In your registry:
        #   version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        #     gem_name: "my-gem",
        #     version: MyGem::VERSION
        #   )
        #   register "version", version_cmd
        #   register "--version", version_cmd
        #
        # @note IMPORTANT: -v is reserved for --verbose (per ADR-018)
        #       Version is ONLY available via --version flag
        #
        # @see https://dry-rb.org/gems/dry-cli/ dry-cli documentation
        module Base
          # Standard option names used across all ACE CLIs
          STANDARD_OPTIONS = %i[quiet verbose debug].freeze

          # Reserved short flags (per ADR-018 and docs/ace-gems.g.md)
          # -h : help (dry-cli default)
          # -v : verbose (NOT version)
          # -q : quiet
          # -d : debug
          # -o : output
          # -f : available for package-specific use
          RESERVED_FLAGS = %i[h v q d o].freeze

          # Check if verbose mode is enabled
          #
          # @param options [Hash] Command options hash
          # @return [Boolean] true if verbose is enabled
          #
          # @example
          #   def call(**options)
          #     debug_output("Processing...") if verbose?(options)
          #   end
          def verbose?(options)
            options[:verbose] == true
          end

          # Check if quiet mode is enabled
          #
          # @param options [Hash] Command options hash
          # @return [Boolean] true if quiet is enabled
          #
          # @example
          #   def call(**options)
          #     return 0 if quiet?(options) # Skip status output
          #     puts "Detailed status..."
          #   end
          def quiet?(options)
            options[:quiet] == true
          end

          # Check if debug mode is enabled
          #
          # @param options [Hash] Command options hash
          # @return [Boolean] true if debug is enabled
          #
          # @example
          #   def call(**options)
          #     warn "DEBUG: #{inspect(obj)}" if debug?(options)
          #   end
          def debug?(options)
            options[:debug] == true
          end

          # Check if help was requested
          #
          # @param options [Hash] Command options hash
          # @return [Boolean] true if help is requested
          #
          # @example
          #   def call(**options)
          #     return show_help if help?(options)
          #   end
          def help?(options)
            options[:help] == true || options[:h] == true
          end

          # Output debug message to stderr if debug mode is enabled
          #
          # @param message [String] Debug message
          # @param options [Hash] Command options hash
          # @return [nil]
          #
          # @example
          #   def call(**options)
          #     debug_log("Processing file: #{file}", options)
          #   end
          def debug_log(message, options)
            $stderr.puts "DEBUG: #{message}" if debug?(options)
          end

          # Return a success exit code
          #
          # @return [Integer] 0 for success
          #
          # @example
          #   def call(**options)
          #     # ... successful work ...
          #     exit_success
          #   end
          def exit_success
            0
          end

          # Return a failure exit code
          #
          # @param message [String, nil] Optional error message to output
          # @return [Integer] 1 for failure
          #
          # @example
          #   def call(**options)
          #     return exit_failure("Invalid input") unless valid?
          #   end
          def exit_failure(message = nil)
            warn "Error: #{message}" if message
            1
          end

          # Validate that required options are present
          #
          # @param options [Hash] Command options hash
          # @param required [Array<Symbol>] Required option keys
          # @raise [ArgumentError] if any required option is missing
          #
          # @example
          #   def call(**options)
          #     validate_required!(options, :file, :output)
          #     # ... proceed with implementation ...
          #   end
          def validate_required!(options, *required)
            missing = required - options.keys.select { |k| !options[k].nil? }
            return if missing.empty?

            raise ArgumentError, "Missing required options: #{missing.join(', ')}"
          end

          # Format a hash as space-separated key=value pairs
          #
          # @param hash [Hash] Hash to format
          # @return [String] Formatted string
          #
          # @example
          #   format_pairs(a: 1, b: 2) # => "a=1 b=2"
          def format_pairs(hash)
            hash.map { |k, v| "#{k}=#{v}" }.join(" ")
          end
        end
      end
    end
  end
end
