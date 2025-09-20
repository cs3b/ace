# frozen_string_literal: true

module Ace
  module TestRunner
    module Molecules
      # Identifies and suggests fixes for deprecated code patterns
      class DeprecationFixer
        DEPRECATION_PATTERNS = [
          {
            pattern: /must_equal/,
            replacement: "must_be :==",
            description: "Replace must_equal with must_be :=="
          },
          {
            pattern: /wont_equal/,
            replacement: "wont_be :==",
            description: "Replace wont_equal with wont_be :=="
          },
          {
            pattern: /must_be_nil/,
            replacement: "must_be_nil",
            description: "Use must_be_nil (no change needed)"
          },
          {
            pattern: /\.must_be\s+:([<>]=?)/,
            replacement: 'must_be :\1',
            description: "Comparison operators should use symbols"
          },
          {
            pattern: /assert_equal\s+nil,/,
            replacement: "assert_nil",
            description: "Use assert_nil instead of assert_equal nil"
          },
          {
            pattern: /refute_equal\s+nil,/,
            replacement: "refute_nil",
            description: "Use refute_nil instead of refute_equal nil"
          }
        ].freeze

        def find_deprecations(content)
          deprecations = []

          content.lines.each_with_index do |line, index|
            DEPRECATION_PATTERNS.each do |pattern_info|
              if line.match?(pattern_info[:pattern])
                deprecations << {
                  line_number: index + 1,
                  line_content: line.strip,
                  pattern: pattern_info[:pattern].source,
                  suggestion: pattern_info[:description],
                  replacement: pattern_info[:replacement]
                }
              end
            end
          end

          deprecations
        end

        def fix_file(file_path, dry_run: false)
          unless File.exist?(file_path)
            return { success: false, error: "File not found: #{file_path}" }
          end

          original_content = File.read(file_path)
          fixed_content = apply_fixes(original_content)

          if original_content == fixed_content
            return {
              success: true,
              changes: 0,
              message: "No deprecations found"
            }
          end

          unless dry_run
            File.write(file_path, fixed_content)
          end

          {
            success: true,
            changes: count_changes(original_content, fixed_content),
            message: dry_run ? "Would fix deprecations (dry run)" : "Fixed deprecations",
            diff: generate_diff(original_content, fixed_content)
          }
        end

        def fix_deprecations_in_output(test_output)
          fixes = []

          # Look for deprecation warnings in test output
          test_output.scan(/DEPRECATION WARNING: (.+)/) do |warning|
            fix = analyze_warning(warning.first)
            fixes << fix if fix
          end

          fixes.uniq
        end

        def generate_fix_report(deprecations)
          return "No deprecations found." if deprecations.empty?

          lines = ["# Deprecation Fixes Required", ""]

          grouped = deprecations.group_by { |d| d[:file] || "Unknown" }

          grouped.each do |file, file_deprecations|
            lines << "## File: #{file}"
            lines << ""

            file_deprecations.each do |dep|
              lines << "- Line #{dep[:line_number]}: #{dep[:suggestion]}"
              if dep[:replacement]
                lines << "  Replace: `#{dep[:line_content]}`"
                lines << "  With: `#{apply_single_fix(dep[:line_content], dep)}`"
              end
            end

            lines << ""
          end

          lines.join("\n")
        end

        private

        def apply_fixes(content)
          fixed_content = content.dup

          DEPRECATION_PATTERNS.each do |pattern_info|
            fixed_content.gsub!(pattern_info[:pattern], pattern_info[:replacement])
          end

          fixed_content
        end

        def apply_single_fix(line, deprecation_info)
          return line unless deprecation_info[:replacement]

          pattern = Regexp.new(deprecation_info[:pattern])
          line.gsub(pattern, deprecation_info[:replacement])
        end

        def count_changes(original, fixed)
          original_lines = original.lines
          fixed_lines = fixed.lines

          changes = 0
          [original_lines.length, fixed_lines.length].max.times do |i|
            if original_lines[i] != fixed_lines[i]
              changes += 1
            end
          end

          changes
        end

        def generate_diff(original, fixed)
          # Simple diff generation
          diff_lines = []
          original_lines = original.lines
          fixed_lines = fixed.lines

          [original_lines.length, fixed_lines.length].max.times do |i|
            if original_lines[i] != fixed_lines[i]
              diff_lines << "- #{original_lines[i]}" if original_lines[i]
              diff_lines << "+ #{fixed_lines[i]}" if fixed_lines[i]
            end
          end

          diff_lines.join
        end

        def analyze_warning(warning_text)
          # Extract file and line information from warning if available
          if warning_text =~ /(.+):(\d+):\s*(.+)/
            {
              file: $1,
              line: $2.to_i,
              message: $3,
              suggestion: find_fix_for_warning($3)
            }
          else
            {
              message: warning_text,
              suggestion: find_fix_for_warning(warning_text)
            }
          end
        end

        def find_fix_for_warning(warning_text)
          DEPRECATION_PATTERNS.each do |pattern_info|
            if warning_text.match?(pattern_info[:pattern])
              return pattern_info[:description]
            end
          end

          "Review deprecation warning and update code accordingly"
        end
      end
    end
  end
end