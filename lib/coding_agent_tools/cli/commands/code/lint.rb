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
            require_relative "../../../organisms/code_quality/multi_phase_quality_manager"

            manager = Organisms::CodeQuality::MultiPhaseQualityManager.new(
              config_path: options[:config],
              dry_run: options[:dry_run]
            )

            if options[:validate_config]
              if manager.validate_configuration
                puts "Configuration is valid"
                exit 0
              else
                puts "Configuration is invalid"
                exit 1
              end
            end

            result = manager.run(
              target: target,
              paths: paths || ["."],
              autofix: options[:autofix],
              review_diff: options[:review_diff],
              show_details: true
            )

            exit(result[:success] ? 0 : 1)
          rescue => e
            warn "Error: #{e.message}"
            exit 1
          end
        end
      end
    end
  end
end
