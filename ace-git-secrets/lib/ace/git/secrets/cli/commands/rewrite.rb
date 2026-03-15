# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module CLI
        module Commands
          # ace-support-cli command for rewriting Git history to remove tokens
          #
          # Exit codes:
          # - 0: Success
          # - 1: Failure
          # - 2: Error occurred
          class Rewrite < Ace::Support::Cli::Command
            include Ace::Core::CLI::Base

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
                   desc: "Show debug output"

            def call(**options)
              debug_log("Starting rewrite-history with options: #{format_pairs(options)}", options)

              exit_code = Ace::Git::Secrets::Commands::RewriteCommand.execute(options)
              raise Ace::Core::CLI::Error.new("Rewrite failed", exit_code: exit_code) if exit_code != 0
            rescue Ace::Core::CLI::Error
              raise
            rescue StandardError => e
              debug_log(e.full_message, options) if debug?(options)
              raise Ace::Core::CLI::Error.new(e.message, exit_code: 2)
            end
          end
        end
      end
    end
  end
end
