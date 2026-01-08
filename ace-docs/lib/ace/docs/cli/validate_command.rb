# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../commands/validate_command"

module Ace
  module Docs
    module CLI
      # dry-cli Command class for the validate command
      #
      # This wraps the existing ValidateCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class ValidateCommand < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Validate documents against rules

          Validate documents against configured rules. Syntax validation uses linters,
          semantic validation uses LLM analysis.

          Configuration:
            Validation rules configured via ace-lint
            Global config:  ~/.ace/docs/config.yml
            Project config: .ace/docs/config.yml

          Output:
            Validation report printed to stdout
            Exit codes: 0 (pass), 1 (fail), 2 (error)
        DESC

        example [
          "ace-docs validate                      # Validate all documents",
          "ace-docs validate README.md            # Validate specific file",
          "ace-docs validate docs/**/*.md         # Validate by pattern",
          "ace-docs validate --syntax             # Run syntax validation only",
          "ace-docs validate --semantic           # Run semantic validation only",
          "ace-docs validate --all                # Run all validation types"
        ]

        argument :pattern, required: false, desc: "File or pattern to validate"

        option :syntax, type: :boolean, desc: "Run syntax validation using linters"
        option :semantic, type: :boolean, desc: "Run semantic validation using LLM"
        option :all, type: :boolean, desc: "Run all validation types"

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

          command = Commands::ValidateCommand.new(options)
          exit_code = command.execute(pattern)
          return exit_code if exit_code != 0
          0
        rescue StandardError => e
          warn "Error validating documents: #{e.message}"
          warn e.backtrace.join("\n  ") if debug?(options)
          1
        end
      end
    end
  end
end
