# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Herdr
    module CLI
      module Commands
        class Deliver < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            Push an answer to an agent pane (ace-hitl delivery contract)

            Delivers are idempotent per event id and never lose the answer:
            a write-ahead record survives crashes, missing agents are
            bootstrapped, and transient failures retry with fixed backoff.
          DESC

          example [
            "--session ws-1 --pane p5 --event-id evt-1 --answer-file answer.md",
            "echo 'the answer' | ace-herdr deliver --pane p5",
            "--session ws-1 --pane p5 --kind codex --label 8wm.t.vs0 (bootstraps if missing)"
          ]

          option :session, type: :string, desc: "Ref session (default: HERDR_SESSION)"
          option :pane, type: :string, desc: "Ref pane (default: HERDR_PANE)"
          option :event_id, type: :string, desc: "Idempotency key (derived from ref and content when omitted)"
          option :kind, type: :string, desc: "Agent kind used when bootstrapping (default: config default_agent_kind)"
          option :label, type: :string, desc: "Agent name used when bootstrapping (default: event id)"
          option :answer_file, type: :string, desc: "Answer file (default: stdin)"
          option :resume, type: :string, desc: "Event id to re-deliver from the stored record (crash recovery)"

          def initialize(executor: nil)
            @executor = executor
          end

          def call(**options)
            translate_errors do
              deliverer = Organisms::Deliverer.from_config(
                executor: executor, deliveries_dir: deliveries_dir, config: config
              )
              if options[:resume]
                result = deliverer.resume(options[:resume], kind: options[:kind], label: options[:label])
                puts JSON.generate(ref: result.ref.to_h, state: result.state.to_s, resumed: true)
                cli_error("delivery did not complete (state: #{result.state})") unless result.state == :delivered
                return
              end

              ref = resolve_ref(options[:session], options[:pane])
              answer = read_content(options[:answer_file], what: "answer")
              result = deliverer.deliver(
                ref, answer,
                event_id: options[:event_id], kind: options[:kind], label: options[:label]
              )
              puts JSON.generate(ref: result.ref.to_h, state: result.state.to_s)
              cli_error("delivery did not complete (state: #{result.state})") unless result.state == :delivered
            end
          end
        end
      end
    end
  end
end
