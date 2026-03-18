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
          # Pattern for inline verbose failures - match test name, FAIL marker, and content until next test or EOF
          # Matches: "  test_name                 FAIL (0.02s)\n    error details\n    /path/file.rb:123..."
          inline_failure: /^\s+(test_[\w_]+).*?FAIL.*?\([\d.]+s\)\n(.*?)(?=^\s+test_[\w_]+.*?(?:PASS|FAIL|ERROR|SKIP)|^Finished in|\z)/m,
          # Pattern for inline errors - same structure as failures but with ERROR marker
          inline_error: /^\s+(test_[\w_]+).*?ERROR.*?\([\d.]+s\)\n(.*?)(?=^\s+test_[\w_]+.*?(?:PASS|FAIL|ERROR|SKIP)|^Finished in|\z)/m,
          location: /\[(.*?):(\d+)\]/,
          duration: /Finished in ([\d.]+)s/,
          deprecation: /DEPRECATION WARNING: (.+)/,
          # Pattern to capture individual test times from verbose output
          # Matches Minitest::Reporters DefaultReporter format:
          #   "  test_name                     PASS (0.00s)"
          test_time: /^\s+(test_[\w_]+).*?\s+(PASS|FAIL|ERROR|SKIP)\s+\(([\d.]+)s\)/,
          # Pattern for standard Minitest verbose format:
          # 1. "ClassName#test_name = 0.00 s = ."
          # 2. "ClassName#test_name 0.00 = ."
          test_time_standard: /^(\S+)#(test_[\w_]+)\s+(?:=\s+)?([\d.]+)\s*s?\s*=\s*([.FEWS])/
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
          # But ONLY if the output contains FAIL or ERROR to avoid expensive processing on success
          if failures.empty? && (clean_output.include?(' FAIL ') || clean_output.include?(' ERROR '))
            # Split by test headers and process each block
            test_blocks = clean_output.split(/(?=^\s+test_[\w_]+)/).select { |s| s.match?(/^\s+test_/) }

            test_blocks.each do |block|
              # Check if this block contains a FAIL or ERROR
              if block =~ /^\s+(test_[\w_]+).*?(ERROR|FAIL).*?\(([\d.]+)s\)\n(.*)/m
                test_name = $1
                type = $2 == 'ERROR' ? :error : :failure
                content = $4

                failure = parse_inline_failure(test_name, content, type)
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

          # Try Minitest::Reporters DefaultReporter format first (most common)
          # Format: "  test_name                     PASS (0.00s)"
          clean_output.scan(PATTERNS[:test_time]) do |test_name, status, time|
            test_times << {
              name: test_name,
              status: status,
              duration: time.to_f,
              location: location_index[test_name]
            }
          end

          # If no matches, try standard Minitest verbose format
          # Format: "ClassName#test_name = 0.00 s = ." or "ClassName#test_name 0.00 = ."
          if test_times.empty?
            clean_output.scan(PATTERNS[:test_time_standard]) do |class_name, test_name, time, status_char|
              status = case status_char
                       when "." then "PASS"
                       when "F" then "FAIL"
                       when "E" then "ERROR"
                       when "S" then "SKIP"
                       else "UNKNOWN"
                       end
              test_times << {
                name: test_name,
                class_name: class_name,
                status: status,
                duration: time.to_f,
                location: location_index[test_name]
              }
            end
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
          #         /Users/mc/Ps/ace/ace-core/test/atoms/env_parser_test.rb:50:in 'EnvParserTest#test_handles_special_characters'

          lines = content.strip.lines

          # Extract location from any line that looks like a file path (first occurrence)
          location = nil
          location_line_idx = nil
          lines.each_with_index do |line, idx|
            # Match absolute paths with .rb extension
            if line =~ %r{^\s*(/[^:]+\.rb):(\d+)}
              location = {
                file: $1.strip,
                line: $2.to_i
              }
              location_line_idx = idx
              break
            end
          end

          # Extract message (all lines before location, trimmed)
          # Skip empty lines and indentation
          message_lines = []
          lines[0...location_line_idx].each do |line|
            stripped = line.strip
            next if stripped.empty?
            message_lines << stripped
          end

          # If no message extracted, use first non-empty line
          if message_lines.empty? && lines.any?
            message_lines << lines.first.strip
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