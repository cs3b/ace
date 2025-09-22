# frozen_string_literal: true

module Ace
  module TestRunner
    module Atoms
      # Parses test output into structured data
      class ResultParser
        # Patterns for parsing minitest output
        PATTERNS = {
          summary: /(\d+) (?:tests?|runs?), (\d+) assertions?, (\d+) failures?, (\d+) errors?, (\d+) skips?/,
          failure: /^\s+\d+\) (Failure|Error):\n(.+?)(?=^\s+\d+\) |^Finished in|\z)/m,
          # Pattern for inline verbose failures - match each failure individually
          inline_failure: /^\s*(test_[\w_]+).*?\s+FAIL\s+.*?\n((?:.*?\n)*?)(?=^\s*test_|^[A-Z]|\z)/m,
          # Pattern for inline errors
          inline_error: /^\s*(test_[\w_]+).*?\s+ERROR\s+.*?\n((?:.*?\n)*?)(?=^\s*test_|^[A-Z]|\z)/m,
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
          # Remove ANSI color codes before parsing
          clean_output = output.gsub(/\e\[[0-9;]*m/, '')
          match = clean_output.match(PATTERNS[:summary])


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
          clean_output = output.gsub(/\e\[[0-9;]*m/, '')

          # First try to parse standard format failures
          clean_output.scan(PATTERNS[:failure]) do |type, content|
            failure = parse_single_failure(type, content)
            failures << failure if failure
          end

          # If no failures found, try inline verbose format
          if failures.empty?
            # Parse FAIL lines
            clean_output.scan(PATTERNS[:inline_failure]) do |test_name, failure_content|
              failure = parse_inline_failure(test_name, failure_content, :failure)
              failures << failure if failure
            end

            # Parse ERROR lines
            clean_output.scan(PATTERNS[:inline_error]) do |test_name, error_content|
              failure = parse_inline_failure(test_name, error_content, :error)
              failures << failure if failure
            end
          end

          failures
        end

        def parse_duration(output)
          clean_output = output.gsub(/\e\[[0-9;]*m/, '')
          match = clean_output.match(PATTERNS[:duration])
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

        def parse_inline_failure(test_name, content, type = :failure)
          # Parse inline verbose format failures
          # Example:
          # test_handles_special_characters                                FAIL (0.00s)
          #         Expected: "path\\to\\file"
          #           Actual: nil
          #         /Users/mc/Ps/ace-meta/ace-core/test/atoms/env_parser_test.rb:50:in 'EnvParserTest#test_handles_special_characters'

          lines = content.strip.lines

          # Extract location from the last line that looks like a file path
          location = nil
          lines.reverse.each do |line|
            if line =~ /^\s*(.+\.rb):(\d+)/
              location = {
                file: $1.strip,
                line: $2.to_i
              }
              break
            end
          end

          # Extract message (Expected/Actual lines)
          message_lines = []
          lines.each do |line|
            next if line =~ /^\s*$/ || line =~ /\.rb:\d+/
            message_lines << line.strip
          end

          {
            type: type,
            test_name: test_name,
            message: message_lines.join("\n"),
            location: location,
            full_content: "#{test_name}\n#{content}".strip
          }
        end
      end
    end
  end
end