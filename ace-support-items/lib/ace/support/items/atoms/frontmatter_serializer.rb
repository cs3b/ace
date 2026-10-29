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
          private_class_method def self.serialize_entry(lines, key, value, indent:)
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
                "#{prefix}#{key}: [#{value.map { |element| flow_element(element, key) }.join(", ")}]"
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

          # One element inside a flow sequence: strings follow the same
          # quoting rules as flat values (a plain scalar containing `: ` would
          # parse back as a hash, silently corrupting the value across
          # read-modify-write cycles). Numbers, booleans and nil serialize to
          # their YAML literals; compound values have no safe flow form and
          # fail loudly instead of emitting YAML that parses back as a
          # different structure (the 8xsdfo ask-flow corruption).
          def self.flow_element(element, key)
            case element
            when String
              needs_quoting?(element) ? "\"#{escape_yaml_string(element)}\"" : element
            when Integer, Float, true, false
              element.to_s
            when nil
              "null"
            else
              raise ArgumentError,
                "frontmatter array '#{key}' cannot safely carry a #{element.class} element; use scalar strings"
            end
          end
          private_class_method :flow_element

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
