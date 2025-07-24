# frozen_string_literal: true

require_relative "language_runner"
require_relative "../../molecules/code_quality/markdown_linting_pipeline"

module CodingAgentTools
  module Organisms
    module CodeQuality
      # Markdown-specific code quality runner
      class MarkdownRunner < LanguageRunner
        def initialize(config:, path_resolver:)
          super(config: config, path_resolver: path_resolver, language: :markdown)
          @pipeline = create_pipeline
        end

        def validate(paths: ["."], **options)
          return skip_result unless language_enabled?

          @pipeline.run(paths: paths, autofix: false)
        end

        def autofix(paths: ["."], **options)
          return skip_result unless language_enabled?

          @pipeline.run(paths: paths, autofix: true)
        end

        def report(results)
          return unless results && !results[:success].nil?

          puts format_summary(results)
          format_detailed_findings(results) if results[:findings]&.any?
        end

        private

        def create_pipeline
          Molecules::CodeQuality::MarkdownLintingPipeline.new(
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
            reason: "Markdown linting disabled in configuration"
          }
        end

        def format_summary(results)
          status = results[:success] ? "✅ PASSED" : "❌ FAILED"
          total_issues = results[:total_issues] || 0
          "Markdown linters: #{total_issues} issues found - #{status}"
        end

        def format_detailed_findings(results)
          return unless results[:linters]

          results[:linters].each do |linter_name, linter_result|
            next unless should_show_linter_results?(linter_result)

            puts "\n  #{linter_name.to_s.upcase}:"
            show_linter_output(linter_result, linter_name)
          end
        end

        def should_show_linter_results?(linter_result)
          linter_result[:findings]&.any? || linter_result[:errors]&.any?
        end

        def show_linter_output(linter_result, linter_name)
          if linter_result[:findings]&.any?
            linter_result[:findings].each do |finding|
              puts format_finding(finding, linter_name)
            end
          elsif linter_result[:errors]&.any?
            linter_result[:errors].each do |error|
              puts "    ❌ #{error}"
            end
          end
        end

        def format_finding(finding, linter_name)
          case linter_name.to_sym
          when :task_metadata, :link_validation, :template_embedding
            if finding.is_a?(Hash)
              file = finding[:file] || "unknown"
              message = finding[:message] || finding[:template] || finding[:link] || "issue"
              "    ❌ #{file} - #{message}"
            else
              "    ❌ #{finding}"
            end
          else
            "    • #{finding}"
          end
        end
      end
    end
  end
end
