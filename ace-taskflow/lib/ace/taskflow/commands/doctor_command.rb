# frozen_string_literal: true

require_relative "../organisms/taskflow_doctor"
require_relative "../molecules/doctor_fixer"
require_relative "../molecules/doctor_reporter"

module Ace
  module Taskflow
    module Commands
      # Handle doctor subcommand for health checks
      class DoctorCommand
        def initialize
          @root_path = find_taskflow_root
        end

        def execute(args)
          options = parse_options(args)

          # Handle help
          if options[:help]
            show_help
            return 0
          end

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

          # Run diagnosis
          results = run_diagnosis(options)

          # Format and display results
          output = Molecules::DoctorReporter.format_results(
            results,
            format: options[:format],
            verbose: options[:verbose],
            colors: !options[:no_color]
          )
          puts output

          # Handle auto-fix if requested
          if options[:fix] && results[:issues] && results[:issues].any?
            handle_auto_fix(results, options)
          end

          # Return appropriate exit code
          results[:valid] ? 0 : 1
        rescue StandardError => e
          puts "Error: #{e.message}"
          puts e.backtrace if options[:verbose]
          2
        end

        private

        def parse_options(args)
          options = {
            format: :terminal,
            verbose: false,
            fix: false,
            dry_run: false,
            quiet: false,
            no_color: false,
            errors_only: false
          }

          i = 0
          while i < args.length
            arg = args[i]

            case arg
            when "--help", "-h"
              options[:help] = true
            when "--component", "-c"
              i += 1
              options[:component] = args[i]
            when "--release", "-r"
              i += 1
              options[:release] = args[i]
            when "--check"
              i += 1
              options[:check] = args[i]
            when "--fix", "-f"
              options[:fix] = true
            when "--dry-run"
              options[:dry_run] = true
              options[:fix] = true
            when "--format"
              i += 1
              options[:format] = args[i].to_sym if args[i]
            when "--verbose", "-v"
              options[:verbose] = true
            when "--quiet", "-q"
              options[:quiet] = true
            when "--errors-only"
              options[:errors_only] = true
            when "--no-color"
              options[:no_color] = true
            when "--json"
              options[:format] = :json
              options[:no_color] = true
            when "--summary"
              options[:format] = :summary
            else
              puts "Unknown option: #{arg}"
            end

            i += 1
          end

          options
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

          # Get fixable issues
          doctor = Organisms::TaskflowDoctor.new(@root_path, options)
          fixable_issues = doctor.get_fixable_issues

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
              --check TYPE              Run specific check (frontmatter, structure, integrity, dependencies)
              -f, --fix                 Auto-fix safe issues
              --dry-run                 Preview fixes without applying them
              --format FORMAT           Output format (terminal, json, summary)
              -v, --verbose             Show detailed diagnostics
              -q, --quiet               Exit code only (0=healthy, 1=issues)
              --errors-only             Show only critical errors
              --no-color                Disable colored output
              --json                    Shorthand for --format json --no-color

            EXAMPLES:
              # Run full health check
              ace-taskflow doctor

              # Auto-fix common issues
              ace-taskflow doctor --fix

              # Preview what would be fixed
              ace-taskflow doctor --fix --dry-run

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
              - Done tasks not in done/ directory
              - Tasks in done/ directory with wrong status
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