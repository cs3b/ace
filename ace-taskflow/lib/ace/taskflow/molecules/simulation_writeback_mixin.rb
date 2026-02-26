# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Shared implementation for simulation write-back helpers.
      # Included by IdeaSimulationWriteback and TaskSimulationWriteback.
      module SimulationWritebackMixin
        SECTION_HEADING = "## Simulation Review (Next-Phase)"

        def apply(path:, run_id:, modes:, synthesis:)
          content = File.read(path)
          section = build_section(run_id: run_id, modes: modes, synthesis: synthesis)
          updated = upsert_section(content, section)
          File.write(path, updated)
          { path: path, section_heading: SECTION_HEADING }
        end

        def build_section(run_id:, modes:, synthesis:)
          questions = Array(synthesis[:questions] || synthesis["questions"])
          refinements = Array(synthesis[:refinements] || synthesis["refinements"])
          unresolved_gaps = Array(synthesis[:unresolved_gaps] || synthesis["unresolved_gaps"])

          parts = [
            SECTION_HEADING,
            "",
            "- Last run: `#{run_id}`",
            "- Modes: `#{Array(modes).join(',')}`",
            "",
            "### Questions",
            format_list(questions),
            "",
            "### Refinements",
            format_list(refinements)
          ]

          unless unresolved_gaps.empty?
            parts << ""
            parts << "### Unresolved Gaps"
            parts << format_list(unresolved_gaps)
          end

          parts.join("\n")
        end

        private

        def upsert_section(content, section)
          pattern = /(#{Regexp.escape(SECTION_HEADING)}\n.*?)(?=\n\#{1,2} |\z)/m
          if content.match?(pattern)
            content.sub(pattern, "#{section}\n")
          else
            "#{content.rstrip}\n\n#{section}\n"
          end
        end

        def format_list(items)
          return "- None" if items.empty?

          items.map { |item| "- #{item}" }.join("\n")
        end
      end
    end
  end
end
