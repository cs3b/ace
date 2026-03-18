# frozen_string_literal: true

require "json"
require "time"

module Ace
  module B36ts
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
          # @option options [String] :format Output format
          # @option options [Boolean] :quiet Suppress config summary output
          # @return [Integer] Exit code (0 for success, 1 for error)
          def execute(time_string, options = {})
            time = parse_time(time_string)
            config = Molecules::ConfigResolver.resolve(options)

            display_config_summary("encode", config, options)

            # Validate mutually exclusive options
            if options[:split]
              if options[:format]
                raise ArgumentError, "--split and --format are mutually exclusive"
              end
              if options[:count]
                raise ArgumentError, "--count and --split are mutually exclusive"
              end

              levels = parse_split_levels(options[:split])
              output = Atoms::CompactIdEncoder.encode_split(
                time,
                levels: levels,
                year_zero: config[:year_zero],
                alphabet: config[:alphabet]
              )

              if options[:path_only]
                puts output[:path]
              elsif options[:json]
                puts JSON.generate(output.transform_keys(&:to_s))
              else
                display_split_output(levels, output)
              end
            else
              # Get format from options or config (default: :"2sec")
              # Normalize hyphens to underscores for CLI compatibility (e.g., high-8 -> high_8)
              format = options[:format]
              format = format.to_s.tr("-", "_").to_sym if format
              format ||= config[:default_format]&.to_sym || :"2sec"

              if options[:count]
                count = options[:count].to_i
                ids = Atoms::CompactIdEncoder.encode_sequence(
                  time,
                  count: count,
                  format: format,
                  year_zero: config[:year_zero],
                  alphabet: config[:alphabet]
                )

                if options[:json]
                  puts JSON.generate(ids)
                else
                  ids.each { |id| puts id }
                end
              else
                compact_id = Atoms::CompactIdEncoder.encode_with_format(
                  time,
                  format: format,
                  year_zero: config[:year_zero],
                  alphabet: config[:alphabet]
                )

                puts compact_id
              end
            end
            0
          rescue ArgumentError => e
            warn "Error: #{e.message}"
            raise
          rescue StandardError => e
            warn "Error encoding timestamp: #{e.message}"
            warn e.backtrace.first(5).join("\n") if Ace::B36ts.debug?
            raise
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

            parsed = Time.parse(time_string)
            return parsed if has_explicit_timezone?(time_string)

            # Treat naïve timestamps as UTC to avoid local-time offsets on date-only
            # inputs and systems with non-UTC defaults.
            Time.utc(parsed.year, parsed.month, parsed.day, parsed.hour, parsed.min, parsed.sec, parsed.nsec)
          rescue ArgumentError
            raise ArgumentError, "Cannot parse time: #{time_string}"
          end

          def has_explicit_timezone?(time_string)
            value = time_string.to_s
            return true if value.match?(%r{[+-]\d{2}:?\d{2}\b})
            return true if value.match?(%r{(?:\A|[[:space:]])(?:Z|UTC|GMT)\b}i)

            false
          end

          # Display configuration summary (unless quiet mode)
          #
          # @param command [String] Command name
          # @param config [Hash] Resolved configuration
          # @param options [Hash] Command options
          def display_config_summary(command, config, options)
            return if options[:quiet] || options[:path_only] || options[:json]

            require "ace/core"
            Ace::Core::Atoms::ConfigSummary.display(
              command: command,
              config: config,
              defaults: Molecules::ConfigResolver::FALLBACK_DEFAULTS,
              options: options,
              quiet: false
            )
          end

          # Normalize split levels from string or array
          #
          # @param levels [String, Array<Symbol>] Split level list
          # @return [Array<Symbol>] Normalized levels
          def parse_split_levels(levels)
            list = levels.is_a?(String) ? levels.split(",") : Array(levels)
            list.map { |level| level.to_s.strip }
                .reject(&:empty?)
                .map(&:to_sym)
          end

          # Display split output in key/value format
          #
          # @param levels [Array<Symbol>] Split levels in order
          # @param output [Hash] Split output hash
          def display_split_output(levels, output)
            lines = []
            levels.each do |level|
              lines << "#{level}: #{output[level]}"
            end
            lines << "rest: #{output[:rest]}"
            lines << "path: #{output[:path]}"
            lines << "full: #{output[:full]}"
            puts lines.join("\n")
          end

        end
      end
  end
  end
end
