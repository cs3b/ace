# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../../organisms/task_doctor"
require_relative "../../molecules/task_doctor_fixer"
require_relative "../../molecules/task_doctor_reporter"
require_relative "../../molecules/task_config_loader"

module Ace
  module Task
    module CLI
      module Commands
        # ace-support-cli Command class for ace-task doctor
        #
        # Runs health checks on tasks and optionally auto-fixes issues.
        class Doctor < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base

          desc <<~DESC.strip
            Run health checks on tasks

            Validates frontmatter, file structure, and scope/status consistency
            across all tasks in the repository. Supports auto-fixing safe issues.

          DESC

          example [
            '                          # Run all health checks',
            '--auto-fix                # Auto-fix safe issues',
            '--auto-fix --dry-run      # Preview fixes without applying',
            '--auto-fix-with-agent     # Auto-fix then launch agent for remaining',
            '--check frontmatter       # Run specific check (frontmatter|structure|scope)',
            '--json                    # Output as JSON',
            '--verbose                 # Show all warnings'
          ]

          option :quiet,    type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose,  type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :auto_fix, type: :boolean, aliases: %w[-f], desc: "Auto-fix safe issues"
          option :auto_fix_with_agent, type: :boolean, desc: "Auto-fix then launch agent for remaining"
          option :model,    type: :string, desc: "Provider:model for agent session"
          option :errors_only, type: :boolean, desc: "Show only errors, not warnings"
          option :no_color, type: :boolean, desc: "Disable colored output"
          option :json,     type: :boolean, desc: "Output in JSON format"
          option :dry_run,  type: :boolean, aliases: %w[-n], desc: "Preview fixes without applying"
          option :check,    type: :string, desc: "Run specific check (frontmatter, structure, scope)"

          def call(**options)
            execute_doctor(options)
          end

          private

          def execute_doctor(options)
            config = Molecules::TaskConfigLoader.load
            root_dir = Molecules::TaskConfigLoader.root_dir(config)

            unless Dir.exist?(root_dir)
              puts "Error: Tasks directory not found: #{root_dir}"
              raise Ace::Core::CLI::Error.new("Tasks directory not found")
            end

            # Normalize options
            format = options[:json] ? :json : :terminal
            fix = options[:auto_fix] || options[:auto_fix_with_agent]
            colors = !options[:no_color]
            colors = false if format == :json

            doctor_opts = {}
            doctor_opts[:check] = options[:check] if options[:check]

            if options[:quiet]
              results = run_diagnosis(root_dir, doctor_opts)
              raise Ace::Core::CLI::Error.new("Health check failed") unless results[:valid]
              return
            end

            results = run_diagnosis(root_dir, doctor_opts)

            # Filter errors-only
            if options[:errors_only] && results[:issues]
              results[:issues] = results[:issues].select { |i| i[:type] == :error }
            end

            output = Molecules::TaskDoctorReporter.format_results(
              results,
              format: format,
              verbose: options[:verbose],
              colors: colors
            )
            puts output

            if fix && results[:issues]&.any?
              handle_auto_fix(results, root_dir, doctor_opts, options, colors)
            end

            if options[:auto_fix_with_agent]
              handle_agent_fix(root_dir, doctor_opts, options, config)
            end

            raise Ace::Core::CLI::Error.new("Health check failed") unless results[:valid]
          rescue Ace::Core::CLI::Error
            raise
          rescue StandardError => e
            raise Ace::Core::CLI::Error.new(e.message)
          end

          def run_diagnosis(root_dir, doctor_opts)
            doctor = Organisms::TaskDoctor.new(root_dir, doctor_opts)
            doctor.run_diagnosis
          end

          def handle_auto_fix(results, root_dir, doctor_opts, options, colors)
            doctor = Organisms::TaskDoctor.new(root_dir, doctor_opts)
            fixable_issues = results[:issues].select { |issue| doctor.auto_fixable?(issue) }

            if fixable_issues.empty?
              puts "\nNo auto-fixable issues found"
              return
            end

            unless options[:quiet] || options[:dry_run]
              puts "\nFound #{fixable_issues.size} auto-fixable issues"
              print "Apply fixes? (y/N): "
              response = $stdin.gets.chomp.downcase
              return unless response == "y" || response == "yes"
            end

            fixer = Molecules::TaskDoctorFixer.new(dry_run: options[:dry_run], root_dir: root_dir)
            fix_results = fixer.fix_issues(fixable_issues)

            output = Molecules::TaskDoctorReporter.format_fix_results(
              fix_results,
              colors: colors
            )
            puts output

            unless options[:dry_run]
              puts "\nRe-running health check after fixes..."
              new_results = run_diagnosis(root_dir, doctor_opts)

              output = Molecules::TaskDoctorReporter.format_results(
                new_results,
                format: :summary,
                verbose: false,
                colors: colors
              )
              puts output
            end
          end

          def handle_agent_fix(root_dir, doctor_opts, options, config)
            require "ace/llm"
            results = run_diagnosis(root_dir, doctor_opts)
            remaining = results[:issues]&.reject { |i| i[:type] == :info }

            if remaining.nil? || remaining.empty?
              puts "\nNo remaining issues for agent to fix."
              return
            end

            issue_list = remaining.map { |i|
              prefix = i[:type] == :error ? "ERROR" : "WARNING"
              "- [#{prefix}] #{i[:message]}#{i[:location] ? " (#{i[:location]})" : ""}"
            }.join("\n")

            provider_model = options[:model] || config.dig("task", "doctor_agent_model") || "gemini:flash-latest@yolo"

            prompt = <<~PROMPT
              The following #{remaining.size} task issues could NOT be auto-fixed and need manual intervention:

              #{issue_list}

              ---

              Fix each issue listed above in the .ace-tasks/ directory.

              IMPORTANT RULES:
              - For invalid ID format issues, inspect the folder name and fix the frontmatter ID to match
              - For YAML syntax errors, read the file and fix the YAML
              - For missing opening delimiter, add '---' at the start of the file
              - Do NOT delete content files — prefer fixing in place
              - For folder naming issues, rename the folder to match {id}-{slug} convention

              ---

              Run `ace-task doctor --verbose` to verify all issues are fixed.
            PROMPT

            puts "\nLaunching agent to fix #{remaining.size} remaining issues..."
            query_options = {
              system: nil,
              timeout: 600,
              fallback: false
            }

            response = Ace::LLM::QueryInterface.query(provider_model, prompt, **query_options)

            puts response[:text]
          end
        end
      end
    end
  end
end
