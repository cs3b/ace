# frozen_string_literal: true

require "fileutils"

module Ace
  module GitDiff
    module Commands
      # Command for generating diffs
      class DiffCommand
        def execute(range, options)
          # Build options hash
          diff_options = build_options(range, options)

          # Generate diff
          result = if options[:raw]
                     Organisms::DiffOrchestrator.raw(diff_options)
                   else
                     Organisms::DiffOrchestrator.generate(diff_options)
                   end

          # Output result
          output_result(result, options)

          # Return success
          0
        rescue Ace::GitDiff::Error => e
          warn "Error generating diff: #{e.message}"
          1
        end

        private

        def build_options(range, cli_options)
          options = {}

          # Add range if specified
          options[:ranges] = [range] if range

          # Add since if specified
          options[:since] = cli_options[:since] if cli_options[:since]

          # Add path filters
          options[:paths] = cli_options[:paths] if cli_options[:paths]

          # Add exclude patterns (overrides config if specified)
          options[:exclude_patterns] = cli_options[:exclude] if cli_options[:exclude]

          # Add format
          options[:format] = cli_options[:format]&.to_sym || :diff

          options
        end

        def output_result(result, options)
          content = format_content(result, options)

          # Write to file or stdout
          if options[:output]
            write_to_file(content, options[:output])
          else
            puts content
          end
        end

        def format_content(result, options)
          if result.empty?
            return "(no changes)"
          end

          case options[:format]
          when "summary"
            format_summary(result)
          else
            result.content
          end
        end

        def write_to_file(content, output_path)
          # Create parent directories if needed
          FileUtils.mkdir_p(File.dirname(output_path)) unless File.dirname(output_path) == "."

          # Write content to file
          File.write(output_path, content)

          # Output confirmation to stderr so it doesn't interfere with piping
          warn "Diff written to: #{output_path}"
        end

        def format_summary(result)
          summary = []
          summary << "# Diff Summary"
          summary << ""
          summary << result.summary
          summary << ""

          if result.files.any?
            summary << "## Files Changed"
            result.files.each do |file|
              summary << "- #{file}"
            end
            summary << ""
          end

          summary.join("\n")
        end
      end
    end
  end
end
