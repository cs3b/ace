# frozen_string_literal: true

module Ace
  module TestRunner
    module Atoms
      class LazyLoader
        class << self
          def load_formatter(format)
            case format
            when "ai"
              require_relative "../formatters/ai_formatter"
              Formatters::AiFormatter
            when "compact"
              require_relative "../formatters/compact_formatter"
              Formatters::CompactFormatter
            when "json"
              require_relative "../formatters/json_formatter"
              Formatters::JsonFormatter
            when "markdown"
              require_relative "../formatters/markdown_formatter"
              Formatters::MarkdownFormatter
            when "progress"
              require_relative "../formatters/progress_formatter"
              Formatters::ProgressFormatter
            when "progress-file"
              require_relative "../formatters/progress_file_formatter"
              Formatters::ProgressFileFormatter
            else
              raise ArgumentError, "Unknown format: #{format}"
            end
          end

          def load_molecule(name)
            case name
            when :pattern_resolver
              require_relative "../molecules/pattern_resolver"
              Molecules::PatternResolver
            when :config_loader
              require_relative "../molecules/config_loader"
              Molecules::ConfigLoader
            when :deprecation_fixer
              require_relative "../molecules/deprecation_fixer"
              Molecules::DeprecationFixer
            when :rake_integration
              require_relative "../molecules/rake_integration"
              Molecules::RakeIntegration
            else
              raise ArgumentError, "Unknown molecule: #{name}"
            end
          end

          def load_organism(name)
            case name
            when :report_generator
              require_relative "../organisms/report_generator"
              Organisms::ReportGenerator
            when :agent_reporter
              require_relative "../organisms/agent_reporter"
              Organisms::AgentReporter
            else
              raise ArgumentError, "Unknown organism: #{name}"
            end
          end
        end
      end
    end
  end
end