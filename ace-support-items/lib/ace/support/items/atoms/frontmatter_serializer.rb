# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Atoms
        # Serializes frontmatter hashes to YAML block strings with `---` delimiters.
        # Preserves inline-array style (`tags: [ux, design]`) and quotes
        # YAML-ambiguous values.
        class FrontmatterSerializer
          YAML_AMBIGUOUS = /\A(true|false|yes|no|on|off|null|~|-?\d+(\.\d+)?([eE][+-]?\d+)?)\z/i

          # Serialize frontmatter hash to YAML block string
          # @param frontmatter [Hash] Frontmatter data
          # @return [String] YAML frontmatter block including `---` delimiters
          def self.serialize(frontmatter)
            lines = ["---"]
            frontmatter.each do |key, value|
              serialize_entry(lines, key, value, indent: 0)
            end
            lines << "---"
            lines.join("\n")
          end

          # Rebuild a full document from frontmatter and body
          # @param frontmatter [Hash] Frontmatter data
          # @param body [String] Document body content
          # @return [String] Full document with frontmatter block and body
          def self.rebuild(frontmatter, body)
            "#{serialize(frontmatter)}\n\n#{body}"
          end

          # Serialize a single key-value entry with indentation support.
          def self.serialize_entry(lines, key, value, indent:)
            prefix = "  " * indent
            case value
            when Hash
              lines << "#{prefix}#{key}:"
              value.each do |k, v|
                serialize_entry(lines, k, v, indent: indent + 1)
              end
            when Array
              lines << if value.empty?
                "#{prefix}#{key}: []"
              else
                "#{prefix}#{key}: [#{value.join(", ")}]"
              end
            when String
              lines << if needs_quoting?(value)
                "#{prefix}#{key}: \"#{escape_yaml_string(value)}\""
              else
                "#{prefix}#{key}: #{value}"
              end
            else
              lines << "#{prefix}#{key}: #{value}"
            end
          end

          private_class_method :serialize_entry

          # Check if a string value needs YAML quoting
          # @param value [String] Value to check
          # @return [Boolean]
          private_class_method def self.needs_quoting?(value)
            value.match?(YAML_AMBIGUOUS) ||
              value.match?(/[:#@*&!%{}|>'"`\\,?\[\]]/) ||
              value.start_with?(" ", "\t") || value.end_with?(" ", "\t") ||
              value.include?("\n") || value.empty?
          end

          # Escape a string for double-quoted YAML
          # @param value [String] Value to escape
          # @return [String] Escaped value
          private_class_method def self.escape_yaml_string(value)
            value.gsub("\\", "\\\\\\\\").gsub('"', '\\"')
          end
        end
      end
    end
  end
end
