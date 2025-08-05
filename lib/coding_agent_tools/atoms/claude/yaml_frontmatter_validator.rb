# frozen_string_literal: true

require 'yaml'

module CodingAgentTools
  module Atoms
    module Claude
      # Validates YAML frontmatter in generated commands
      # This is a pure utility with no dependencies on other components
      class YamlFrontmatterValidator
        # Validate YAML frontmatter in content
        # @param content [String] File content with YAML frontmatter
        # @return [Boolean] True if valid YAML
        def self.valid?(content)
          return false if content.nil? || content.empty?
          
          # Extract YAML between --- markers
          yaml_match = content.match(/\A---\n(.*?)\n---/m)
          return false unless yaml_match

          begin
            # Attempt to parse the YAML
            YAML.safe_load(yaml_match[1])
            true
          rescue Psych::SyntaxError
            false
          end
        end

        # Parse YAML frontmatter from content
        # @param content [String] File content
        # @return [Hash, nil] Parsed YAML data or nil if invalid
        def self.parse(content)
          return nil if content.nil? || content.empty?
          
          # Extract YAML between --- markers
          yaml_match = content.match(/\A---\n(.*?)\n---/m)
          return nil unless yaml_match

          begin
            parsed = YAML.safe_load(yaml_match[1])
            # Ensure we return a hash (YAML could parse to other types)
            parsed.is_a?(Hash) ? parsed : nil
          rescue Psych::SyntaxError
            nil
          end
        end

        # Extract YAML frontmatter section
        # @param content [String] File content
        # @return [String, nil] YAML frontmatter content (without markers) or nil
        def self.extract_frontmatter(content)
          return nil if content.nil? || content.empty?
          
          yaml_match = content.match(/\A---\n(.*?)\n---/m)
          yaml_match ? yaml_match[1] : nil
        end

        # Check if content has frontmatter markers
        # @param content [String] File content
        # @return [Boolean] True if content has frontmatter markers
        def self.has_frontmatter?(content)
          return false if content.nil? || content.empty?
          
          content.match?(/\A---\n.*?\n---/m)
        end
      end
    end
  end
end