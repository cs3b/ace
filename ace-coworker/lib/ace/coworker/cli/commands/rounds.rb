# frozen_string_literal: true

require "json"

module Ace
  module Coworker
    module CLI
      module Commands
        class Rounds < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Record a review round for an assignment and print the 3/2/10 verdict"

          example [
            "record --assignment asg01 --type full --status completed",
            "record --assignment asg01 --type full --status completed \\",
            "       --confirmed f-1:high,f-2:low --resolved f-3",
            "record --assignment asg01 --type delta --status aborted"
          ]

          argument :action, required: true, desc: "Subcommand (record)"

          option :assignment, required: true, desc: "Assignment ID"
          option :type, required: true, desc: "Round type (full, delta)"
          option :status, required: true, desc: "Round status (completed, aborted)"
          option :confirmed, type: :array, default: [], desc: "Confirmed findings as id:severity pairs (e.g. f-1:high)"
          option :resolved, type: :array, default: [], desc: "Finding ids resolved by this round"
          option :format, default: "table", desc: "Output format (table, json)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def initialize(store: nil)
            super()
            @store = store
          end

          def call(action:, assignment:, type:, status:, confirmed: [], resolved: [],
                   format: "table", **options)
            raise Ace::Support::Cli::Error, "unknown subcommand '#{action}' (expected: record)" unless action == "record"

            store = @store || begin
              project_root = Molecules::ProjectRoot.new.resolve
              Molecules::ReviewRoundStore.new(project_root: project_root)
            end
            verdict = store.record!(assignment, build_record(type, status, confirmed, resolved))

            return if options[:quiet]

            if format == "json"
              puts JSON.pretty_generate(json_payload(assignment, verdict))
            else
              puts render(assignment, verdict)
            end
          rescue Ace::Coworker::Error => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          def build_record(type, status, confirmed, resolved)
            {
              "type" => type,
              "status" => status,
              "confirmed" => Array(confirmed).map { |pair| parse_finding(pair) },
              "resolved" => Array(resolved).map(&:to_s)
            }
          end

          def parse_finding(pair)
            id, severity = pair.to_s.split(":", 2)
            {"id" => id.to_s, "severity" => severity.to_s}
          end

          def json_payload(assignment, verdict)
            {
              "assignment" => assignment,
              "verdict" => verdict[:verdict].to_s,
              "full_rounds" => verdict[:full_rounds],
              "completed_full_rounds" => verdict[:completed_full_rounds],
              "consecutive_clean" => verdict[:consecutive_clean],
              "unresolved_high_critical" => verdict[:unresolved_high_critical]
            }
          end

          def render(assignment, verdict)
            lines = ["Coworker rounds record"]
            lines << "  assignment:             #{assignment}"
            lines << "  verdict:                #{verdict[:verdict]}"
            lines << "  full rounds:            #{verdict[:full_rounds]}"
            lines << "  completed full rounds:  #{verdict[:completed_full_rounds]}"
            lines << "  consecutive clean:      #{verdict[:consecutive_clean]}"
            lines << "  unresolved High/Critical: #{verdict[:unresolved_high_critical].join(', ')}"
            lines.join("\n")
          end
        end
      end
    end
  end
end
