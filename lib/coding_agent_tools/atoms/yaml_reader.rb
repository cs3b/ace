# frozen_string_literal: true

require 'yaml'

module CodingAgentTools
  module Atoms
    # YamlReader - Atom for reading and parsing YAML files
    #
    # Responsibilities:
    # - Load YAML files from filesystem
    # - Parse YAML content into Ruby objects
    # - Handle file not found and parse errors gracefully
    # - Provide standardized error handling for YAML operations
    class YamlReader
      # Reads and parses a YAML file
      #
      # @param file_path [String] Path to the YAML file
      # @return [Hash] Parsed YAML content as Hash
      # @raise [CodingAgentTools::Error] If file doesn't exist or YAML is invalid
      def self.read_file(file_path)
        raise CodingAgentTools::Error, "YAML file not found: #{file_path}" unless File.exist?(file_path)

        YAML.safe_load_file(file_path, permitted_classes: [Date, Time, DateTime])
      rescue Psych::SyntaxError => e
        raise CodingAgentTools::Error, "Invalid YAML syntax in #{file_path}: #{e.message}"
      rescue => e
        raise CodingAgentTools::Error, "Failed to read YAML file #{file_path}: #{e.message}"
      end

      # Parses YAML content from a string
      #
      # @param yaml_content [String] YAML content as string
      # @return [Hash] Parsed YAML content as Hash
      # @raise [CodingAgentTools::Error] If YAML is invalid
      def self.parse_content(yaml_content)
        YAML.safe_load(yaml_content, permitted_classes: [Date, Time, DateTime])
      rescue Psych::SyntaxError => e
        raise CodingAgentTools::Error, "Invalid YAML syntax: #{e.message}"
      rescue => e
        raise CodingAgentTools::Error, "Failed to parse YAML content: #{e.message}"
      end
    end
  end
end
