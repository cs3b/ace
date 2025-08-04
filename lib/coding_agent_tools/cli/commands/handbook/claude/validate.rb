# frozen_string_literal: true

require "dry/cli"
require_relative "../../../../organisms/claude_validator"

module CodingAgentTools
  module Cli
    module Commands
      module Handbook
        module Claude
          class Validate < Dry::CLI::Command
            desc "Validate Claude command coverage"

            option :check, type: :string, desc: "Specific check to run (missing, outdated, duplicates)"
            option :strict, type: :boolean, default: false, desc: "Exit with code 1 if issues found"
            option :workflow, type: :string, desc: "Validate specific workflow"
            option :format, type: :string, default: 'text', values: %w[text json], desc: "Output format"

            example [
              '',
              '--check missing',
              '--workflow draft-task',
              '--strict --format json'
            ]

            def call(**options)
              validator = CodingAgentTools::Organisms::ClaudeValidator.new
              result = validator.validate(options)

              puts result.to_s

              exit_code = if options[:strict] && !result.success
                            1
                          else
                            result.success ? 0 : 1
                          end

              exit(exit_code)
            rescue StandardError => e
              warn "Error: #{e.message}"
              warn e.backtrace if ENV['DEBUG']
              exit(1)
            end
          end
        end
      end
    end
  end
end