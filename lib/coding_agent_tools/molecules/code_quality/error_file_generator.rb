# frozen_string_literal: true

require_relative "../../atoms/code_quality/error_distributor"

module CodingAgentTools
  module Molecules
    module CodeQuality
      # Molecule for generating error distribution files
      class ErrorFileGenerator
        attr_reader :output_dir, :error_distributor, :project_root

        def initialize(output_dir: ".", max_files: 4)
          @output_dir = output_dir
          @project_root = output_dir  # Store project root for making paths relative
          @error_distributor = Atoms::CodeQuality::ErrorDistributor.new(
            max_files: max_files,
            one_issue_per_file: true
          )
        end

        def generate(linting_results)
          # Extract all errors from results
          all_errors = extract_errors(linting_results)

          # Distribute errors
          distribution = error_distributor.distribute(all_errors)

          # Generate error files
          generated_files = []
          distribution[:distributions].each do |dist|
            file_path = generate_error_file(dist)
            generated_files << file_path if file_path
          end

          {
            success: true,
            files_generated: generated_files,
            total_errors: distribution[:total_errors],
            files_with_errors: distribution[:files_with_errors]
          }
        end

        def cleanup
          # Remove existing error files
          Dir.glob(File.join(output_dir, ".lint-errors-*.md")).each do |file|
            File.delete(file)
          end
        end

        private

        def extract_errors(results)
          errors = []

          # Extract Ruby errors
          results.dig(:ruby, :linters)&.each do |linter, data|
            next unless data[:findings]

            data[:findings].each do |finding|
              errors << format_error(linter, "ruby", finding)
            end
          end

          # Extract Markdown errors
          results.dig(:markdown, :linters)&.each do |linter, data|
            if data[:findings]
              data[:findings].each do |finding|
                errors << format_error(linter, "markdown", finding)
              end
            elsif data[:errors]
              data[:errors].each_with_index do |error, idx|
                errors << {
                  file: extract_file_from_error(error) || "unknown",
                  type: "markdown_#{linter}",
                  message: error,
                  severity: "error",
                  line: nil
                }
              end
            end
          end

          errors
        end

        def format_error(linter, language, finding)
          file_path = finding[:file] || finding[:path] || "unknown"
          relative_path = make_path_relative(file_path)

          {
            file: relative_path,
            type: "#{language}_#{linter}",
            message: finding[:message] || finding.to_s,
            line: finding[:line] || finding[:line_no],
            column: finding[:column],
            severity: finding[:severity] || "warning"
          }
        end

        def extract_file_from_error(error_string)
          # Try to extract file path from error message
          if error_string =~ /^(.+?):(\d+):/
            $1
          elsif error_string =~ /^(.+\.(?:rb|md)):/
            $1
          end
        end

        def generate_error_file(distribution)
          file_path = File.join(output_dir, ".lint-errors-#{distribution[:file_number]}.md")

          content = build_error_file_content(distribution)
          File.write(file_path, content)

          file_path
        end

        def build_error_file_content(distribution)
          content = []
          content << "# Lint Errors - Group #{distribution[:file_number]}"
          content << ""
          content << "This file contains #{distribution[:error_count]} error(s) to be fixed."
          content << ""

          # Group errors by file
          errors_by_file = distribution[:errors].group_by { |e| e[:file] }

          errors_by_file.each do |file, errors|
            content << "## #{file}"
            content << ""

            errors.each do |error|
              content << format_error_entry(error)
              content << ""
            end
          end

          content.join("\n")
        end

        def format_error_entry(error)
          lines = []

          location = error[:file]
          location += ":#{error[:line]}" if error[:line]
          location += ":#{error[:column]}" if error[:column]

          lines << "### #{error[:type]}"
          lines << ""
          lines << "**Location:** `#{location}`"
          lines << "**Severity:** #{error[:severity]}"
          lines << ""
          lines << "**Issue:**"
          lines << "```"
          lines << error[:message]
          lines << "```"

          lines.join("\n")
        end

        def make_path_relative(path)
          return path unless path && File.absolute_path?(path)

          path.start_with?(@project_root) ? path.sub("#{@project_root}/", "") : path
        end
      end
    end
  end
end
