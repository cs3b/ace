# frozen_string_literal: true

require_relative "../atoms/type_detector"
require_relative "../molecules/markdown_linter"
require_relative "../molecules/yaml_linter"
require_relative "../molecules/frontmatter_validator"
require_relative "../molecules/kramdown_formatter"
require_relative "../molecules/markdown_surgical_fixer"
require_relative "../molecules/ruby_linter"
require_relative "../molecules/group_resolver"
require_relative "../molecules/skill_validator"
require_relative "../models/lint_result"

module Ace
  module Lint
    module Organisms
      # Orchestrates linting of multiple files
      # Supports group-based validator configuration for Ruby files
      class LintOrchestrator
        attr_reader :results

        # Initialize orchestrator
        # @param ruby_groups [Hash, nil] Ruby validator groups configuration
        def initialize(ruby_groups: nil)
          @results = []
          @group_resolver = ruby_groups ? Molecules::GroupResolver.new(ruby_groups) : nil
        end

        # Lint multiple files
        # @param file_paths [Array<String>] Paths to files
        # @param options [Hash] Linting options
        # @option options [Symbol] :type Force file type (:markdown, :yaml, :frontmatter)
        # @option options [Boolean] :fix Apply fixes
        # @option options [Boolean] :format Format files
        # @option options [Hash] :kramdown_options Kramdown options
        # @option options [Array<Symbol>] :validators CLI override for validators
        # @return [Array<Models::LintResult>] Results for all files
        def lint_files(file_paths, options: {})
          # Group files by type for batch processing
          files_by_type = group_files_by_type(file_paths, options: options)

          # Batch process Ruby files (performance optimization)
          @results = []

          # Process non-Ruby files individually
          non_ruby_files = files_by_type.except(:ruby)
          non_ruby_files.each do |type, paths|
            paths.each do |file_path|
              @results << lint_single_file_by_type(file_path, type, options: options)
            end
          end

          # Batch process Ruby files (with group-aware routing)
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
          when :skill, :workflow, :agent
            # Skill/workflow/agent files get both markdown and skill-specific validation
            lint_skill_file(file_path, type, options)
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
        # When group configuration is available, files are grouped by validator
        # configuration and each group is processed separately.
        #
        # @param file_paths [Array<String>] Paths to Ruby files
        # @param options [Hash] Linting options
        # @return [Array<Models::LintResult>] Results for each file
        def batch_lint_ruby(file_paths, options: {})
          return [] if file_paths.empty?

          # CLI --validators flag takes highest precedence
          cli_validators = options[:validators]

          # Check if formatting is requested (not supported for batch)
          needs_formatting = options[:fix] || options[:format]

          # Use group-based routing if resolver is available and no CLI override
          if @group_resolver && !cli_validators
            return batch_lint_ruby_by_groups(file_paths, options: options, needs_formatting: needs_formatting)
          end

          # Standard batch processing (with optional CLI validator override)
          lint_options = options.dup
          lint_options[:validators] = cli_validators if cli_validators

          if needs_formatting
            # Fall back to individual file processing for formatting
            file_paths.map do |file_path|
              Molecules::RubyLinter.lint(file_path, options: lint_options)
            end
          else
            # Use batch processing for better performance
            Molecules::RubyLinter.lint_batch(file_paths, options: lint_options)
          end
        end

        # Batch lint Ruby files grouped by validator configuration
        # @param file_paths [Array<String>] Paths to Ruby files
        # @param options [Hash] Linting options
        # @param needs_formatting [Boolean] Whether formatting is needed
        # @return [Array<Models::LintResult>] Results for each file
        def batch_lint_ruby_by_groups(file_paths, options:, needs_formatting:)
          grouped = @group_resolver.resolve_batch(file_paths)
          results = []

          grouped.each do |_group_name, group_data|
            group_files = group_data[:files]
            next if group_files.empty?

            # Build options with group validators
            group_options = options.dup
            group_options[:validators] = group_data[:validators] unless group_data[:validators].empty?
            group_options[:fallback_validators] = group_data[:fallback_validators]
            group_options[:config_path] = group_data[:config_path] if group_data[:config_path]

            if needs_formatting
              # Individual file processing for formatting
              group_files.each do |file_path|
                results << Molecules::RubyLinter.lint(file_path, options: group_options)
              end
            else
              # Batch processing for performance
              results.concat(Molecules::RubyLinter.lint_batch(group_files, options: group_options))
            end
          end

          results
        end

        def lint_single_file(file_path, options: {})
          type = options[:type] || detect_type(file_path)
          lint_single_file_by_type(file_path, type, options: options)
        end

        def detect_type(file_path)
          content = begin
            File.read(file_path)
          rescue
            nil
          end
          Atoms::TypeDetector.detect(file_path, content: content)
        end

        def lint_markdown(file_path, options)
          kramdown_opts = options[:kramdown_options] || {}
          Molecules::MarkdownLinter.lint(file_path, options: kramdown_opts)
        end

        # Lint skill/workflow/agent files with both markdown and skill-specific validation
        # @param file_path [String] Path to the file
        # @param type [Symbol] File type (:skill, :workflow, :agent)
        # @param options [Hash] Linting options
        # @return [Models::LintResult] Combined validation result
        def lint_skill_file(file_path, type, options)
          # Run standard markdown validation first
          md_result = lint_markdown(file_path, options)

          # Run skill-specific validation
          skill_result = Molecules::SkillValidator.validate(file_path, type, options: options)

          # Merge results
          merge_lint_results(file_path, md_result, skill_result)
        end

        # Merge two lint results into one
        # @param file_path [String] Path for the combined result
        # @param result1 [Models::LintResult] First result
        # @param result2 [Models::LintResult] Second result
        # @return [Models::LintResult] Combined result
        def merge_lint_results(file_path, result1, result2)
          combined_errors = (result1.errors || []) + (result2.errors || [])
          combined_warnings = (result1.warnings || []) + (result2.warnings || [])

          Models::LintResult.new(
            file_path: file_path,
            success: combined_errors.empty?,
            errors: combined_errors,
            warnings: combined_warnings,
            formatted: result1.formatted || result2.formatted
          )
        end

        def apply_formatting(file_path, type, options)
          # Skill, workflow, and agent files are markdown-based and support formatting
          return nil unless [:markdown, :skill, :workflow, :agent].include?(type)

          warnings = []
          formatted = false

          if options[:fix]
            fix_result = Molecules::MarkdownSurgicalFixer.fix_file(file_path)
            unless fix_result[:success]
              return Models::LintResult.new(
                file_path: file_path,
                success: false,
                errors: fix_result[:errors].map { |msg| Models::ValidationError.new(message: msg) },
                warnings: [],
                formatted: false
              )
            end
            warnings.concat(Array(fix_result[:warnings]).map { |msg| Models::ValidationError.new(message: msg, severity: :warning) })
            formatted ||= fix_result[:formatted]
          end

          return nil unless options[:format] || options[:fix]

          unless options[:format]
            return Models::LintResult.new(
              file_path: file_path,
              success: true,
              errors: [],
              warnings: warnings,
              formatted: formatted
            )
          end

          kramdown_opts = options[:kramdown_options] || {}
          format_result = Molecules::KramdownFormatter.format_file(file_path, options: kramdown_opts, guardrails: true)

          if format_result[:success]
            warnings.concat(Array(format_result[:warnings]).map { |msg| Models::ValidationError.new(message: msg, severity: :warning) })
            Models::LintResult.new(
              file_path: file_path,
              success: true,
              errors: [],
              warnings: warnings,
              formatted: formatted || format_result[:formatted]
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
