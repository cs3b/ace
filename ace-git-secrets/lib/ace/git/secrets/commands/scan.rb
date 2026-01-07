# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module Commands
        # dry-cli command for scanning repository for tokens
        #
        # Requires gitleaks to be installed (brew install gitleaks)
        #
        # Exit codes:
        # - 0: Clean (no tokens found)
        # - 1: Tokens detected
        # - 2: Error occurred
        class Scan < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Scan Git history for authentication tokens"

          option :since, type: :string, desc: "Start scanning from commit or date"
          option :format, type: :string, aliases: ["f"], default: "table",
                 desc: "Stdout format when --verbose is used (table, json, yaml)"
          option :report_format, type: :string, aliases: ["r"], default: "json",
                 desc: "Format for saved report file (json, markdown)"
          option :confidence, type: :string, aliases: ["c"], default: "low",
                 desc: "Minimum confidence (high, medium, low)"
          option :verbose, type: :boolean, default: false,
                 desc: "Enable verbose output with full report to stdout"
          option :quiet, type: :boolean, aliases: ["q"], default: false,
                 desc: "Suppress non-essential output (for CI)"
          option :debug, type: :boolean, default: false,
                 desc: "Enable debug output"

          def call(**options)
            debug_log("Starting scan with options: #{format_pairs(options)}", options)

            # Delegate to existing ScanCommand logic and capture exit code
            exit_code = ScanCommand.execute(options)

            # Store exit code for CLI.start to retrieve
            ::Ace::Git::Secrets::CLI.exit_code = exit_code

            exit_code
          rescue StandardError => e
            debug_log(e.full_message, options) if debug?(options)
            failure_code = exit_failure(e.message)
            ::Ace::Git::Secrets::CLI.exit_code = failure_code
            failure_code
          end
        end
      end
    end
  end
end
