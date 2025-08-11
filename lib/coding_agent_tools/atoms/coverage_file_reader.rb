# frozen_string_literal: true

require "json"

module CodingAgentTools
  module Atoms
    # Reads and validates SimpleCov .resultset.json files
    # Handles large files efficiently and provides detailed error information
    class CoverageFileReader
      class InvalidFileError < StandardError; end

      class MalformedJsonError < StandardError; end

      def initialize
        # No state needed - stateless atom
      end

      # Reads and parses a SimpleCov resultset file
      # @param file_path [String] Path to .resultset.json file
      # @return [Hash] Parsed JSON data
      # @raise [InvalidFileError] If file doesn't exist or isn't readable
      # @raise [MalformedJsonError] If JSON is invalid
      def read(file_path)
        validate_file_exists(file_path)
        parse_json_content(file_path)
      end

      # Validates file structure matches SimpleCov format
      # @param data [Hash] Parsed JSON data
      # @return [Boolean] true if valid
      # @raise [InvalidFileError] If structure is invalid
      def validate_structure(data)
        raise InvalidFileError, "Root must be a hash, got #{data.class}" unless data.is_a?(Hash)

        data.each do |framework_name, framework_data|
          validate_framework_data(framework_name, framework_data)
        end

        true
      end

      # Extracts test framework names from the data
      # @param data [Hash] Parsed JSON data
      # @return [Array<String>] Framework names
      def extract_frameworks(data)
        data.keys
      end

      # Extracts file paths from coverage data
      # @param data [Hash] Parsed JSON data
      # @return [Array<String>] File paths
      def extract_file_paths(data)
        file_paths = []

        data.each do |_framework_name, framework_data|
          next unless framework_data.is_a?(Hash) && framework_data["coverage"]

          file_paths.concat(framework_data["coverage"].keys)
        end

        file_paths.uniq
      end

      private

      def validate_file_exists(file_path)
        raise InvalidFileError, "File does not exist: #{file_path}" unless File.exist?(file_path)

        return if File.readable?(file_path)

        raise InvalidFileError, "File is not readable: #{file_path}"
      end

      def parse_json_content(file_path)
        content = File.read(file_path)
        JSON.parse(content)
      rescue JSON::ParserError => e
        raise MalformedJsonError, "Invalid JSON in #{file_path}: #{e.message}"
      rescue => e
        raise InvalidFileError, "Error reading #{file_path}: #{e.message}"
      end

      def validate_framework_data(framework_name, framework_data)
        raise InvalidFileError, "Framework '#{framework_name}' data must be a hash" unless framework_data.is_a?(Hash)

        unless framework_data.key?("coverage")
          raise InvalidFileError, "Framework '#{framework_name}' missing 'coverage' key"
        end

        unless framework_data["coverage"].is_a?(Hash)
          raise InvalidFileError, "Framework '#{framework_name}' coverage must be a hash"
        end

        validate_coverage_data(framework_name, framework_data["coverage"])
      end

      def validate_coverage_data(framework_name, coverage_data)
        coverage_data.each do |file_path, file_data|
          next unless file_data.is_a?(Hash)

          unless file_data.key?("lines")
            raise InvalidFileError, "File '#{file_path}' in '#{framework_name}' missing 'lines' key"
          end

          raise InvalidFileError, "File '#{file_path}' lines must be an array" unless file_data["lines"].is_a?(Array)
        end
      end
    end
  end
end
