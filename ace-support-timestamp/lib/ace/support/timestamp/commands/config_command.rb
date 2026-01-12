# frozen_string_literal: true

module Ace
  module Support
    module Timestamp
    module Commands
      # Command to display current configuration
      #
      # @example Usage
      #   ConfigCommand.execute
      #   # Output:
      #   # year_zero: 2000
      #   # alphabet: 0123456789abcdefghijklmnopqrstuvwxyz
      #
      class ConfigCommand
        class << self
          # Execute the config command
          #
          # @param options [Hash] Command options
          # @option options [Boolean] :verbose Show additional config details
          # @return [Integer] Exit code (0 for success)
          def execute(options = {})
            config = Molecules::ConfigResolver.resolve

            puts "Current ace-timestamp configuration:"
            puts ""
            puts "  year_zero: #{config[:year_zero]}"
            puts "  alphabet: #{config[:alphabet]}"

            if options[:verbose]
              puts ""
              puts "Configuration sources (in order of precedence):"
              puts "  1. Runtime options (passed to commands)"
              puts "  2. Project config: .ace/timestamp/config.yml"
              puts "  3. User config: ~/.ace/timestamp/config.yml"
              puts "  4. Gem defaults: .ace-defaults/timestamp/config.yml"
              puts ""
              puts "Year range: #{config[:year_zero]} to #{config[:year_zero] + 107}"
              puts "ID length: 6 characters (Base36)"
              puts "Time precision: ~1.85 seconds"
            end

            0
          rescue StandardError => e
            warn "Error displaying config: #{e.message}"
            warn e.backtrace.first(5).join("\n") if Ace::Support::Timestamp.debug?
            1
          end
        end
      end
    end
  end
  end
end
