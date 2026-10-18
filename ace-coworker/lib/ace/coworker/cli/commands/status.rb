# frozen_string_literal: true

require "json"

module Ace
  module Coworker
    module CLI
      module Commands
        class Status < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Show readiness, identity, and assignment progress"

          option :config, desc: "Path to coworker config (default: .ace-local/coworker/config.yml)"
          option :assignment, desc: "Show status for a specific assignment ID (default: config assignment)"
          option :format, default: "table", desc: "Output format (table, json)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def initialize(orchestrator: nil)
            super()
            @orchestrator = orchestrator
          end

          def call(config: nil, assignment: nil, format: "table", **options)
            orchestrator = @orchestrator || Organisms::StatusOrchestrator.new
            result = orchestrator.call(config_path: config, assignment: assignment)
            return if options[:quiet]

            if format == "json"
              puts JSON.pretty_generate(to_h(result))
            else
              puts render_table(result)
            end
          rescue Interrupt
            nil
          rescue Ace::Coworker::Error, StandardError => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          def effective_assignment(result)
            result.assignment || result.config.assignment
          end

          def to_h(result)
            if result.is_a?(Organisms::StatusOrchestrator::NotReady)
              {"ready" => false, "message" => result.message}
            else
              cfg = result.config
              payload = {
                "ready" => true,
                "role" => cfg.role,
                "task" => cfg.task,
                "assignment" => effective_assignment(result),
                "overseer" => cfg.overseer,
                "on_failure" => cfg.on_failure
              }
              if result.snapshot
                payload["assignment_status"] = result.snapshot.to_h
              elsif result.probe_error
                payload["assignment_error"] = result.probe_error
              end
              payload
            end
          end

          def render_table(result)
            if result.is_a?(Organisms::StatusOrchestrator::NotReady)
              return result.message
            end

            cfg = result.config
            lines = ["Coworker status"]
            lines << "  role:        #{cfg.role}"
            lines << "  task:        #{cfg.task}"
            lines << "  assignment:  #{effective_assignment(result)}"
            lines << "  overseer:    #{cfg.overseer}"
            if result.snapshot
              snapshot = result.snapshot
              verdict = snapshot.completion_verdict == :complete ? "complete" : "incomplete"
              lines << "  state:       #{snapshot.state} (#{snapshot.progress}) — #{verdict}"
              unless verdict == "complete"
                reasons = snapshot.incomplete_reasons
                lines.concat(reasons.map { |r| "    remaining: #{r}" })
              end
            elsif result.probe_error
              lines << "  assignment:  #{result.probe_error}"
            end
            lines.join("\n")
          end
        end
      end
    end
  end
end
