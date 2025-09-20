# frozen_string_literal: true

module AceTools
  module TestReporter
    module Formatters
      class CompactFormatter
        def initialize(options = {})
          @color_output = options[:color_output]
        end

        def format_group(name, results, elapsed_time)
          passed = results[:passed].size
          failed = results[:failed].size
          errors = results[:errors].size
          skipped = results[:skipped].size

          status_parts = []
          status_parts << color_text("✓ #{passed}", :green) if passed > 0
          status_parts << color_text("✗ #{failed}", :red) if failed > 0
          status_parts << color_text("E #{errors}", :red) if errors > 0
          status_parts << color_text("⊘ #{skipped}", :yellow) if skipped > 0

          time_str = format('(%.2fs)', elapsed_time)

          format('%-12s: %s  %s', name, status_parts.join('  '), time_str)
        end

        def format_failure(result)
          file, line = extract_location(result)
          error_msg = extract_error_message(result)

          # Simple format: just file:line and message
          format('%s:%s - %s', file, line, error_msg)
        end

        def format_full_summary(results_by_group, total_time)
          lines = []
          lines << "═" * 67

          # Group statistics
          results_by_group.each do |group, results|
            time = results.values.flatten.sum(&:time)
            lines << format_group(group, results, time)
          end

          # Totals
          lines << "─" * 67
          total_passed = results_by_group.sum { |_, r| r[:passed].size }
          total_failed = results_by_group.sum { |_, r| r[:failed].size }
          total_errors = results_by_group.sum { |_, r| r[:errors].size }
          total_skipped = results_by_group.sum { |_, r| r[:skipped].size }

          lines << format('TOTAL: ✓ %d  ✗ %d  E %d  ⊘ %d  (%.2fs)',
                         total_passed, total_failed, total_errors, total_skipped, total_time)
          lines << "═" * 67

          lines.join("\n")
        end

        private

        def extract_location(result)
          if result.source_location
            file = result.source_location[0].sub(%r{^.*/test/}, 'test/')
            line = result.source_location[1]
          else
            file = 'unknown'
            line = '0'
          end
          [file, line]
        end

        def extract_error_message(result)
          if result.failure
            # Extract the core message, removing assertion details
            msg = result.failure.message.to_s
            msg = msg.split("\n").first if msg.include?("\n")
            msg = msg.sub(/^[A-Z]\w+::\w+:\s*/, '') # Remove error class prefix
            # Truncate long error messages
            msg = msg[0, 100] + '...' if msg.length > 100
            msg
          else
            'Unknown error'
          end
        end

        def color_text(text, color)
          return text unless @color_output

          color_codes = {
            green: "\e[32m",
            red: "\e[31m",
            yellow: "\e[33m",
            reset: "\e[0m"
          }

          "#{color_codes[color]}#{text}#{color_codes[:reset]}"
        end
      end
    end
  end
end