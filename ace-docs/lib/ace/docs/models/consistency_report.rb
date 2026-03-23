# frozen_string_literal: true

require "json"
require "time"

module Ace
  module Docs
    module Models
      # Model for storing and formatting consistency analysis results
      class ConsistencyReport
        attr_reader :terminology_conflicts, :duplicate_content,
          :version_inconsistencies, :consolidation_opportunities,
          :generated_at, :document_count, :raw_response

        def initialize(data = {})
          @terminology_conflicts = data[:terminology_conflicts] || []
          @duplicate_content = data[:duplicate_content] || []
          @version_inconsistencies = data[:version_inconsistencies] || []
          @consolidation_opportunities = data[:consolidation_opportunities] || []
          @generated_at = data[:generated_at] || Time.now
          @document_count = data[:document_count] || 0
          @raw_response = data[:raw_response]
        end

        # Parse LLM response into ConsistencyReport
        # @param response [String] JSON response from LLM
        # @param document_count [Integer] number of documents analyzed
        # @return [ConsistencyReport] parsed report
        def self.parse(response, document_count = 0)
          data = JSON.parse(response, symbolize_names: true)

          new(
            terminology_conflicts: data[:terminology_conflicts] || [],
            duplicate_content: data[:duplicate_content] || [],
            version_inconsistencies: data[:version_inconsistencies] || [],
            consolidation_opportunities: data[:consolidation_opportunities] || [],
            document_count: document_count,
            generated_at: Time.now,
            raw_response: response
          )
        rescue JSON::ParserError
          # If parsing fails, create a report with the raw response
          new(
            raw_response: response,
            document_count: document_count,
            generated_at: Time.now
          )
        end

        # Check if the report has any issues
        def has_issues?
          total_issues > 0
        end

        # Get total number of issues found
        def total_issues
          terminology_conflicts.size +
            duplicate_content.size +
            version_inconsistencies.size +
            consolidation_opportunities.size
        end

        # Check if parsing was successful
        def parsing_successful?
          !raw_response.nil? && total_issues >= 0
        end

        # Convert report to markdown format
        def to_markdown
          output = []

          output << "# Cross-Document Consistency Report"
          output << ""
          output << "Generated: #{generated_at.strftime("%Y-%m-%d %H:%M:%S")}"
          output << "Documents analyzed: #{document_count}"
          output << "Issues found: #{total_issues}"
          output << ""

          if !parsing_successful? && raw_response
            output << "## Warning: Could not parse LLM response"
            output << ""
            output << "Raw output:"
            output << "```"
            output << raw_response
            output << "```"
            return output.join("\n")
          end

          if terminology_conflicts.any?
            output << "## Terminology Conflicts (#{terminology_conflicts.size})"
            output << ""

            terminology_conflicts.each do |conflict|
              output << format_terminology_conflict(conflict)
              output << ""
            end
          end

          if duplicate_content.any?
            output << "## Duplicate Content (#{duplicate_content.size})"
            output << ""

            duplicate_content.each do |duplicate|
              output << format_duplicate_content(duplicate)
              output << ""
            end
          end

          if version_inconsistencies.any?
            output << "## Version Inconsistencies (#{version_inconsistencies.size})"
            output << ""

            version_inconsistencies.each do |version_issue|
              output << format_version_inconsistency(version_issue)
              output << ""
            end
          end

          if consolidation_opportunities.any?
            output << "## Consolidation Opportunities (#{consolidation_opportunities.size})"
            output << ""

            consolidation_opportunities.each do |opportunity|
              output << format_consolidation_opportunity(opportunity)
              output << ""
            end
          end

          if total_issues == 0
            output << "## No Issues Found"
            output << ""
            output << "✅ All documents appear to be consistent!"
          end

          output.join("\n")
        end

        # Convert report to JSON format
        def to_json(*args)
          {
            generated_at: generated_at.iso8601,
            document_count: document_count,
            total_issues: total_issues,
            terminology_conflicts: terminology_conflicts,
            duplicate_content: duplicate_content,
            version_inconsistencies: version_inconsistencies,
            consolidation_opportunities: consolidation_opportunities
          }.to_json(*args)
        end

        private

        # Format a terminology conflict for markdown output
        def format_terminology_conflict(conflict)
          lines = []

          terms = conflict[:terms] || conflict["terms"] || []
          lines << "### \"#{terms[0]}\" vs \"#{terms[1]}\""

          occurrences = conflict[:occurrences] || conflict["occurrences"] || {}

          terms.each do |term|
            term_occurrences = occurrences[term.to_sym] || occurrences[term.to_s] || []
            next if term_occurrences.empty?

            term_occurrences.each do |occurrence|
              file = occurrence[:file] || occurrence["file"]
              count = occurrence[:count] || occurrence["count"]
              examples = occurrence[:examples] || occurrence["examples"] || []

              lines << "- #{file}: uses \"#{term}\" (#{count} occurrences)"
              if examples.any?
                lines << "  Examples: #{examples.first(2).join("; ")}"
              end
            end
          end

          recommendation = conflict[:recommendation] || conflict["recommendation"]
          lines << "**Recommendation**: #{recommendation}" if recommendation

          lines.join("\n")
        end

        # Format duplicate content for markdown output
        def format_duplicate_content(duplicate)
          lines = []

          description = duplicate[:description] || duplicate["description"] || "Duplicate content"
          similarity = duplicate[:similarity_percentage] || duplicate["similarity_percentage"]

          lines << "### #{description}"
          lines << "Files with duplicate content (#{similarity}% similarity):" if similarity

          locations = duplicate[:locations] || duplicate["locations"] || []
          locations.each do |location|
            file = location[:file] || location["file"]
            line_range = location[:lines] || location["lines"]
            excerpt = location[:excerpt] || location["excerpt"]

            lines << "- #{file} (lines #{line_range})"
            lines << "  \"#{excerpt}\"" if excerpt
          end

          recommendation = duplicate[:recommendation] || duplicate["recommendation"]
          lines << "**Recommendation**: #{recommendation}" if recommendation

          lines.join("\n")
        end

        # Format version inconsistency for markdown output
        def format_version_inconsistency(version_issue)
          lines = []

          item = version_issue[:item] || version_issue["item"] || "Version"
          lines << "### #{item}"

          versions = version_issue[:versions_found] || version_issue["versions_found"] || []
          versions.each do |version_info|
            version = version_info[:version] || version_info["version"]
            file = version_info[:file] || version_info["file"]
            line = version_info[:line] || version_info["line"]

            lines << "- #{file}: \"#{version}\""
            lines << "  (line #{line})" if line
          end

          recommendation = version_issue[:recommendation] || version_issue["recommendation"]
          lines << "**Recommendation**: #{recommendation}" if recommendation

          lines.join("\n")
        end

        # Format consolidation opportunity for markdown output
        def format_consolidation_opportunity(opportunity)
          lines = []

          topic = opportunity[:topic] || opportunity["topic"] || "Related content"
          lines << "### #{topic}"

          lines << "Multiple documents explain similar content:"

          documents = opportunity[:documents] || opportunity["documents"] || []
          documents.each do |doc|
            file = doc[:file] || doc["file"]
            coverage = doc[:coverage] || doc["coverage"]

            lines << "- #{file}"
            lines << "  Coverage: #{coverage}" if coverage
          end

          recommendation = opportunity[:recommendation] || opportunity["recommendation"]
          lines << "**Recommendation**: #{recommendation}" if recommendation

          lines.join("\n")
        end
      end
    end
  end
end
