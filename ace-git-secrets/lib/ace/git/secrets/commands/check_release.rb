# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module Commands
        # dry-cli command for pre-release security check
        #
        # Exit codes:
        # - 0: Passed (no tokens detected)
        # - 1: Failed (tokens detected)
        # - 2: Error occurred
        class CheckRelease < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Pre-release security validation check"

          option :strict, type: :boolean, default: false,
                 desc: "Fail on medium confidence matches"
          option :format, type: :string, aliases: ["f"], default: "table",
                 desc: "Output format (table, json)"
          option :debug, type: :boolean, default: false,
                 desc: "Enable debug output"

          def call(**options)
            debug_log("Starting check-release with options: #{format_pairs(options)}", options)

            # Delegate to existing CheckReleaseCommand logic and return exit code directly
            CheckReleaseCommand.execute(options)
          rescue StandardError => e
            debug_log(e.full_message, options) if debug?(options)
            exit_failure(e.message)
          end
        end
      end
    end
  end
end
