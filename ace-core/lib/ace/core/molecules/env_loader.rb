# frozen_string_literal: true

require_relative "../atoms/env_parser"
require_relative "../atoms/path_expander"
require_relative "../errors"

module Ace
  module Core
    module Molecules
      # .env file loading and environment variable management
      class EnvLoader
        # Load .env file and return parsed variables
        # @param filepath [String] Path to .env file
        # @return [Hash] Parsed environment variables
        # @raise [EnvParseError] if parsing fails
        def self.load_file(filepath)
          filepath = Atoms::PathExpander.expand(filepath)

          unless File.exist?(filepath)
            return {}
          end

          content = File.read(filepath)
          Atoms::EnvParser.parse(content)
        rescue IOError, SystemCallError => e
          raise EnvParseError, "Failed to read .env file #{filepath}: #{e.message}"
        end

        # Load .env file and set environment variables
        # @param filepath [String] Path to .env file
        # @param overwrite [Boolean] Whether to overwrite existing vars
        # @return [Hash] Variables that were set
        def self.load_and_set(filepath, overwrite: true)
          vars = load_file(filepath)
          set_environment(vars, overwrite: overwrite)
        end

        # Set environment variables from hash
        # @param vars [Hash] Variables to set
        # @param overwrite [Boolean] Whether to overwrite existing
        # @return [Hash] Variables that were actually set
        def self.set_environment(vars, overwrite: true)
          set_vars = {}

          vars.each do |key, value|
            next unless Atoms::EnvParser.valid_key?(key)
            next if !overwrite && ENV.key?(key)

            ENV[key] = value.to_s
            set_vars[key] = value
          end

          set_vars
        end

        # Save environment variables to .env file
        # @param vars [Hash] Variables to save
        # @param filepath [String] Path to .env file
        def self.save_file(vars, filepath)
          content = Atoms::EnvParser.format(vars)

          # Create directory if it doesn't exist
          dir = File.dirname(filepath)
          FileUtils.mkdir_p(dir) unless File.directory?(dir)

          File.write(filepath, content)
        rescue IOError, SystemCallError => e
          raise EnvParseError, "Failed to save .env file #{filepath}: #{e.message}"
        end

        # Load multiple .env files in order
        # @param filepaths [Array<String>] Paths to .env files
        # @param overwrite [Boolean] Whether to overwrite existing
        # @return [Hash] All variables that were set
        def self.load_multiple(*filepaths, overwrite: true)
          all_vars = {}

          filepaths.flatten.each do |filepath|
            vars = load_file(filepath)
            all_vars.merge!(vars) if vars && !vars.empty?
          end

          set_environment(all_vars, overwrite: overwrite)
        end

        # Find and load .env files in standard locations
        # @param root [String] Project root directory
        # @return [Hash] Variables that were loaded
        def self.auto_load(root = Dir.pwd)
          root = Atoms::PathExpander.expand(root)

          # Standard .env file locations in priority order
          env_files = [
            File.join(root, ".env.local"),
            File.join(root, ".env")
          ]

          # Load files that exist
          existing = env_files.select { |f| File.exist?(f) }
          load_multiple(*existing, overwrite: false) unless existing.empty?
        end
      end
    end
  end
end