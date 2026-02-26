# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Shared implementation for simulation write-back helpers.
      # Included by IdeaSimulationWriteback and TaskSimulationWriteback.
      module SimulationWritebackMixin
        SECTION_HEADING = "## Simulation Review (Next-Phase)"

        ARTIFACT_HEADINGS = {
          "draft" => "## Simulated Draft",
          "plan" => "## Simulated Plan"
        }.freeze

        def apply(path:, run_id:, modes:, synthesis:)
          content = File.read(path)
          section = build_section(run_id: run_id, modes: modes, synthesis: synthesis)
          updated = upsert_section(content, section)
          updated = upsert_artifact_sections(updated, synthesis)
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

        # Build full preview including both review section and artifact sections.
        # This shows exactly what would be written to the source file.
        def build_full_preview(run_id:, modes:, synthesis:)
          review_section = build_section(run_id: run_id, modes: modes, synthesis: synthesis)
          artifacts = synthesis[:artifacts] || synthesis["artifacts"] || {}

          artifact_sections = ARTIFACT_HEADINGS.filter_map do |mode_name, heading|
            content = artifacts[mode_name] || artifacts[mode_name.to_sym]
            next if content.to_s.strip.empty?

            <<~SECTION
              <!-- sim-artifact:#{mode_name} -->
              #{heading}

              #{content.strip}
              <!-- /sim-artifact:#{mode_name} -->
            SECTION
          end

          [review_section, *artifact_sections].join("\n\n")
        end

        private

        def upsert_section(content, section)
          # Stop before: next ## or # heading, sim-artifact marker, or end of string.
          # The sim-artifact stop prevents consuming start markers of artifact sections.
          pattern = /(#{Regexp.escape(SECTION_HEADING)}\n.*?)(?=\n\#{1,2} |\n<!-- sim-artifact:|\z)/m
          if content.match?(pattern)
            content.sub(pattern, "#{section}\n")
          else
            "#{content.rstrip}\n\n#{section}\n"
          end
        end

        # Upsert per-stage artifact sections using HTML comment markers.
        # Markers make the boundaries safe regardless of heading content in the artifact.
        def upsert_artifact_sections(content, synthesis)
          artifacts = synthesis[:artifacts] || synthesis["artifacts"] || {}
          return content if artifacts.empty?

          result = content
          ARTIFACT_HEADINGS.each do |mode_name, heading|
            artifact_content = artifacts[mode_name] || artifacts[mode_name.to_sym]
            result = upsert_artifact_section(result, mode_name, heading, artifact_content.to_s.strip)
          end
          result
        end

        def upsert_artifact_section(content, mode_name, heading, artifact_content)
          start_marker = "<!-- sim-artifact:#{mode_name} -->"
          end_marker = "<!-- /sim-artifact:#{mode_name} -->"

          if artifact_content.empty?
            # Remove existing artifact section if artifact is now empty
            escaped_start = Regexp.escape(start_marker)
            escaped_end = Regexp.escape(end_marker)
            return content.gsub(/\n\n#{escaped_start}.*?#{escaped_end}/m, "")
          end

          new_block = "#{start_marker}\n#{heading}\n\n#{artifact_content}\n#{end_marker}"

          escaped_start = Regexp.escape(start_marker)
          escaped_end = Regexp.escape(end_marker)
          pattern = /#{escaped_start}.*?#{escaped_end}/m

          if content.match?(pattern)
            content.sub(pattern, new_block)
          else
            "#{content.rstrip}\n\n#{new_block}\n"
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
