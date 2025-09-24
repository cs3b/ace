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
          deprecation: /DEPRECATION WARNING: (.+)/,
          # Pattern to capture individual test times from verbose output
          test_time: /^\s+(test_[\w_]+).*?\s+(PASS|FAIL|ERROR|SKIP)\s+\(([\d.]+)s\)/
        }.freeze

        def parse_output(output)
          # Clean ANSI color codes once for all parsing methods
          clean_output = output.gsub(/\e\[[0-9;]*m/, '')

          summary = parse_summary(clean_output)
          failures = parse_failures(clean_output)
          duration = parse_duration(clean_output)
          deprecations = parse_deprecations(clean_output)
          test_times = parse_test_times(clean_output)

          {
            raw_output: output,
            summary: summary,
            failures: failures,
            duration: duration,
            deprecations: deprecations,
            test_times: test_times
          }
        end

        def parse_summary(clean_output)
          # clean_output already has ANSI codes removed
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

        def parse_failures(clean_output)
          # clean_output already has ANSI codes removed
          failures = []

          # First try to parse standard format failures
          clean_output.scan(PATTERNS[:failure]) do |type, content|
            failure = parse_single_failure(type, content)
            failures << failure if failure
          end

          # If no failures found, try inline verbose format
          # But ONLY if the output contains FAIL or ERROR to avoid expensive regex on success
          if failures.empty? && (clean_output.include?(' FAIL ') || clean_output.include?(' ERROR '))
            # Parse FAIL lines
            if clean_output.include?(' FAIL ')
              clean_output.scan(PATTERNS[:inline_failure]) do |test_name, failure_content|
                failure = parse_inline_failure(test_name, failure_content, :failure)
                failures << failure if failure
              end
            end

            # Parse ERROR lines
            if clean_output.include?(' ERROR ')
              clean_output.scan(PATTERNS[:inline_error]) do |test_name, error_content|
                failure = parse_inline_failure(test_name, error_content, :error)
                failures << failure if failure
              end
            end
          end

          failures
        end

        def parse_duration(clean_output)
          # clean_output already has ANSI codes removed
          match = clean_output.match(PATTERNS[:duration])
          match ? match[1].to_f : 0.0
        end

        def parse_deprecations(clean_output)
          deprecations = []

          clean_output.scan(PATTERNS[:deprecation]) do |message|
            deprecations << message.first
          end

          deprecations.uniq
        end

        def parse_test_times(clean_output)
          # clean_output already has ANSI codes removed
          test_times = []

          # Build location index first to avoid O(n²) complexity
          location_index = {}
          clean_output.scan(/(test_[\w_]+).*?\[(.*?):(\d+)\]/) do |name, file, line|
            location_index[name] ||= "#{file}:#{line}"
          end

          clean_output.scan(PATTERNS[:test_time]) do |test_name, status, time|
            test_times << {
              name: test_name,
              status: status,
              duration: time.to_f,
              location: location_index[test_name]
            }
          end

          test_times.sort_by { |t| -t[:duration] }
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