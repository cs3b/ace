# frozen_string_literal: true

module Ace
  module TestRunner
    module Models
      # Represents a single test failure or error
      class TestFailure
        attr_accessor :type, :test_name, :test_class, :message, :file_path,
          :line_number, :backtrace, :fix_suggestion, :code_context,
          :stderr_warnings

        def initialize(attributes = {})
          @type = attributes[:type] || :failure  # :failure or :error
          @test_name = attributes[:test_name]
          @test_class = attributes[:test_class]
          @message = attributes[:message]
          @file_path = attributes[:file_path]
          @line_number = attributes[:line_number]
          @backtrace = attributes[:backtrace] || []
          @fix_suggestion = attributes[:fix_suggestion]
          @code_context = attributes[:code_context]
          @stderr_warnings = attributes[:stderr_warnings]
        end

        def location
          return nil unless file_path

          if line_number
            "#{file_path}:#{line_number}"
          else
            file_path
          end
        end

        def short_location
          return nil unless file_path

          base_name = File.basename(file_path)
          line_number ? "#{base_name}:#{line_number}" : base_name
        end

        def full_test_name
          test_class ? "#{test_class}##{test_name}" : test_name.to_s
        end

        def error?
          type == :error
        end

        def failure?
          type == :failure
        end

        def summary_line
          "#{type_icon} #{full_test_name} - #{short_location}"
        end

        def detailed_description
          lines = []
          lines << "#{type_icon} #{type.to_s.capitalize}: #{full_test_name}"
          lines << "  Location: #{location}" if location
          lines << "  Message: #{message}" if message
          lines << "  Fix: #{fix_suggestion}" if fix_suggestion
          lines.join("\n")
        end

        def to_h
          {
            type: type,
            test_name: test_name,
            test_class: test_class,
            message: message,
            location: location,
            file_path: file_path,
            line_number: line_number,
            backtrace: backtrace,
            fix_suggestion: fix_suggestion,
            code_context: code_context,
            stderr_warnings: stderr_warnings
          }
        end

        def to_json(*args)
          to_h.to_json(*args)
        end

        private

        def type_icon
          error? ? "💥" : "❌"
        end
      end
    end
  end
end
