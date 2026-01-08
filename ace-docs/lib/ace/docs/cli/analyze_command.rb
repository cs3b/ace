# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../commands/analyze_command"

module Ace
  module Docs
    module CLI
      # dry-cli Command class for the analyze command
      #
      # This wraps the existing AnalyzeCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class AnalyzeCommand < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Analyze changes for a document with LLM

          Analyze git changes for a document using an LLM to understand what content
          has changed and whether documentation updates are needed.

          Configuration:
            LLM model configured via ace-llm
            Global config:  ~/.ace/docs/config.yml
            Project config: .ace/docs/config.yml

          Output:
            Analysis results printed to stdout
            Exit codes: 0 (success), 1 (error)
        DESC

        example [
          "ace-docs analyze README.md",
          "ace-docs analyze docs/architecture.md --since '2025-01-01'",
          "ace-docs analyze file.md --exclude-renames --exclude-moves"
        ]

        argument :file, required: true, desc: "File to analyze"

        option :since, type: :string, desc: "Date or commit to analyze from"
        option :exclude_renames, type: :boolean, desc: "Exclude renamed files from diff"
        option :exclude_moves, type: :boolean, desc: "Exclude moved files from diff"

        # Standard options
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        def call(file:, **options)
          # Handle --help/-h passed as file argument
          if file == "--help" || file == "-h"
            # dry-cli will handle help automatically, so we just ignore
            return 0
          end

          command = Commands::AnalyzeCommand.new(options)
          exit_code = command.execute(file)
          return exit_code if exit_code != 0
          0
        rescue StandardError => e
          warn "Error analyzing document: #{e.message}"
          warn e.backtrace.join("\n  ") if debug?(options)
          1
        end
      end
    end
  end
end
