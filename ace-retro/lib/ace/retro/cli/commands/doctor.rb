# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../../organisms/retro_doctor"
require_relative "../../molecules/retro_doctor_fixer"
require_relative "../../molecules/retro_doctor_reporter"
require_relative "../../molecules/retro_config_loader"

module Ace
  module Retro
    module CLI
      module Commands
        # dry-cli Command class for ace-retro doctor
        #
        # Runs health checks on retros and optionally auto-fixes issues.
        class Doctor < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Run health checks on retros

            Validates frontmatter, file structure, and scope/status consistency
            across all retros in the repository. Supports auto-fixing safe issues.

          DESC

          example [
            '                          # Run all health checks',
            '--auto-fix                # Auto-fix safe issues',
            '--auto-fix --dry-run      # Preview fixes without applying',
            '--check frontmatter       # Run specific check (frontmatter|structure|scope)',
            '--json                    # Output as JSON',
            '--verbose                 # Show all warnings'
          ]

          option :quiet,    type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose,  type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :auto_fix, type: :boolean, aliases: %w[-f], desc: "Auto-fix safe issues"
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
            config = Molecules::RetroConfigLoader.load
            root_dir = Molecules::RetroConfigLoader.root_dir(config)

            unless Dir.exist?(root_dir)
              puts "Error: Retros directory not found: #{root_dir}"
              raise Ace::Core::CLI::Error.new("Retros directory not found")
            end

            format = options[:json] ? :json : :terminal
            fix = options[:auto_fix]
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

            if options[:errors_only] && results[:issues]
              results[:issues] = results[:issues].select { |i| i[:type] == :error }
            end

            output = Molecules::RetroDoctorReporter.format_results(
              results,
              format: format,
              verbose: options[:verbose],
              colors: colors
            )
            puts output

            if fix && results[:issues]&.any?
              handle_auto_fix(results, root_dir, doctor_opts, options, colors)
            end

            raise Ace::Core::CLI::Error.new("Health check failed") unless results[:valid]
          rescue Ace::Core::CLI::Error
            raise
          rescue StandardError => e
            raise Ace::Core::CLI::Error.new(e.message)
          end

          def run_diagnosis(root_dir, doctor_opts)
            doctor = Organisms::RetroDoctor.new(root_dir, doctor_opts)
            doctor.run_diagnosis
          end

          def handle_auto_fix(results, root_dir, doctor_opts, options, colors)
            doctor = Organisms::RetroDoctor.new(root_dir, doctor_opts)
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

            fixer = Molecules::RetroDoctorFixer.new(dry_run: options[:dry_run], root_dir: root_dir)
            fix_results = fixer.fix_issues(fixable_issues)

            output = Molecules::RetroDoctorReporter.format_fix_results(
              fix_results,
              colors: colors
            )
            puts output

            unless options[:dry_run]
              puts "\nRe-running health check after fixes..."
              new_results = run_diagnosis(root_dir, doctor_opts)

              output = Molecules::RetroDoctorReporter.format_results(
                new_results,
                format: :summary,
                verbose: false,
                colors: colors
              )
              puts output
            end
          end
        end
      end
    end
  end
end
