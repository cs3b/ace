# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module Commands
        # dry-cli command for rewriting Git history to remove tokens
        #
        # Exit codes:
        # - 0: Success
        # - 1: Failure
        # - 2: Error occurred
        class Rewrite < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Remove detected tokens from Git history"

          option :dry_run, type: :boolean, aliases: ["n"], default: false,
                 desc: "Show what would be rewritten"
          option :backup, type: :boolean, default: true,
                 desc: "Create backup before rewrite"
          option :force, type: :boolean, default: false,
                 desc: "Skip confirmation prompt"
          option :scan_file, type: :string,
                 desc: "Use previous scan results file"
          option :debug, type: :boolean, default: false,
                 desc: "Enable debug output"

          def call(**options)
            debug_log("Starting rewrite-history with options: #{format_pairs(options)}", options)

            # Delegate to existing RewriteCommand logic and capture exit code
            exit_code = RewriteCommand.execute(options)
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
