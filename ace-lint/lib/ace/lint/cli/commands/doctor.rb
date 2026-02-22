# frozen_string_literal: true

require "dry/cli"
require "ace/core/cli/dry_cli/base"
require_relative "../../organisms/lint_doctor"

module Ace
  module Lint
    module CLI
      module Commands
        # Doctor command for diagnosing lint configuration health
        class Doctor < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          # Exit codes for diagnostic results
          EXIT_HEALTHY = 0  # No issues found
          EXIT_WARNINGS = 1  # Warnings present
          EXIT_ERRORS = 2  # Errors present

          desc <<~DESC.strip
            Check linting configuration health

            Diagnoses:
              - Validator availability (StandardRB, RuboCop)
              - Configuration file locations and existence
              - Pattern coverage for validator groups

            Output:
              Displays diagnostic results with status indicators:
                [OK]   - Configuration is correct
                [WARN] - Potential issue that may affect linting
                [ERR]  - Configuration error that needs fixing

            Exit codes: 0 (healthy), 1 (warnings), 2 (errors)
          DESC

          example [
            "                    # Check configuration health",
            "--verbose           # Show all diagnostics including info"
          ]

          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show all diagnostics including info"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(**options)
            ruby_groups = Ace::Lint.ruby_config&.dig("groups")
            doctor = Organisms::LintDoctor.new(project_root: Dir.pwd, groups: ruby_groups)
            diagnostics = doctor.diagnose

            # Filter diagnostics based on options
            if options[:quiet]
              diagnostics = diagnostics.reject(&:info?)
            end

            # Display results
            display_diagnostics(diagnostics, verbose: options[:verbose])

            # Raise on errors or warnings
            if doctor.errors?
              raise Ace::Core::CLI::Error.new("Configuration has errors", exit_code: EXIT_ERRORS)
            elsif doctor.warnings?
              raise Ace::Core::CLI::Error.new("Configuration has warnings", exit_code: EXIT_WARNINGS)
            end
          end

          private

          def display_diagnostics(diagnostics, verbose: false)
            if diagnostics.empty?
              puts "No diagnostics to display."
              return
            end

            # Group by category
            by_category = diagnostics.group_by(&:category)

            by_category.each do |category, items|
              puts "\n#{format_category(category)}:"
              puts "-" * 40

              items.each do |diag|
                # Skip info unless verbose
                next if diag.info? && !verbose

                puts "  #{format_level(diag.level)} #{diag.message}"
              end
            end

            puts "\n"
            display_summary(diagnostics)
          end

          def format_category(category)
            case category
            when :validator
              "Validators"
            when :config
              "Configuration Files"
            when :pattern
              "Pattern Groups"
            else
              category.to_s.capitalize
            end
          end

          def format_level(level)
            case level
            when :error
              "[ERR] "
            when :warning
              "[WARN]"
            when :info
              "[OK]  "
            else
              "[???] "
            end
          end

          def display_summary(diagnostics)
            errors = diagnostics.count(&:error?)
            warnings = diagnostics.count(&:warning?)
            infos = diagnostics.count(&:info?)

            parts = []
            parts << "#{errors} error(s)" if errors > 0
            parts << "#{warnings} warning(s)" if warnings > 0
            parts << "#{infos} OK" if infos > 0

            status = if errors > 0
              "Configuration has issues"
            elsif warnings > 0
              "Configuration has warnings"
            else
              "Configuration looks healthy"
            end

            puts "Summary: #{status}"
            puts "         #{parts.join(", ")}"
          end
        end
      end
    end
  end
end
