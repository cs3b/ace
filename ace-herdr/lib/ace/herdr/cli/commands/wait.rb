# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Herdr
    module CLI
      module Commands
        class Wait < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            Wait for an agent to reach a state (noise-free monitoring)

            Prints nothing on success unless running without --quiet output.
          DESC

          example [
            "--pane p5",
            "--pane p5 --until done --timeout 120"
          ]

          option :pane, type: :string, desc: "Target pane id"
          option :until, type: :string, desc: "Comma-separated states: idle,working,blocked,done,unknown (default: idle,done,blocked)"
          option :timeout, type: :integer, desc: "Timeout in seconds (default: config timeouts.wait)"

          def initialize(executor: nil)
            @executor = executor
          end

          def call(**options)
            translate_errors do
              cli_error("--pane is required") if options[:pane].to_s.empty?
              until_states = (options[:until] || "idle,done,blocked")
                .split(",").map(&:strip).reject(&:empty?)
              timeout_seconds =
                options[:timeout] || (config.dig("timeouts", "wait") || 30)
              @executor.agent_wait(
                pane: options.fetch(:pane), until_states: until_states,
                timeout_ms: timeout_seconds * 1000
              )
              puts JSON.generate(pane: options.fetch(:pane), state: "ready") unless options[:quiet]
            end
          end
        end
      end
    end
  end
end
