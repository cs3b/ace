# frozen_string_literal: true

module Ace
  module B36ts
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
          # @param compact_id [String] 2-8 character compact ID to decode
          # @param options [Hash] Command options
          # @option options [Integer] :year_zero Override year_zero config
          # @option options [String] :format Output format (:iso, :timestamp, :readable)
          # @option options [Boolean] :quiet Suppress config summary output
          # @return [Integer] Exit code (0 for success, 1 for error)
          def execute(compact_id, options = {})
            config = Molecules::ConfigResolver.resolve(options)

            display_config_summary("decode", config, options)

            # Use split decoding for hierarchical paths, otherwise auto-detect
            time = if options[:split] || contains_split_separator?(compact_id)
              Atoms::CompactIdEncoder.decode_path(
                compact_id,
                year_zero: config[:year_zero],
                alphabet: config[:alphabet]
              )
            else
              Atoms::CompactIdEncoder.decode_auto(
                compact_id,
                year_zero: config[:year_zero],
                alphabet: config[:alphabet]
              )
            end

            output = format_output(time, options[:format])
            puts output
            0
          rescue ArgumentError => e
            warn "Error: #{e.message}"
            raise
          rescue => e
            warn "Error decoding compact ID: #{e.message}"
            warn e.backtrace.first(5).join("\n") if Ace::B36ts.debug?
            raise
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

          # Detect split separators in input
          #
          # @param value [String] Input to check
          # @return [Boolean] True if split separators are present
          def contains_split_separator?(value)
            value.is_a?(String) && value.match?(/[\/\\:]/)
          end
        end
      end
    end
  end
end
