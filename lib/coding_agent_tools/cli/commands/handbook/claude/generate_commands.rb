# frozen_string_literal: true

require "dry/cli"
require_relative "../../../../organisms/claude_command_generator"

module CodingAgentTools
  module Cli
    module Commands
      module Handbook
        module Claude
          class GenerateCommands < Dry::CLI::Command
            desc "Generate missing Claude commands from workflow files"

            option :dry_run, type: :boolean, default: false, desc: "Show what would be generated"
            option :force, type: :boolean, default: false, desc: "Overwrite existing generated commands"
            option :workflow, type: :string, desc: "Generate for specific workflow (supports glob patterns)"

            def call(**options)
              generator = CodingAgentTools::Organisms::ClaudeCommandGenerator.new
              result = generator.generate(options)

              exit(result.success ? 0 : 1)
            rescue StandardError => e
              puts "Error: #{e.message}"
              puts e.backtrace if ENV['DEBUG']
              exit(1)
            end
          end
        end
      end
    end
  end
end