# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module CLI
        module Commands
          # ace-support-cli command for pre-release security check
          #
          # Exit codes:
          # - 0: Passed (no tokens detected)
          # - 1: Failed (tokens detected)
          # - 2: Error occurred
          class CheckRelease < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base

            desc "Pre-release security validation check"

            option :strict, type: :boolean, default: false,
              desc: "Fail on medium confidence matches"
            option :format, type: :string, aliases: ["f"], default: "table",
              desc: "Output format (table, json)"
            option :debug, type: :boolean, default: false,
              desc: "Show debug output"

            def call(**options)
              debug_log("Starting check-release with options: #{format_pairs(options)}", options)

              # Delegate to existing CheckReleaseCommand logic
              exit_code = Ace::Git::Secrets::Commands::CheckReleaseCommand.execute(options)
              raise Ace::Support::Cli::Error.new("Pre-release check failed", exit_code: exit_code) if exit_code != 0
            rescue => e
              debug_log(e.full_message, options) if debug?(options)
              raise Ace::Support::Cli::Error.new(e.message)
            end
          end
        end
      end
    end
  end
end
