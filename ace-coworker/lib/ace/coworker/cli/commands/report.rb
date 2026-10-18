# frozen_string_literal: true

require "json"

module Ace
  module Coworker
    module CLI
      module Commands
        class Report < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Record the assignment outcome and report it through ace-hitl"

          option :config, desc: "Path to coworker config (default: .ace-local/coworker/config.yml)"
          option :assignment, desc: "Assignment ID (default: config assignment)"
          option :result, desc: "Force result (success, error); default: derived from the ace-assign verdict"
          option :message, desc: "Explicit failure cause (required for error without step evidence)"
          option :step, desc: "Step ref to report (default: failed step / last step)"
          option :"no-send", type: :boolean, desc: "Create the HITL event without delivering it"
          option :"dry-run", type: :boolean, desc: "Show the derived outcome; nothing is written or sent"
          option :format, default: "table", desc: "Output format (table, json)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(**options)
            orchestrator = Organisms::ReportOrchestrator.new
            result = orchestrator.call(
              config_path: options[:config],
              assignment: options[:assignment],
              result: options[:result],
              message: options[:message],
              step: options[:step],
              no_send: options[:"no-send"] == true,
              dry_run: options[:"dry-run"] == true
            )

            # Exit semantics first: quiet suppresses output, never the
            # non-zero exit an error outcome or delivery failure must keep.
            if result.exit_code != 0
              raise Ace::Support::Cli::Error, result.message
            end

            return if options[:quiet]

            if options[:format] == "json"
              puts JSON.pretty_generate(to_h(result))
            else
              puts render(result)
            end
          rescue Ace::Coworker::Error => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          def to_h(result)
            {
              "result" => result.outcome.result,
              "record" => result.record_path,
              "event_id" => result.event_id,
              "delivery" => result.delivery,
              "message" => result.message
            }
          end

          def render(result)
            lines = ["Coworker report"]
            lines << "  outcome:    #{result.outcome.result}"
            lines << "  record:     #{result.record_path}" if result.record_path
            lines << "  event:      #{result.event_id}" if result.event_id
            lines << "  delivery:   #{result.delivery}" if result.delivery
            lines << "  #{result.message}" if result.message
            lines.join("\n")
          end
        end
      end
    end
  end
end
