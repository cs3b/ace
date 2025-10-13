# frozen_string_literal: true

require "yaml"

module Ace
  module Taskflow
    module Atoms
      # Pure function to safely parse YAML frontmatter with error recovery
      # Handles common issues like missing closing delimiters and malformed YAML
      class SafeYamlParser
        # Parse YAML frontmatter with recovery from common errors
        # @param content [String] The markdown content with optional frontmatter
        # @return [Hash] Result hash with :frontmatter, :content, :errors, and :warnings
        def self.parse_with_recovery(content)
          return empty_result if content.nil? || content.empty?

          # Check if content starts with YAML frontmatter
          unless content.start_with?("---\n")
            return {
              frontmatter: {},
              content: content,
              errors: [],
              warnings: [],
              recovered: false
            }
          end

          # Try standard parsing first
          standard_result = try_standard_parse(content)
          return standard_result if standard_result[:errors].empty?

          # Attempt recovery if standard parsing failed
          recovery_result = recover_frontmatter(content)

          # If recovery succeeded (has frontmatter), return it
          # Otherwise return the standard error result
          recovery_result[:frontmatter].empty? ? standard_result : recovery_result
        end

        # Attempt to fix common frontmatter issues
        # @param content [String] The markdown content
        # @return [String] Content with fixed frontmatter
        def self.fix_frontmatter(content)
          return content unless content.start_with?("---\n")

          # Find or infer the end of frontmatter
          end_index = content.index("\n---\n", 4)

          if end_index.nil?
            # Try to infer end of frontmatter
            inferred_end = infer_frontmatter_end(content)
            if inferred_end
              # Insert closing delimiter
              # inferred_end already accounts for trailing newlines, so just insert ---\n
              fixed_content = content[0...inferred_end] + "---\n" + content[inferred_end..-1]
              return fixed_content
            end
          end

          content
        end

        private

        def self.empty_result
          {
            frontmatter: {},
            content: "",
            errors: [],
            warnings: [],
            recovered: false
          }
        end

        def self.try_standard_parse(content)
          # Find the ending delimiter
          end_index = content.index("\n---\n", 4)

          unless end_index
            return {
              frontmatter: {},
              content: content[4..-1] || "",
              errors: ["Missing closing '---' delimiter for frontmatter"],
              warnings: [],
              recovered: false
            }
          end

          # Extract and parse the YAML content
          yaml_content = content[4...end_index]
          body_content = content[(end_index + 5)..-1] || ""

          begin
            frontmatter = YAML.safe_load(yaml_content, permitted_classes: [Date, Time, Symbol]) || {}
            {
              frontmatter: frontmatter,
              content: body_content,
              errors: [],
              warnings: [],
              recovered: false
            }
          rescue Psych::SyntaxError => e
            {
              frontmatter: {},
              content: body_content,
              errors: ["YAML syntax error: #{e.message}"],
              warnings: [],
              recovered: false
            }
          end
        end

        def self.recover_frontmatter(content)
          # Try to find where frontmatter should end
          inferred_end = infer_frontmatter_end(content)

          if inferred_end.nil?
            return {
              frontmatter: {},
              content: content[4..-1] || "",
              errors: ["Unable to recover frontmatter structure"],
              warnings: ["Could not determine frontmatter boundaries"],
              recovered: false
            }
          end

          # Extract what we think is the frontmatter
          yaml_content = content[4...inferred_end].strip
          body_content = content[inferred_end..-1] || ""

          # Try to parse the recovered YAML
          begin
            frontmatter = YAML.safe_load(yaml_content, permitted_classes: [Date, Time, Symbol]) || {}

            # Validate required fields for taskflow items
            warnings = []
            if frontmatter.is_a?(Hash)
              warnings << "Missing 'id' field" unless frontmatter["id"]
              warnings << "Missing 'status' field" unless frontmatter["status"]
            else
              frontmatter = {}
              warnings << "Frontmatter is not a valid hash"
            end

            {
              frontmatter: frontmatter,
              content: body_content,
              errors: [],
              warnings: ["Recovered from missing closing delimiter"] + warnings,
              recovered: true
            }
          rescue Psych::SyntaxError => e
            # Try partial recovery - parse line by line
            partial_frontmatter = recover_partial_yaml(yaml_content)

            {
              frontmatter: partial_frontmatter,
              content: body_content,
              errors: ["Partial YAML recovery: #{e.message}"],
              warnings: ["Some frontmatter fields may be missing"],
              recovered: true
            }
          end
        end

        def self.infer_frontmatter_end(content)
          lines = content.split("\n", -1) # -1 keeps trailing empty strings

          # Calculate position by tracking cumulative length
          position = 0

          # Look for common markers that indicate content start
          lines.each_with_index do |line, i|
            # Skip opening ---
            if i == 0
              position += line.length + 1 # Skip "---\n"
              next
            end

            # Check for markdown headers (content likely starts here)
            return position if line.match?(/^#+\s/)

            # Check for blank line followed by content
            if line.strip.empty? && i + 1 < lines.length
              next_line = lines[i + 1]
              if next_line.match?(/^#+\s/) || next_line.start_with?("*") || next_line.start_with?("-")
                # Return position before the blank line (blank line should not be part of YAML)
                return position
              end
            end

            # Check for obvious non-YAML content
            if line.include?("```") || line.start_with?(">") || line.match?(/^\d+\./)
              return position
            end

            # Move position forward
            position += line.length + 1 # +1 for newline
          end

          nil
        end

        def self.recover_partial_yaml(yaml_content)
          result = {}

          yaml_content.split("\n").each do |line|
            # Try to parse simple key: value pairs
            if line =~ /^(\w+):\s*(.*)$/
              key = $1
              value = $2.strip

              # Try to parse the value
              begin
                # Remove quotes if present
                value = value[1..-2] if value.start_with?('"') && value.end_with?('"')
                value = value[1..-2] if value.start_with?("'") && value.end_with?("'")

                # Try to parse as YAML value (handles arrays, etc.)
                if value.start_with?("[") && value.end_with?("]")
                  parsed_value = YAML.safe_load(value)
                  result[key] = parsed_value
                else
                  result[key] = value
                end
              rescue
                result[key] = value
              end
            end
          end

          result
        end

        # Check if content has valid frontmatter structure
        # @param content [String] The content to check
        # @return [Hash] Validation result with :valid and :issues
        def self.validate_frontmatter(content)
          result = parse_with_recovery(content)

          issues = []
          issues.concat(result[:errors].map { |e| { type: :error, message: e } })
          issues.concat(result[:warnings].map { |w| { type: :warning, message: w } })

          # Check for required fields
          fm = result[:frontmatter]
          if fm.is_a?(Hash)
            issues << { type: :error, message: "Missing required field: id" } unless fm["id"]
            issues << { type: :warning, message: "Missing recommended field: status" } unless fm["status"]
          end

          {
            valid: issues.none? { |i| i[:type] == :error },
            issues: issues,
            recovered: result[:recovered]
          }
        end
      end
    end
  end
end