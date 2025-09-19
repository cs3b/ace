# frozen_string_literal: true

require "dry/cli"

module CodingAgentTools
  module Cli
    module Commands
      module CodeLint
        # CLI command for Ruby-specific code quality validation and linting
        class Ruby < Dry::CLI::Command
          desc "Run code quality validation and linting on Ruby files"

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

          def call(paths: nil, **options)
            require_relative "../../../organisms/code_quality/language_runner_factory"
            require_relative "../../../atoms/code_quality/configuration_loader"
            require_relative "../../../atoms/code_quality/path_resolver"

            # Load configuration
            config_loader = Atoms::CodeQuality::ConfigurationLoader.new(
              config_path: options[:config]
            )
            config = config_loader.load
            path_resolver = Atoms::CodeQuality::PathResolver.new

            # Create Ruby runner
            runner = Organisms::CodeQuality::LanguageRunnerFactory.create_runner(
              "ruby",
              config: config,
              path_resolver: path_resolver
            )

            # Run validation or autofix
            result = if options[:autofix] && !options[:dry_run]
              runner.autofix(paths: paths || ["."])
            else
              runner.validate(paths: paths || ["."])
            end

            # Report results
            runner.report(result) if result

            # Exit with appropriate code
            exit((result && result[:success]) ? 0 : 1)
          rescue => e
            warn "Error: #{e.message}"
            exit 1
          end
        end
      end
    end
  end
end
