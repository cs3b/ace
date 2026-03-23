# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module Commands
        # CLI command for scanning repository for tokens
        # Requires gitleaks to be installed (brew install gitleaks)
        class ScanCommand
          # Execute scan command
          # @param options [Hash] Command options
          # @return [Integer] Exit code (0=clean, 1=tokens found, 2=error)
          def self.execute(options)
            new(options).execute
          end

          def initialize(options)
            @options = options
            @config = Ace::Git::Secrets.config
          end

          def execute
            # Check gitleaks availability early with clear error
            Atoms::GitleaksRunner.ensure_available!

            auditor = Organisms::SecurityAuditor.new(
              repository_path: ".",
              gitleaks_config: Ace::Git::Secrets.gitleaks_config_path,
              output_format: output_format,
              whitelist: load_whitelist,
              exclusions: load_exclusions
            )

            # Quiet mode suppresses verbose and uses minimal output
            quiet = @options[:quiet]
            verbose = !quiet && @options[:verbose]

            report = auditor.audit(
              since: @options[:since],
              min_confidence: @options[:confidence] || "low",
              verbose: verbose
            )

            # Save report to file (new default behavior)
            report_format = @options[:report_format]&.to_sym || :json
            output_directory = @config.dig("output", "directory")
            report_path = report.save_to_file(format: report_format, directory: output_directory, quiet: quiet)

            # Print output based on mode
            if quiet
              # In quiet mode, only print summary for CI
              puts report.clean? ? "clean" : "found:#{report.token_count}"
            elsif verbose
              # In verbose mode, print full table report
              puts auditor.format_report(report)
              puts
              # Show whitelisted count if any
              if auditor.whitelisted_count > 0
                puts "Whitelisted: #{auditor.whitelisted_count} token(s) excluded by whitelist rules"
                puts
              end
              puts auditor.next_steps(report)
              puts
              puts "Report saved: #{report_path}"
            else
              # Default: summary to stdout, full report to file
              puts report.to_summary(report_path: report_path)
              # Show whitelisted count if any
              if auditor.whitelisted_count > 0
                puts "Whitelisted: #{auditor.whitelisted_count} token(s) excluded by whitelist rules"
              end
              unless report.clean?
                puts
                puts auditor.next_steps(report)
              end
            end

            # Return appropriate exit code
            report.clean? ? 0 : 1
          rescue Atoms::GitleaksRunner::GitleaksNotFoundError => e
            puts "Error: #{e.message}"
            2
          rescue => e
            puts "Error: #{e.message}"
            puts e.backtrace.first(5).join("\n") if ENV["DEBUG"]
            2
          end

          private

          # Load whitelist from config
          def load_whitelist
            @config["whitelist"] || []
          end

          # Load exclusions from config
          # ADR-022: Config already contains defaults merged with user overrides
          def load_exclusions
            @config["exclusions"]
          end

          # Determine output format
          # CLI option takes precedence, then config, then default (table)
          def output_format
            @options[:format] ||
              @config.dig("output", "format") ||
              "table"
          end
        end
      end
    end
  end
end
