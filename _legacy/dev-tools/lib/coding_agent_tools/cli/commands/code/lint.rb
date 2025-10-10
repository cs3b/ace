# frozen_string_literal: true

require "dry/cli"

module CodingAgentTools
  module Cli
    module Commands
      module Code
        class Lint < Dry::CLI::Command
          desc "Run code quality validation and linting"

          argument :paths, desc: "Paths to lint", type: :array, required: false

          option :autofix,
            desc: "Apply moderate-level automatic fixes",
            type: :boolean,
            default: false,
            aliases: ["a"]

          option :config,
            desc: "Path to custom configuration file",
            type: :string,
            aliases: ["c"]

          option :dry_run,
            desc: "Show what would be done without making changes",
            type: :boolean,
            default: false,
            aliases: ["n"]

          option :review_diff,
            desc: "Review all changes made during autofix",
            type: :boolean,
            default: false,
            aliases: ["r"]

          option :validate_config,
            desc: "Validate configuration file and exit",
            type: :boolean,
            default: false

          def call(target: "all", paths: nil, **options)
            # Delegate to the new CodeLint::All command to maintain backwards compatibility
            require_relative "../../code_lint/all"

            command = Commands::CodeLint::All.new
            command.call(target: target, paths: paths, **options)
          end
        end
      end
    end
  end
end
