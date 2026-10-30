# frozen_string_literal: true

require "json"

module Ace
  module Hitl
    module CLI
      module Commands
        # `ace-hitl history` (task 8xs.t.pu0.c): the citable decision
        # history for the NEXT Second Captain suggestion — answered,
        # NON-SECRET question cases of THIS project scope, each row with
        # its checkable references (case id, suggestion, decision,
        # lesson). Secret/OTP cases never reach the model; no wider
        # lab-wide sharing. No embedding store or decision index: HITL
        # stays the single source.
        class History < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "List the citable decision history (answered, non-secret cases of this scope)"

          option :scope, type: :string, default: "current", desc: "current or all linked worktrees"
          option :limit, type: :integer, default: 50, desc: "Maximum rows"
          option :format, default: "json", desc: "Output format (json, table)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(scope: "current", limit: 50, format: "json", quiet: false, **)
            rows = Ace::Hitl::Organisms::HitlManager.new
              .decision_history(scope: scope, limit: limit)
            return if quiet

            if format == "table"
              puts render_table(rows)
            else
              puts JSON.pretty_generate({"history" => rows, "count" => rows.size})
            end
          rescue ArgumentError => e
            raise Ace::Support::Cli::Error.new(e.message)
          end

          private

          # One row per decided case: the case id, the decision (truncated
          # to one line for the terminal) and the citable lesson relation.
          def render_table(rows)
            return "no decided cases in this scope" if rows.empty?

            lines = ["CASE               DECISION                                     LESSON"]
            rows.each do |row|
              decision = row["decision"].to_s.gsub(/\s+/, " ")
              decision = decision.length > 44 ? "#{decision[0, 43]}…" : decision
              lesson = row["lesson_relation"].to_s.empty? ? "-" : row["lesson_relation"].to_s
              lines << format("%-18s %-44s %s", row["id"], decision, lesson)
            end
            lines.join("\n")
          end
        end
      end
    end
  end
end
