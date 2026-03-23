# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module CLI
        module Commands
          # ace-support-cli command for revoking tokens via provider APIs
          #
          # Exit codes:
          # - 0: Success (all tokens revoked)
          # - 1: Partial success or failure
          # - 2: Error occurred
          class Revoke < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base

            desc "Revoke detected tokens via provider APIs"

            option :service, type: :string, aliases: ["s"],
              desc: "Revoke for specific service"
            option :token, type: :string, aliases: ["t"],
              desc: "Revoke specific token"
            option :scan_file, type: :string,
              desc: "Use previous scan results file"
            option :debug, type: :boolean, default: false,
              desc: "Show debug output"

            def call(**options)
              debug_log("Starting revoke with options: #{format_pairs(options)}", options)

              exit_code = Ace::Git::Secrets::Commands::RevokeCommand.execute(options)
              raise Ace::Support::Cli::Error.new("Revocation failed", exit_code: exit_code) if exit_code != 0
            rescue Ace::Support::Cli::Error
              raise
            rescue => e
              debug_log(e.full_message, options) if debug?(options)
              raise Ace::Support::Cli::Error.new(e.message, exit_code: 2)
            end
          end
        end
      end
    end
  end
end
