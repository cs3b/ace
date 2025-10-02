# frozen_string_literal: true

module Ace
  module TestRunner
    module Atoms
      # Resolves line numbers to test method names
      module LineNumberResolver
        module_function

        # Given a file and line number, find the test method name
        # Returns the test name or nil if not found
        def resolve_test_at_line(file_path, line_number)
          return nil unless File.exist?(file_path)

          content = File.read(file_path)
          lines = content.split("\n")

          # Find all test methods and their line ranges
          test_methods = extract_test_methods(lines)

          # Find the test that contains the specified line
          test_methods.find do |test|
            line_number >= test[:start_line] && line_number <= test[:end_line]
          end&.fetch(:name)
        end

        # Extract test method names and their line ranges from file content
        def extract_test_methods(lines)
          test_methods = []
          current_test = nil
          indent_stack = []

          lines.each_with_index do |line, index|
            line_number = index + 1

            # Match test method definitions: def test_something or test "something"
            if line =~ /^\s*(def\s+(test_\w+)|test\s+["'](.+)["']\s+do)/
              test_name = $2 || $3 # Either def test_name or test "name"

              # Convert test "name" to test_name format for minitest --name option
              test_name = test_name.gsub(/\s+/, '_') if test_name && test_name.include?(' ')

              # Close previous test if any
              if current_test
                current_test[:end_line] = line_number - 1
                test_methods << current_test
              end

              current_test = {
                name: test_name,
                start_line: line_number,
                end_line: lines.size  # Default to end of file
              }
            elsif line =~ /^\s*end\s*(#.*)?$/ && current_test
              # Found an end keyword - could be end of test method
              # Simple heuristic: if we're at the same or less indentation level, close the test
              current_indent = line[/^\s*/].length

              if current_indent <= 2 # Assuming test methods are indented at most 2 spaces
                current_test[:end_line] = line_number
                test_methods << current_test
                current_test = nil
              end
            end
          end

          # Close last test if still open
          if current_test
            current_test[:end_line] = lines.size
            test_methods << current_test
          end

          test_methods
        end

        # Given "file.rb:123", split into file and line number
        def parse_file_with_line(file_with_line)
          if file_with_line =~ /^(.+):(\d+)$/
            {file: $1, line: $2.to_i}
          else
            {file: file_with_line, line: nil}
          end
        end
      end
    end
  end
end
