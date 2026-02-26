# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Validates checklist completion in key behavioral spec sections
      class TaskCompletionGate
        CHECKBOX_PATTERN = /^\s*[-*]\s+\[( |x|X)\]\s+/.freeze
        HEADING_PATTERN = /^(\#{1,6})\s+(.+?)\s*$/.freeze

        SECTION_SUCCESS_CRITERIA = "Success Criteria"
        SECTION_VALIDATION_QUESTIONS = "Validation Questions"

        def self.evaluate(content:, require_success_criteria: true, require_validation_questions: false)
          section_stats = collect_section_stats(content.to_s)
          violations = []
          warnings = []

          success_criteria = section_stats[SECTION_SUCCESS_CRITERIA]
          validation_questions = section_stats[SECTION_VALIDATION_QUESTIONS]

          if require_success_criteria && success_criteria[:unchecked].positive?
            violations << build_issue(SECTION_SUCCESS_CRITERIA, success_criteria)
          elsif success_criteria[:unchecked].positive?
            warnings << build_issue(SECTION_SUCCESS_CRITERIA, success_criteria)
          end

          if require_validation_questions && validation_questions[:unchecked].positive?
            violations << build_issue(SECTION_VALIDATION_QUESTIONS, validation_questions)
          elsif validation_questions[:unchecked].positive?
            warnings << build_issue(SECTION_VALIDATION_QUESTIONS, validation_questions)
          end

          {
            blocked: !violations.empty?,
            violations: violations,
            warnings: warnings,
            has_issues: !(violations.empty? && warnings.empty?)
          }
        end

        def self.collect_section_stats(content)
          stats = {
            SECTION_SUCCESS_CRITERIA => empty_stats,
            SECTION_VALIDATION_QUESTIONS => empty_stats
          }

          current_section = nil
          current_level = nil

          content.each_line do |line|
            heading = line.match(HEADING_PATTERN)
            if heading
              heading_level = heading[1].length
              heading_name = normalize_heading_name(heading[2])

              if stats.key?(heading_name)
                current_section = heading_name
                current_level = heading_level
                stats[current_section][:present] = true
              elsif current_section && heading_level <= current_level
                current_section = nil
                current_level = nil
              end

              next
            end

            next unless current_section

            checkbox = line.match(CHECKBOX_PATTERN)
            next unless checkbox

            stats[current_section][:total] += 1
            stats[current_section][:unchecked] += 1 if checkbox[1] == " "
          end

          stats
        end

        def self.normalize_heading_name(raw)
          raw.to_s.strip.gsub(/\s+/, " ")
        end

        def self.build_issue(section, stats)
          {
            section: section,
            unresolved_count: stats[:unchecked],
            total_count: stats[:total]
          }
        end

        def self.empty_stats
          { present: false, unchecked: 0, total: 0 }
        end
      end
    end
  end
end
