# frozen_string_literal: true

require_relative 'language_runner'
require_relative '../../molecules/code_quality/ruby_linting_pipeline'
require_relative '../../atoms/code_quality/language_file_filter'

module CodingAgentTools
  module Organisms
    module CodeQuality
      # Ruby-specific code quality runner
      class RubyRunner < LanguageRunner
        def initialize(config:, path_resolver:)
          super(config: config, path_resolver: path_resolver, language: :ruby)
          @pipeline = create_pipeline
          @file_filter = Atoms::CodeQuality::LanguageFileFilter.new(config: config)
        end

        def validate(paths: ['.'], **_options)
          return skip_result unless language_enabled?

          filtered_paths = filter_ruby_files(paths)
          return skip_result if filtered_paths.empty?

          @pipeline.run(paths: filtered_paths, autofix: false)
        end

        def autofix(paths: ['.'], **_options)
          return skip_result unless language_enabled?

          filtered_paths = filter_ruby_files(paths)
          return skip_result if filtered_paths.empty?

          @pipeline.run(paths: filtered_paths, autofix: true)
        end

        def report(results)
          return unless results && !results[:success].nil?

          puts format_summary(results)
          format_detailed_findings(results) if results[:findings]&.any?
        end

        private

        def create_pipeline
          Molecules::CodeQuality::RubyLintingPipeline.new(
            config: @config,
            path_resolver: @path_resolver
          )
        end

        def skip_result
          {
            success: true,
            total_issues: 0,
            linters: {},
            findings: [],
            skipped: true,
            reason: 'Ruby linting disabled in configuration'
          }
        end

        def format_summary(results)
          status = results[:success] ? '✅ PASSED' : '❌ FAILED'
          total_issues = results[:total_issues] || 0
          "Ruby linters: #{total_issues} issues found - #{status}"
        end

        def format_detailed_findings(results)
          return unless results[:linters]

          results[:linters].each do |linter_name, linter_result|
            next unless linter_result[:findings]&.any?

            puts "\n  #{linter_name.to_s.upcase}:"
            linter_result[:findings].each do |finding|
              puts format_finding(finding, linter_name)
            end
          end
        end

        def filter_ruby_files(paths)
          @file_filter.expand_paths_for_language(paths, :ruby)
        end

        def format_finding(finding, linter_name)
          case linter_name.to_sym
          when :standardrb
            location = "#{finding[:file]}:#{finding[:line]}:#{finding[:column]}"
            severity = finding[:severity] == 'error' ? '❌' : '⚠️'
            "    #{severity} #{location} - #{finding[:message]} (#{finding[:cop]})"
          when :security
            "    ⚠️  Security: #{finding}"
          when :cassettes
            "    ⚠️  #{finding[:path]} - #{finding[:size_formatted]} (threshold exceeded)"
          else
            "    • #{finding}"
          end
        end
      end
    end
  end
end
