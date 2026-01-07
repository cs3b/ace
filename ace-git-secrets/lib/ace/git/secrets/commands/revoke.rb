# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module Commands
        # dry-cli command for revoking tokens via provider APIs
        #
        # Exit codes:
        # - 0: Success (all tokens revoked)
        # - 1: Partial success or failure
        # - 2: Error occurred
        class Revoke < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Revoke detected tokens via provider APIs"

          option :service, type: :string, aliases: ["s"],
                 desc: "Revoke for specific service"
          option :token, type: :string, aliases: ["t"],
                 desc: "Revoke specific token"
          option :scan_file, type: :string,
                 desc: "Use previous scan results file"
          option :debug, type: :boolean, default: false,
                 desc: "Enable debug output"

          def call(**options)
            debug_log("Starting revoke with options: #{format_pairs(options)}", options)

            # Delegate to existing RevokeCommand logic and capture exit code
            exit_code = RevokeCommand.execute(options)
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
