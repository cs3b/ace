# frozen_string_literal: true

require "time"

module Ace
  module Timestamp
    module Commands
      # Command to encode a timestamp to a compact ID
      #
      # @example Usage
      #   EncodeCommand.execute("2025-01-06 12:30:00")
      #   # => "i50jj3"
      #
      class EncodeCommand
        class << self
          # Execute the encode command
          #
          # @param time_string [String] Time string to encode (various formats supported)
          # @param options [Hash] Command options
          # @option options [Integer] :year_zero Override year_zero config
          # @option options [Boolean] :quiet Suppress config summary output
          # @return [Integer] Exit code (0 for success, 1 for error)
          def execute(time_string, options = {})
            time = parse_time(time_string)
            config = Molecules::ConfigResolver.resolve(options)

            display_config_summary("encode", config, options)

            compact_id = Atoms::CompactIdEncoder.encode(
              time,
              year_zero: config[:year_zero],
              alphabet: config[:alphabet]
            )

            puts compact_id
            0
          rescue ArgumentError => e
            warn "Error: #{e.message}"
            1
          rescue StandardError => e
            warn "Error encoding timestamp: #{e.message}"
            warn e.backtrace.first(5).join("\n") if Ace::Timestamp.debug?
            1
          end

          private

          # Parse various time string formats
          #
          # @param time_string [String] Time string to parse
          # @return [Time] Parsed time
          # @raise [ArgumentError] If format is unrecognized
          def parse_time(time_string)
            return Time.now.utc if time_string.nil? || time_string.empty? || time_string == "now"

            # Check for legacy timestamp format FIRST (YYYYMMDD-HHMMSS)
            # Time.parse incorrectly parses this format (treats -HHMMSS as timezone offset)
            if Atoms::Formats.timestamp?(time_string)
              return Atoms::Formats.parse_timestamp(time_string)
            end

            # Try standard parsing for other formats
            Time.parse(time_string).utc
          rescue ArgumentError
            raise ArgumentError, "Cannot parse time: #{time_string}"
          end

          # Display configuration summary (unless quiet mode)
          #
          # @param command [String] Command name
          # @param config [Hash] Resolved configuration
          # @param options [Hash] Command options
          def display_config_summary(command, config, options)
            return if options[:quiet]

            require "ace/core"
            Ace::Core::Atoms::ConfigSummary.display(
              command: command,
              config: config,
              defaults: Molecules::ConfigResolver::FALLBACK_DEFAULTS,
              options: options,
              quiet: false
            )
          end
        end
      end
    end
  end
end
