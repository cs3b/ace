# frozen_string_literal: true

require_relative '../atoms/type_detector'
require_relative '../molecules/markdown_linter'
require_relative '../molecules/yaml_linter'
require_relative '../molecules/frontmatter_validator'
require_relative '../molecules/kramdown_formatter'
require_relative '../models/lint_result'

module Ace
  module Lint
    module Organisms
      # Orchestrates linting of multiple files
      class LintOrchestrator
        attr_reader :results

        def initialize
          @results = []
        end

        # Lint multiple files
        # @param file_paths [Array<String>] Paths to files
        # @param options [Hash] Linting options
        # @option options [Symbol] :type Force file type (:markdown, :yaml, :frontmatter)
        # @option options [Boolean] :fix Apply fixes
        # @option options [Boolean] :format Format files
        # @option options [Hash] :kramdown_options Kramdown options
        # @return [Array<Models::LintResult>] Results for all files
        def lint_files(file_paths, options: {})
          @results = file_paths.map do |file_path|
            lint_single_file(file_path, options: options)
          end
        end

        # Check if any file failed
        # @return [Boolean] True if any file failed
        def any_failures?
          @results.any?(&:failed?)
        end

        # Get count of passed files
        # @return [Integer] Count of passed files
        def passed_count
          @results.count(&:success)
        end

        # Get count of failed files
        # @return [Integer] Count of failed files
        def failed_count
          @results.count(&:failed?)
        end

        # Get total error count across all files
        # @return [Integer] Total error count
        def total_errors
          @results.sum(&:error_count)
        end

        # Get total warning count across all files
        # @return [Integer] Total warning count
        def total_warnings
          @results.sum(&:warning_count)
        end

        private

        def lint_single_file(file_path, options: {})
          # Detect file type
          type = options[:type] || detect_type(file_path)

          # Apply formatting if requested
          if options[:fix] || options[:format]
            format_result = apply_formatting(file_path, type, options)
            return format_result unless format_result.nil?
          end

          # Lint based on type
          case type
          when :markdown
            lint_markdown(file_path, options)
          when :yaml
            Molecules::YamlLinter.lint(file_path)
          when :frontmatter
            Molecules::FrontmatterValidator.lint(file_path)
          else
            Models::LintResult.new(
              file_path: file_path,
              success: false,
              errors: [Models::ValidationError.new(message: "Unknown file type: #{type}")]
            )
          end
        end

        def detect_type(file_path)
          content = begin
            File.read(file_path)
          rescue StandardError
            nil
          end
          Atoms::TypeDetector.detect(file_path, content: content)
        end

        def lint_markdown(file_path, options)
          kramdown_opts = options[:kramdown_options] || {}
          Molecules::MarkdownLinter.lint(file_path, options: kramdown_opts)
        end

        def apply_formatting(file_path, type, options)
          return nil unless type == :markdown

          kramdown_opts = options[:kramdown_options] || {}
          format_result = Molecules::KramdownFormatter.format_file(file_path, options: kramdown_opts)

          if format_result[:success]
            Models::LintResult.new(
              file_path: file_path,
              success: true,
              errors: [],
              warnings: [],
              formatted: format_result[:formatted]
            )
          else
            Models::LintResult.new(
              file_path: file_path,
              success: false,
              errors: format_result[:errors].map { |msg| Models::ValidationError.new(message: msg) },
              formatted: false
            )
          end
        end
      end
    end
  end
end
