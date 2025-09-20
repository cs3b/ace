# frozen_string_literal: true

module Ace
  module TestRunner
    module Atoms
      # Parses test output into structured data
      class ResultParser
        # Patterns for parsing minitest output
        PATTERNS = {
          summary: /(\d+) runs?, (\d+) assertions?, (\d+) failures?, (\d+) errors?, (\d+) skips?/,
          failure: /^\s+\d+\) (Failure|Error):\n(.+?)(?=^\s+\d+\) |^Finished in|\z)/m,
          location: /\[(.*?):(\d+)\]/,
          duration: /Finished in ([\d.]+)s/,
          deprecation: /DEPRECATION WARNING: (.+)/
        }.freeze

        def parse_output(output)
          {
            raw_output: output,
            summary: parse_summary(output),
            failures: parse_failures(output),
            duration: parse_duration(output),
            deprecations: parse_deprecations(output)
          }
        end

        def parse_summary(output)
          match = output.match(PATTERNS[:summary])
          return default_summary unless match

          {
            runs: match[1].to_i,
            assertions: match[2].to_i,
            failures: match[3].to_i,
            errors: match[4].to_i,
            skips: match[5].to_i,
            passed: match[1].to_i - match[3].to_i - match[4].to_i - match[5].to_i
          }
        end

        def parse_failures(output)
          failures = []

          output.scan(PATTERNS[:failure]) do |type, content|
            failure = parse_single_failure(type, content)
            failures << failure if failure
          end

          failures
        end

        def parse_duration(output)
          match = output.match(PATTERNS[:duration])
          match ? match[1].to_f : 0.0
        end

        def parse_deprecations(output)
          deprecations = []

          output.scan(PATTERNS[:deprecation]) do |message|
            deprecations << message.first
          end

          deprecations.uniq
        end

        private

        def default_summary
          {
            runs: 0,
            assertions: 0,
            failures: 0,
            errors: 0,
            skips: 0,
            passed: 0
          }
        end

        def parse_single_failure(type, content)
          lines = content.strip.lines
          return nil if lines.empty?

          # First line is test name
          test_name = lines.first.strip

          # Find location
          location_match = content.match(PATTERNS[:location])
          location = if location_match
            {
              file: location_match[1],
              line: location_match[2].to_i
            }
          end

          # Extract message (everything after test name and before location/backtrace)
          message_lines = []
          lines[1..-1].each do |line|
            break if line.match?(PATTERNS[:location]) || line.strip.start_with?("/")
            message_lines << line
          end

          {
            type: type.downcase.to_sym,
            test_name: test_name,
            message: message_lines.join.strip,
            location: location,
            full_content: content.strip
          }
        end
      end
    end
  end
end