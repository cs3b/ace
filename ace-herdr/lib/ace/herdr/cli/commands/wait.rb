# frozen_string_literal: true

require "json"
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
            Wait for an agent state or matching pane output

            --for agent (default) waits for an agent state without scraping
            pane output. --for output waits until the pane content contains
            the literal --pattern; existing content is checked immediately,
            then polled.
          DESC

          example [
            "--pane p5",
            "--pane p5 --until done --timeout 120",
            "--pane p5 --for output --pattern 'build succeeded'",
            "--pane p5 --for output --pattern done --timeout 30"
          ]

          option :pane, type: :string, desc: "Target pane id"
          option :for, type: :string, desc: "What to wait for: agent (default) or output"
          option :until, type: :string, desc: "Agent states, comma-separated: idle,working,blocked,done,unknown (default: idle,done,blocked)"
          option :pattern, type: :string, desc: "Literal output pattern to wait for (with --for output)"
          option :timeout, type: :integer, desc: "Timeout in seconds (default: config timeouts.wait)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(executor: nil)
            @executor = executor
          end

          def call(**options)
            translate_errors do
              cli_error("--pane is required") if options[:pane].to_s.empty?
              mode = options[:for] || "agent"
              unless %w[agent output].include?(mode)
                cli_error("--for must be agent or output")
              end
              timeout_seconds =
                options[:timeout] || (config.dig("timeouts", "wait") || 30)

              if mode == "output"
                wait_for_output(options, timeout_seconds)
              else
                wait_for_agent(options, timeout_seconds)
              end
            end
          end

          private

          def wait_for_agent(options, timeout_seconds)
            cli_error("--pattern requires --for output") if options[:pattern]
            until_states = (options[:until] || "idle,done,blocked")
              .split(",").map(&:strip).reject(&:empty?)
            executor.agent_wait(
              pane: options.fetch(:pane), until_states: until_states,
              timeout_ms: timeout_seconds * 1000
            )
            puts JSON.generate(pane: options.fetch(:pane), state: "ready") unless options[:quiet]
          end

          def wait_for_output(options, timeout_seconds)
            cli_error("--for output requires --pattern") if options[:pattern].to_s.empty?
            cli_error("--until requires --for agent") if options[:until]
            control = Organisms::ControlSurface.new(executor: executor)
            control.wait_output(
              pane: options.fetch(:pane), pattern: options.fetch(:pattern),
              timeout_ms: timeout_seconds * 1000
            )
            puts JSON.generate(pane: options.fetch(:pane), matched: true) unless options[:quiet]
          end
        end
      end
    end
  end
end
