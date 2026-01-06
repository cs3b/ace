# frozen_string_literal: true

module Ace
  module Timestamp
    module Commands
      # Command to decode a compact ID to a timestamp
      #
      # @example Usage
      #   DecodeCommand.execute("i50jj3")
      #   # => "2025-01-06 12:30:00 UTC"
      #
      class DecodeCommand
        class << self
          # Execute the decode command
          #
          # @param compact_id [String] 6-character compact ID to decode
          # @param options [Hash] Command options
          # @option options [Integer] :year_zero Override year_zero config
          # @option options [String] :format Output format (:iso, :timestamp, :readable)
          # @option options [Boolean] :quiet Suppress config summary output
          # @return [Integer] Exit code (0 for success, 1 for error)
          def execute(compact_id, options = {})
            config = Molecules::ConfigResolver.resolve(options)

            display_config_summary("decode", config, options)

            time = Atoms::CompactIdEncoder.decode(
              compact_id,
              year_zero: config[:year_zero],
              alphabet: config[:alphabet]
            )

            output = format_output(time, options[:format])
            puts output
            0
          rescue ArgumentError => e
            warn "Error: #{e.message}"
            1
          rescue StandardError => e
            warn "Error decoding compact ID: #{e.message}"
            warn e.backtrace.first(5).join("\n") if Ace::Timestamp.debug?
            1
          end

          private

          # Format the time output based on requested format
          #
          # @param time [Time] Decoded time
          # @param format [Symbol, String, nil] Output format
          # @return [String] Formatted time string
          def format_output(time, format)
            case format&.to_sym
            when :iso
              time.iso8601
            when :timestamp
              Atoms::Formats.format_timestamp(time)
            when :readable
              time.strftime("%Y-%m-%d %H:%M:%S UTC")
            else
              # Default: readable format
              time.strftime("%Y-%m-%d %H:%M:%S UTC")
            end
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
