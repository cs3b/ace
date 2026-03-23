# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module Commands
        # CLI command for pre-release security check
        class CheckReleaseCommand
          # Execute check-release command
          # @param options [Hash] Command options
          # @return [Integer] Exit code (0=passed, 1=failed, 2=error)
          def self.execute(options)
            new(options).execute
          end

          def initialize(options)
            @options = options
          end

          def execute
            # Ensure gitleaks is available
            Atoms::GitleaksRunner.ensure_available!

            puts "Performing pre-release security check..."
            puts

            gate = Organisms::ReleaseGate.new(
              repository_path: ".",
              strict: @options[:strict],
              gitleaks_config: Ace::Git::Secrets.gitleaks_config_path
            )

            result = gate.check

            # Output formatted result
            puts gate.format_result(result, format: @options[:format] || "table")

            result[:exit_code]
          rescue => e
            puts "Error: #{e.message}"
            puts e.backtrace.first(5).join("\n") if ENV["DEBUG"]
            2
          end
        end
      end
    end
  end
end
