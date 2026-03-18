# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module CLI
        module Commands
          # ace-support-cli command for scanning repository for tokens
          #
          # Requires gitleaks to be installed (brew install gitleaks)
          #
          # Exit codes:
          # - 0: Clean (no tokens found)
          # - 1: Tokens detected
          # - 2: Error occurred
          class Scan < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base

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
                   desc: "Suppress non-essential output"
            option :debug, type: :boolean, default: false,
                   desc: "Show debug output"

            def call(**options)
              debug_log("Starting scan with options: #{format_pairs(options)}", options)

              exit_code = Ace::Git::Secrets::Commands::ScanCommand.execute(options)
              raise Ace::Support::Cli::Error.new("Tokens detected", exit_code: exit_code) if exit_code != 0
            rescue Ace::Support::Cli::Error
              raise
            rescue StandardError => e
              debug_log(e.full_message, options) if debug?(options)
              raise Ace::Support::Cli::Error.new(e.message, exit_code: 2)
            end
          end
        end
      end
    end
  end
end
