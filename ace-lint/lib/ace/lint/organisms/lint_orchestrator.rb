# frozen_string_literal: true

require_relative '../atoms/type_detector'
require_relative '../molecules/markdown_linter'
require_relative '../molecules/yaml_linter'
require_relative '../molecules/frontmatter_validator'
require_relative '../molecules/kramdown_formatter'
require_relative '../molecules/ruby_linter'
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
          # Group files by type for batch processing
          files_by_type = group_files_by_type(file_paths, options: options)

          # Batch process Ruby files (performance optimization)
          @results = []

          # Process non-Ruby files individually
          non_ruby_files = files_by_type.reject { |type, _| type == :ruby }
          non_ruby_files.each do |type, paths|
            paths.each do |file_path|
              @results << lint_single_file_by_type(file_path, type, options: options)
            end
          end

          # Batch process Ruby files
          if files_by_type[:ruby]&.any?
            ruby_results = batch_lint_ruby(files_by_type[:ruby], options: options)
            @results.concat(ruby_results)
          end

          @results
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

        # Group files by type for batch processing
        # @param file_paths [Array<String>] Paths to files
        # @param options [Hash] Linting options
        # @return [Hash] Files grouped by type
        def group_files_by_type(file_paths, options: {})
          groups = Hash.new { |h, k| h[k] = [] }

          file_paths.each do |file_path|
            type = options[:type] || detect_type(file_path)
            groups[type] << file_path
          end

          groups
        end

        # Lint a single file by its type
        # @param file_path [String] Path to the file
        # @param type [Symbol] File type
        # @param options [Hash] Linting options
        # @return [Models::LintResult] Lint result
        def lint_single_file_by_type(file_path, type, options: {})
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
          when :ruby
            Molecules::RubyLinter.lint(file_path, options: options)
          else
            # Skip unsupported file types instead of erroring
            Models::LintResult.skipped(file_path: file_path, reason: "Unsupported file type: #{type}")
          end
        end

        # Batch lint Ruby files for performance
        #
        # Ruby files are processed in batch for performance optimization - a single
        # StandardRB subprocess handles all Ruby files together. Other file types
        # (markdown, YAML) are processed individually due to different validation
        # requirements and tool limitations.
        #
        # @param file_paths [Array<String>] Paths to Ruby files
        # @param options [Hash] Linting options
        # @return [Array<Models::LintResult>] Results for each file
        def batch_lint_ruby(file_paths, options: {})
          return [] if file_paths.empty?

          # Check if formatting is requested (not supported for batch)
          needs_formatting = options[:fix] || options[:format]

          if needs_formatting
            # Fall back to individual file processing for formatting
            file_paths.map do |file_path|
              Molecules::RubyLinter.lint(file_path, options: options)
            end
          else
            # Use batch processing for better performance
            Molecules::RubyLinter.lint_batch(file_paths, options: options)
          end
        end

        def lint_single_file(file_path, options: {})
          type = options[:type] || detect_type(file_path)
          lint_single_file_by_type(file_path, type, options: options)
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
