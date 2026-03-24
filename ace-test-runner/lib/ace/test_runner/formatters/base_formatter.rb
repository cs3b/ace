# frozen_string_literal: true

module Ace
  module TestRunner
    module Formatters
      # Base class for all formatters
      class BaseFormatter
        attr_reader :options
        attr_accessor :report_path

        def initialize(options = {})
          @options = options
          @use_color = options.fetch(:color, true) && $stdout.tty?
          @report_path = nil
        end

        # Format the test result for stdout output
        def format_stdout(result)
          raise NotImplementedError, "Subclasses must implement format_stdout"
        end

        # Format the complete report for saving
        def format_report(report)
          raise NotImplementedError, "Subclasses must implement format_report"
        end

        # Called when test execution starts
        def on_start(total_files)
          # Override in subclasses if needed
        end

        # Called when a single test file completes
        def on_test_complete(file, success, duration)
          # Override in subclasses if needed
        end

        # Called when all tests complete
        def on_finish(result)
          # Override in subclasses if needed
        end

        protected

        def colorize(text, color)
          return text unless @use_color

          color_codes = {
            red: "\e[31m",
            green: "\e[32m",
            yellow: "\e[33m",
            blue: "\e[34m",
            magenta: "\e[35m",
            cyan: "\e[36m",
            white: "\e[37m",
            bold: "\e[1m",
            reset: "\e[0m"
          }

          code = color_codes[color] || color_codes[:reset]
          "#{code}#{text}#{color_codes[:reset]}"
        end

        def pluralize(count, singular, plural = nil)
          plural ||= "#{singular}s"
          (count == 1) ? "#{count} #{singular}" : "#{count} #{plural}"
        end

        def format_duration(seconds)
          if seconds < 1
            "#{(seconds * 1000).round(2)}ms"
          elsif seconds < 60
            "#{seconds.round(2)}s"
          else
            minutes = (seconds / 60).floor
            remaining = (seconds % 60).round
            "#{minutes}m #{remaining}s"
          end
        end

        def success_icon
          "✅"
        end

        def failure_icon
          "❌"
        end

        def error_icon
          "💥"
        end

        def skip_icon
          "⚠️"
        end

        def format_percentage(value)
          "#{value.round(1)}%"
        end
      end
    end
  end
end
