# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../../organisms/taskflow_doctor"
require_relative "../../molecules/doctor_fixer"
require_relative "../../molecules/doctor_reporter"
require_relative "../../molecules/command_option_parser"

module Ace
  module Taskflow
    module CLI
      module Commands
        # dry-cli Command class for the doctor command
        #
        # This command runs health checks and auto-fixes issues.
        class Doctor < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Run health checks and auto-fix issues"
          example [
            '                          # Run all health checks',
            '--auto-fix                # Auto-fix safe issues',
            '--auto-fix-with-agent     # Auto-fix then launch agent for remaining',
            '--check subtasks          # Run specific check',
            '--json                    # Output as JSON'
          ]

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

          option :component, type: :string, aliases: %w[-c], desc: "Check specific component"
          option :check, type: :string, desc: "Run specific check"
          option :subtasks, type: :boolean, desc: "Shorthand for --check subtasks"
          option :auto_fix, type: :boolean, aliases: %w[-f], desc: "Auto-fix safe issues"
          option :auto_fix_with_agent, type: :boolean, desc: "Auto-fix then launch agent for remaining issues"
          option :verbose_info, type: :boolean, desc: "Show all output including info-level items"
          option :model, type: :string, desc: "Provider:model for agent session (default from config)"
          option :errors_only, type: :boolean, desc: "Show only errors, not warnings"
          option :no_color, type: :boolean, desc: "Disable colored output"
          option :json, type: :boolean, desc: "Output in JSON format"
          option :dry_run, type: :boolean, desc: "Preview fixes without applying them"

          def call(**options)
            args = options[:args] || []
            clean_options = options.reject { |k, _| k == :args }
            execute_doctor(args, clean_options)
          end

          private

          def execute_doctor(args, thor_options = {})
            @root_path = find_taskflow_root
            @option_parser = build_option_parser

            result = @option_parser.parse(args, thor_options: thor_options)
            return if result[:help_requested]

            parsed_options = result[:parsed]
            parsed_options[:format] ||= :terminal

            # --auto-fix-with-agent implies --auto-fix
            parsed_options[:fix] = true if parsed_options[:auto_fix] || parsed_options[:auto_fix_with_agent]

            # --verbose-info implies --verbose
            parsed_options[:verbose] = true if parsed_options[:verbose_info]

            unless @root_path
              puts "Error: No .ace-taskflow directory found"
              puts "Please run this command from within an ace-taskflow project"
              raise Ace::Core::CLI::Error.new("No .ace-taskflow directory found")
            end

            if parsed_options[:quiet]
              results = run_diagnosis(parsed_options)
              raise Ace::Core::CLI::Error.new("Health check failed") unless results[:valid]
              return
            end

            results = run_diagnosis(parsed_options)

            output = Molecules::DoctorReporter.format_results(
              results,
              format: parsed_options[:format],
              verbose: parsed_options[:verbose],
              verbose_info: parsed_options[:verbose_info],
              colors: !parsed_options[:no_color]
            )
            puts output

            if parsed_options[:fix] && results[:issues] && results[:issues].any?
              handle_auto_fix(results, parsed_options)
            end

            if parsed_options[:fix_with_agent]
              handle_agent_fix(parsed_options)
            end

            raise Ace::Core::CLI::Error.new("Health check failed") unless results[:valid]
          rescue StandardError => e
            raise Ace::Core::CLI::Error.new(e.message)
          end

          def build_option_parser
            Molecules::CommandOptionParser.new(
              option_sets: [:display, :release, :actions, :help],
              banner: "Usage: ace-taskflow doctor [options]"
            ) do |opts, parsed|
              opts.on("--component TYPE", "-c TYPE", "Check specific component") { |v| parsed[:component] = v }
              opts.on("--check TYPE", "Run specific check") { |v| parsed[:check] = v }
              opts.on("--subtasks", "Shorthand for --check subtasks") { parsed[:check] = "subtasks" }
              opts.on("--auto-fix", "-f", "Auto-fix safe issues") { parsed[:fix] = true }
              opts.on("--auto-fix-with-agent", "Auto-fix then launch agent for remaining issues") { parsed[:fix_with_agent] = true }
              opts.on("--model MODEL", "Provider:model for agent session (default from config)") { |v| parsed[:model] = v }
              opts.on("--quiet", "-q", "Quiet mode - just exit code") { parsed[:quiet] = true }
              opts.on("--verbose-info", "Show all output including info-level items") { parsed[:verbose_info] = true }
              opts.on("--errors-only", "Show only errors, not warnings") { parsed[:errors_only] = true }
              opts.on("--no-color", "Disable colored output") { parsed[:no_color] = true }
              opts.on("--json", "Output in JSON format") do
                parsed[:format] = :json
                parsed[:no_color] = true
              end
              opts.on("--summary", "Show summary format") { parsed[:format] = :summary }
            end
          end

          def run_diagnosis(options)
            doctor = Organisms::TaskflowDoctor.new(@root_path, options)
            results = doctor.run_diagnosis

            if options[:errors_only] && results[:issues]
              results[:issues] = results[:issues].select { |i| i[:type] == :error }
            end

            results
          end

          def handle_auto_fix(results, options)
            fixer = Molecules::DoctorFixer.new(dry_run: options[:dry_run])

            doctor = Organisms::TaskflowDoctor.new(@root_path, options)
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

            fix_results = fixer.fix_issues(fixable_issues)

            output = Molecules::DoctorReporter.format_fix_results(
              fix_results,
              colors: !options[:no_color]
            )
            puts output

            unless options[:dry_run]
              puts "\nRe-running health check after fixes..."
              new_results = run_diagnosis(options)

              output = Molecules::DoctorReporter.format_results(
                new_results,
                format: :summary,
                verbose: false,
                colors: !options[:no_color]
              )
              puts output
            end
          end

          def handle_agent_fix(options)
            require "ace/llm"
            require "ace/llm/query_interface"

            # Re-diagnose after auto-fix to count remaining issues
            results = run_diagnosis(options)
            remaining = results[:issues]&.reject { |i| i[:type] == :info }

            if remaining.nil? || remaining.empty?
              puts "\nNo remaining issues for agent to fix."
              return
            end

            # Format remaining issues as plain-text list for the agent
            issue_list = remaining.map { |i|
              prefix = i[:type] == :error ? "ERROR" : "WARNING"
              "- [#{prefix}] #{i[:message]}#{i[:location] ? " (#{i[:location]})" : ""}"
            }.join("\n")

            # Resolve provider:model
            provider_model = options[:model] || resolve_agent_model

            # Build prompt with embedded issue list
            prompt = build_agent_prompt(remaining.size, issue_list)

            puts "\nLaunching agent to fix #{remaining.size} remaining issues..."

            # Invoke via QueryInterface
            response = Ace::LLM::QueryInterface.query(
              provider_model,
              prompt,
              system: nil,
              cli_args: "dangerously-skip-permissions",
              timeout: 600,
              fallback: false
            )

            puts response[:text]
          end

          def resolve_agent_model
            Ace::Taskflow.configuration.doctor_agent_model
          end

          def build_agent_prompt(issue_count, issue_list)
            <<~PROMPT
              /onboard

              ---

              The following #{issue_count} issues could NOT be auto-fixed and need manual intervention:

              #{issue_list}

              ---

              Fix each issue listed above.

              IMPORTANT RULES:
              - SKIP all issues in archived releases (_archive/v.0.0.0 through _archive/v.0.8.0) — these are historical
              - Only fix issues in active releases (v.0.9.0+) and backlog
              - "Orphaned file" means a file doesn't match expected naming/location patterns for its directory
              - "Partial YAML recovery" means frontmatter has YAML syntax errors — fix the YAML
              - Do NOT delete content files — prefer moving/renaming to match conventions

              ---

              Run `ace-taskflow doctor --verbose` to verify all issues are fixed.
            PROMPT
          end

          def find_taskflow_root
            current = Dir.pwd
            while current != "/"
              taskflow_dir = File.join(current, ".ace-taskflow")
              return taskflow_dir if Dir.exist?(taskflow_dir)
              current = File.dirname(current)
            end
            nil
          end
        end
      end
    end
  end
end
