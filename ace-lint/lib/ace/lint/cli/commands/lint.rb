# frozen_string_literal: true

require "ace/support/cli"
require "ace/core/cli/base"
require_relative "../../atoms/validator_registry"
require_relative "../../organisms/lint_orchestrator"
require_relative "../../organisms/result_reporter"
require_relative "../../organisms/report_generator"
require_relative "../../organisms/lint_doctor"

module Ace
  module Lint
    module CLI
      module Commands
        # ace-support-cli Command class for the lint command
        #
        # This command provides linting functionality for markdown, YAML, and
        # frontmatter files, with built-in doctor diagnostics via --doctor flag.
        class Lint < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base

          desc <<~DESC.strip
            Lint markdown, YAML, Ruby, and frontmatter files

            File Type Auto-Detection:
              File types are detected from extensions by default:
                .md, .markdown → markdown (frontmatter validation)
                .yml, .yaml    → yaml (syntax checking)
                .rb, .rake, .gemspec → ruby (StandardRB linting)
                *.*            → frontmatter (YAML frontmatter in any file)

            Configuration:
              Global config:  ~/.ace/lint/config.yml
              Project config: .ace/lint/config.yml
              Example:        ace-lint/.ace-defaults/lint/config.yml

            Output:
              Exit codes: 0 (success), 1 (errors found), 2 (fatal error)
              Errors printed to stderr in format: "file:line: message"
              Use --quiet to suppress detailed output
          DESC

          # Examples shown in help output
          example [
            "README.md                    # Auto-detect type from extension",
            "--fix README.md              # Auto-fix and format",
            "docs/**/*.md --format        # Format with kramdown",
            "**/*.rb --validators standardrb,rubocop  # Multiple validators",
            "--doctor                     # Diagnose lint configuration",
            "--doctor-verbose             # Diagnose with all details"
          ]

          # Define positional arguments for file paths
          # Using a splat argument to accept multiple files
          argument :files, required: false, type: :array, desc: "Files to lint"

          # Method options (maintaining parity with Thor implementation)
          option :fix, type: :boolean, aliases: %w[-f], desc: "Auto-fix/format files"
          option :format, type: :boolean, desc: "Format files with kramdown"
          option :type, type: :string, aliases: %w[-t], desc: "File type (markdown, yaml, ruby, frontmatter)"
          option :line_width, type: :integer, desc: "Line width for formatting (default: 120)"
          option :validators, type: :string, desc: "Comma-separated list of validators (e.g., standardrb,rubocop)"
          option :no_report, type: :boolean, desc: "Disable JSON report generation"

          # Standard options (inherited from Base but need explicit definition for ace-support-cli)
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          # Single-command options
          option :version, type: :boolean, desc: "Show version information"
          option :doctor, type: :boolean, desc: "Diagnose lint configuration and validator health"
          option :doctor_verbose, type: :boolean, desc: "Run doctor with verbose output (all diagnostics including info)"

          def call(**options)
            if options[:version]
              puts "ace-lint #{Ace::Lint::VERSION}"
              return
            end

            if options[:doctor] || options[:doctor_verbose]
              run_doctor(verbose: !!options[:doctor_verbose], quiet: !!options[:quiet])
              return
            end

            # Reset availability caches to ensure fresh tool detection per invocation
            # This handles cases where tools are installed/removed during long-lived sessions
            Ace::Lint::Atoms::ValidatorRegistry.reset_all_caches!

            # Extract files array from options (ace-support-cli passes it as :files key)
            files = options[:files] || []

            # Remove ace-support-cli specific keys (args is leftover arguments)
            clean_options = options.reject { |k, _| k == :files || k == :args }

            # Type-convert numeric options (ace-support-cli returns strings for integers in some cases)
            # This maintains parity with the Thor implementation
            clean_options[:line_width] = clean_options[:line_width].to_i if clean_options[:line_width]

            # Validate inputs
            if files.empty?
              raise Ace::Core::CLI::Error.new("No files specified\nUsage: ace-lint [FILES...] [OPTIONS]")
            end

            # Expand globs
            expanded_paths = expand_file_paths(files)

            if expanded_paths.empty?
              raise Ace::Core::CLI::Error.new("No files found matching the given patterns")
            end

            # Create orchestrator with ruby groups configuration
            ruby_groups = Ace::Lint.ruby_config&.dig("groups")
            orchestrator = Organisms::LintOrchestrator.new(ruby_groups: ruby_groups)

            # Prepare options
            lint_options = prepare_options(clean_options)

            # Lint files
            results = orchestrator.lint_files(expanded_paths, options: lint_options)

            # Generate report unless --no-report flag is set
            report_dir = nil
            report_files = nil
            unless clean_options[:no_report]
              project_root = find_project_root
              report_result = Organisms::ReportGenerator.generate(
                results,
                project_root: project_root,
                options: lint_options
              )
              if report_result[:success]
                report_dir = report_result[:dir]
                report_files = report_result[:files]
              end
            end

            # Report results
            verbose = !clean_options[:quiet]
            Organisms::ResultReporter.report(results, verbose: verbose, report_dir: report_dir, report_files: report_files)

            # Raise on lint failures
            if results.any?(&:failed?)
              failed_count = results.count(&:failed?)
              exit_code = Organisms::ResultReporter.exit_code(results)
              raise Ace::Core::CLI::Error.new("#{failed_count} file(s) had lint errors", exit_code: exit_code)
            end
          end

          private

          # Run doctor diagnostics
          def run_doctor(verbose: false, quiet: false)
            puts "Diagnoses:"
            puts "  - Validator availability (StandardRB, RuboCop)"
            puts "  - Configuration file locations and existence"
            puts "  - Pattern coverage for validator groups"
            puts ""
            puts "Status indicators:"
            puts "  [OK]   - Configuration is correct"
            puts "  [WARN] - Potential issue that may affect linting"
            puts "  [ERR]  - Configuration error that needs fixing"

            ruby_groups = Ace::Lint.ruby_config&.dig("groups")
            doctor = Organisms::LintDoctor.new(project_root: Dir.pwd, groups: ruby_groups)
            diagnostics = doctor.diagnose

            diagnostics = diagnostics.reject(&:info?) if quiet
            display_diagnostics(diagnostics, verbose: verbose)

            if doctor.errors?
              raise Ace::Core::CLI::Error.new("Configuration has errors", exit_code: 2)
            elsif doctor.warnings?
              raise Ace::Core::CLI::Error.new("Configuration has warnings", exit_code: 1)
            end
          end

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

          # Find the project root directory (git root or current directory)
          # @return [String] Project root path
          def find_project_root
            # Try to find git root
            git_root = `git rev-parse --show-toplevel 2>/dev/null`.chomp
            return git_root unless git_root.empty?

            # Fall back to current directory
            Dir.pwd
          end

          # Expand file paths, handling glob patterns
          # @param paths [Array<String>] File paths or glob patterns
          # @return [Array<String>] Expanded file paths
          def expand_file_paths(paths)
            expanded = []

            paths.each do |path|
              # Check if it's a glob pattern
              if path.include?("*")
                matched_files = Dir.glob(path)
                expanded.concat(matched_files)
              elsif File.exist?(path)
                expanded << path
              else
                puts "Warning: File not found: #{path}"
              end
            end

            expanded.uniq.sort
          end

          # Prepare options for the linter
          # @param options [Hash] Raw command options
          # @return [Hash] Prepared options for lint orchestrator
          def prepare_options(options)
            prepared = {}

            # Type option
            prepared[:type] = options[:type].to_sym if options[:type]

            # Fix/format options
            prepared[:fix] = options[:fix] if options[:fix]
            prepared[:format] = options[:format] if options[:format]

            # Validators option (comma-separated list)
            if options[:validators]
              prepared[:validators] = parse_validators(options[:validators])
            end

            # Kramdown options
            kramdown_opts = {}
            kramdown_opts[:line_width] = options[:line_width] if options[:line_width]
            prepared[:kramdown_options] = kramdown_opts unless kramdown_opts.empty?

            prepared
          end

          # Parse comma-separated validators string into array of symbols
          # @param validators_str [String] Comma-separated validator names
          # @return [Array<Symbol>] Validator names as symbols
          def parse_validators(validators_str)
            validators_str.split(",").map { |v| v.strip.downcase.to_sym }
          end
        end
      end
    end
  end
end
