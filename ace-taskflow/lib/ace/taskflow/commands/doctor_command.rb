# frozen_string_literal: true

require_relative "../organisms/taskflow_doctor"
require_relative "../molecules/doctor_fixer"
require_relative "../molecules/doctor_reporter"
require_relative "../molecules/command_option_parser"

module Ace
  module Taskflow
    module Commands
      # Handle doctor subcommand for health checks
      class DoctorCommand
        def initialize
          @root_path = find_taskflow_root
          @option_parser = build_option_parser
        end

        def execute(args, thor_options = {})
          # Parse options using CommandOptionParser, merging any pre-parsed options
          result = @option_parser.parse(args, thor_options: thor_options)
          return 0 if result[:help_requested]

          options = result[:parsed]
          # Set default format
          options[:format] ||= :terminal

          # Check for taskflow directory
          unless @root_path
            puts "Error: No .ace-taskflow directory found"
            puts "Please run this command from within an ace-taskflow project"
            return 2
          end

          # Handle quiet mode - just exit code
          if options[:quiet]
            results = run_diagnosis(options)
            return results[:valid] ? 0 : 1
          end

          # Imply --auto-fix when --auto-fix-with-agent is used
          options[:fix] = true if options[:fix_with_agent]

          # --verbose-info implies --verbose
          options[:verbose] = true if options[:verbose_info]

          # Run diagnosis
          results = run_diagnosis(options)

          # Format and display results
          output = Molecules::DoctorReporter.format_results(
            results,
            format: options[:format],
            verbose: options[:verbose],
            verbose_info: options[:verbose_info],
            colors: !options[:no_color]
          )
          puts output

          # Handle auto-fix if requested
          if options[:fix] && results[:issues] && results[:issues].any?
            handle_auto_fix(results, options)
          end

          # Handle agent-assisted fix for remaining issues
          if options[:fix_with_agent]
            handle_agent_fix(options)
          end

          # Return appropriate exit code
          results[:valid] ? 0 : 1
        rescue StandardError => e
          puts "Error: #{e.message}"
          puts e.backtrace if options[:verbose]
          2
        end

        private

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

          # Filter results if errors-only
          if options[:errors_only] && results[:issues]
            results[:issues] = results[:issues].select { |i| i[:type] == :error }
          end

          results
        end

        def handle_auto_fix(results, options)
          fixer = Molecules::DoctorFixer.new(dry_run: options[:dry_run])

          # Filter fixable issues from already-diagnosed results
          doctor = Organisms::TaskflowDoctor.new(@root_path, options)
          fixable_issues = results[:issues].select { |issue| doctor.auto_fixable?(issue) }

          if fixable_issues.empty?
            puts "\nNo auto-fixable issues found"
            return
          end

          # Confirm with user unless quiet mode
          unless options[:quiet] || options[:dry_run]
            puts "\nFound #{fixable_issues.size} auto-fixable issues"
            print "Apply fixes? (y/N): "
            response = $stdin.gets.chomp.downcase
            return unless response == "y" || response == "yes"
          end

          # Apply fixes
          fix_results = fixer.fix_issues(fixable_issues)

          # Report fix results
          output = Molecules::DoctorReporter.format_fix_results(
            fix_results,
            colors: !options[:no_color]
          )
          puts output

          # Re-run diagnosis after fixes (unless dry-run)
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

          # Invoke via QueryInterface (same pattern as E2E runner)
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
            /ace_onboard

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

        def show_help
          help_text = <<~HELP
            Usage: ace-taskflow doctor [OPTIONS]

            Run comprehensive health checks on the taskflow system

            OPTIONS:
              -h, --help                Show this help message
              -c, --component TYPE      Check specific component (tasks, ideas, releases, retros)
              -r, --release VERSION     Check specific release (e.g., v.0.9.0)
              --check TYPE              Run specific check (frontmatter, structure, integrity, dependencies, subtasks)
              --subtasks                Shorthand for --check subtasks
              -f, --auto-fix            Auto-fix safe issues
              --auto-fix-with-agent     Auto-fix then launch agent for remaining issues
              --model MODEL             Provider:model for agent session (default from config)
              --dry-run                 Preview fixes without applying them
              --format FORMAT           Output format (terminal, json, summary)
              -v, --verbose             Show detailed diagnostics (all warnings)
              --verbose-info            Show all output including info-level items
              -q, --quiet               Exit code only (0=healthy, 1=issues)
              --errors-only             Show only critical errors
              --no-color                Disable colored output
              --json                    Shorthand for --format json --no-color

            EXAMPLES:
              # Run full health check
              ace-taskflow doctor

              # Auto-fix common issues
              ace-taskflow doctor --auto-fix

              # Preview what would be fixed
              ace-taskflow doctor --auto-fix --dry-run

              # Auto-fix then launch agent for remaining issues
              ace-taskflow doctor --auto-fix-with-agent

              # Use specific model for agent
              ace-taskflow doctor --auto-fix-with-agent --model claude:opus

              # Check specific component
              ace-taskflow doctor --component tasks

              # Check specific release
              ace-taskflow doctor --release v.0.9.0

              # Get JSON output for CI/CD
              ace-taskflow doctor --json

              # Quick health summary
              ace-taskflow doctor --format summary

              # Check only for errors
              ace-taskflow doctor --errors-only

              # Validate dependencies
              ace-taskflow doctor --check dependencies

            EXIT CODES:
              0 - System healthy (no errors)
              1 - Issues detected
              2 - Doctor command failed

            AUTO-FIXABLE ISSUES:
              - Missing closing '---' delimiter in frontmatter
              - Done tasks not in configured archive directory
              - Tasks in archive directory with wrong status
              - Missing recommended fields with defaults
              - Simple formatting issues

            MANUAL FIX REQUIRED:
              - YAML syntax errors
              - Circular dependencies
              - Duplicate IDs
              - Invalid file structures
              - Complex data inconsistencies

          HELP
          puts help_text
        end
      end
    end
  end
end