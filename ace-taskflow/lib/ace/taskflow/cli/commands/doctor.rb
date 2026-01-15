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
            '                   # Run all health checks',
            '--fix              # Auto-fix issues',
            '--check subtasks   # Run specific check',
            '--json             # Output as JSON'
          ]

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

          option :component, type: :string, aliases: %w[-c], desc: "Check specific component"
          option :check, type: :string, desc: "Run specific check"
          option :subtasks, type: :boolean, desc: "Shorthand for --check subtasks"
          option :fix, type: :boolean, aliases: %w[-f], desc: "Attempt to auto-fix issues"
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
            return exit_success if result[:help_requested]

            parsed_options = result[:parsed]
            parsed_options[:format] ||= :terminal

            unless @root_path
              puts "Error: No .ace-taskflow directory found"
              puts "Please run this command from within an ace-taskflow project"
              return exit_failure
            end

            if parsed_options[:quiet]
              results = run_diagnosis(parsed_options)
              return results[:valid] ? exit_success : exit_failure
            end

            results = run_diagnosis(parsed_options)

            output = Molecules::DoctorReporter.format_results(
              results,
              format: parsed_options[:format],
              verbose: parsed_options[:verbose],
              colors: !parsed_options[:no_color]
            )
            puts output

            if parsed_options[:fix] && results[:issues] && results[:issues].any?
              handle_auto_fix(results, parsed_options)
            end

            results[:valid] ? exit_success : exit_failure
          rescue StandardError => e
            puts "Error: #{e.message}"
            puts e.backtrace if options[:verbose]
            exit_failure
          end

          def build_option_parser
            Molecules::CommandOptionParser.new(
              option_sets: [:display, :release, :actions, :help],
              banner: "Usage: ace-taskflow doctor [options]"
            ) do |opts, parsed|
              opts.on("--component TYPE", "-c TYPE", "Check specific component") { |v| parsed[:component] = v }
              opts.on("--check TYPE", "Run specific check") { |v| parsed[:check] = v }
              opts.on("--subtasks", "Shorthand for --check subtasks") { parsed[:check] = "subtasks" }
              opts.on("--fix", "-f", "Attempt to auto-fix issues") { parsed[:fix] = true }
              opts.on("--quiet", "-q", "Quiet mode - just exit code") { parsed[:quiet] = true }
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
            fixable_issues = doctor.get_fixable_issues

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
