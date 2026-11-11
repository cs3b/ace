# frozen_string_literal: true

require "ace/support/cli"
require_relative "support"

module Ace
  module Herdr
    module CLI
      module Commands
        # Native Herdr owns its configuration and persistent terminal lifecycle.
        # Replace this process so the caller retains the terminal and exit status.
        class Start < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc "Start or attach to Herdr using its native configuration"

          def initialize(launcher: nil, configuration: nil)
            @launcher = launcher || ->(environment, binary) { Kernel.exec(environment, binary) }
            @configuration = configuration
          end

          def call(**)
            configuration = @configuration || config
            binary = configuration.fetch("binary", "herdr")
            unless binary.is_a?(String) && !binary.empty? && !binary.include?("\0")
              cli_error("herdr binary must be a nonempty executable path")
            end
            environment = Molecules::HerdrExecutor.environment(configuration)
            Molecules::InstalledPiExtensions.arguments(env: ENV.to_h.merge(environment))
            @launcher.call(environment, binary)
          rescue SystemCallError, Ace::Herdr::ExecutorError => e
            cli_error("Cannot start Herdr: #{e.message}")
          end
        end
      end
    end
  end
end
