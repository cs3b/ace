# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../commands/analyze_consistency_command"

module Ace
  module Docs
    module CLI
      # dry-cli Command class for the analyze-consistency command
      #
      # This wraps the existing AnalyzeConsistencyCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class AnalyzeConsistencyCommand < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Analyze cross-document consistency

          Analyze multiple documents for consistency issues including terminology
          conflicts, duplicate content, and version inconsistencies.

          Configuration:
            LLM model configured via ace-llm
            Global config:  ~/.ace/docs/config.yml
            Project config: .ace/docs/config.yml

          Output:
            Consistency report in markdown format (default)
            Exit codes: 0 (success), 1 (issues found with --strict), 2 (error)
        DESC

        example [
          "ace-docs analyze-consistency",
          "ace-docs analyze-consistency docs/handbook/",
          "ace-docs analyze-consistency --terminology",
          "ace-docs analyze-consistency --duplicates --threshold 80",
          "ace-docs analyze-consistency --save",
          "ace-docs analyze-consistency --model gpt-4"
        ]

        argument :pattern, required: false, desc: "Pattern to analyze"

        option :terminology, type: :boolean, desc: "Check terminology conflicts only"
        option :duplicates, type: :boolean, desc: "Find duplicate content only"
        option :versions, type: :boolean, desc: "Check version consistency only"
        option :all, type: :boolean, desc: "All analysis types (default)"
        option :threshold, type: :integer, desc: "Similarity threshold for duplicates (default: 70)"
        option :output, type: :string, desc: "Output format (markdown|json|text)", default: "markdown"
        option :save, type: :boolean, desc: "Save report to cache directory"
        option :model, type: :string, desc: "LLM model to use (default: gflash)"
        option :timeout, type: :integer, desc: "LLM timeout in seconds"
        option :strict, type: :boolean, desc: "Exit with code 1 if issues found"

        # Standard options
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        def call(pattern: nil, **options)
          # Handle --help/-h passed as pattern argument
          if pattern == "--help" || pattern == "-h"
            # dry-cli will handle help automatically, so we just ignore
            return 0
          end

          # Type-convert numeric options (dry-cli returns strings, Thor converted to integers)
          numeric_options = %i[threshold timeout]
          numeric_options.each do |key|
            options[key] = options[key].to_i if options[key]
          end

          command = Commands::AnalyzeConsistencyCommand.new(options)
          exit_code = command.execute(pattern)
          return exit_code if exit_code != 0
          0
        rescue StandardError => e
          warn "Error analyzing consistency: #{e.message}"
          warn e.backtrace.join("\n  ") if debug?(options)
          1
        end
      end
    end
  end
end
