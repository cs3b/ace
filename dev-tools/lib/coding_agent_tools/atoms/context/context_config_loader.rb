# frozen_string_literal: true

require "yaml"
require "pathname"
require_relative "../project_root_detector"

module CodingAgentTools
  module Atoms
    module Context
      # ContextConfigLoader - Atom for loading context preset configurations
      #
      # Responsibilities:
      # - Load .coding-agent/context.yml configuration
      # - Validate configuration schema
      # - Merge with sensible defaults
      # - Handle missing configuration gracefully
      class ContextConfigLoader
        DEFAULT_CONFIG = {
          "presets" => {
            "project" => {
              "description" => "Main project context",
              "template" => "docs/context/project.md",
              "output" => "docs/context/cached/project.md",
              "chunk_limit" => 150_000
            }
          },
          "settings" => {
            "default_chunk_limit" => 150_000,
            "cache_directory" => "docs/context/cached",
            "fallback_directory" => "docs/context",
            "auto_create_directories" => true
          },
          "security" => {
            "allowed_template_paths" => [
              "docs/**",
              "dev-handbook/**",
              "dev-taskflow/**",
              ".coding-agent/**"
            ],
            "allowed_output_paths" => [
              "docs/**",
              ".coding-agent/**"
            ],
            "forbidden_patterns" => [
              ".git/**",
              "**/.git/**",
              "node_modules/**",
              "**/node_modules/**",
              ".env*",
              "**/.env*",
              "*.key",
              "**/*.key",
              "*.pem",
              "**/*.pem"
            ]
          }
        }.freeze

        def initialize(project_root = nil, config_path = nil)
          @project_root = project_root || detect_project_root
          @config_path = config_path || default_config_path
        end

        # Load configuration from file or use defaults
        #
        # @return [Hash] Merged configuration
        def load
          return DEFAULT_CONFIG unless config_exists?

          config = YAML.load_file(@config_path)
          validate_user_config!(config)
          merge_with_defaults(config)
        rescue Psych::SyntaxError => e
          raise Error, "Invalid YAML in context configuration: #{e.message}"
        rescue => e
          raise Error, "Failed to load context configuration: #{e.message}"
        end

        # Check if configuration file exists
        #
        # @return [Boolean] true if config file exists
        def config_exists?
          File.exist?(@config_path)
        end

        # Get default configuration file path
        #
        # @return [String] Path to configuration file
        def default_config_path
          File.join(@project_root, ".coding-agent", "context.yml")
        end

        # Get project root directory
        #
        # @return [String] Project root path
        attr_reader :project_root

        private

        # Detect project root using existing atom
        #
        # @return [String] Project root path
        def detect_project_root
          CodingAgentTools::Atoms::ProjectRootDetector.find_project_root(Dir.pwd)
        end

        # Validate user configuration structure (less strict than full validation)
        #
        # @param config [Hash] Configuration to validate
        # @raise [Error] if configuration is invalid
        def validate_user_config!(config)
          raise Error, "Configuration must be a Hash" unless config.is_a?(Hash)

          validate_section!(config, "presets", Hash)
          validate_section!(config, "settings", Hash)
          validate_section!(config, "security", Hash)

          # Validate presets structure (only user-provided ones, not defaults)
          config["presets"]&.each do |preset_name, preset_config|
            validate_user_preset!(preset_name, preset_config)
          end
        end

        # Validate a configuration section
        #
        # @param config [Hash] Full configuration
        # @param section_name [String] Section to validate
        # @param expected_type [Class] Expected type for section
        def validate_section!(config, section_name, expected_type)
          return unless config.key?(section_name)
          return if config[section_name].is_a?(expected_type)

          raise Error, "#{section_name} must be a #{expected_type.name}"
        end

        # Validate a user-provided preset configuration (less strict)
        #
        # @param preset_name [String] Name of the preset
        # @param preset_config [Hash] Preset configuration
        def validate_user_preset!(preset_name, preset_config)
          unless preset_config.is_a?(Hash)
            raise Error, "Preset '#{preset_name}' must be a Hash"
          end

          # Validate optional keys have correct types (template not required for user presets)
          type_validations = {
            "description" => String,
            "template" => String,
            "output" => String,
            "chunk_limit" => Integer
          }

          type_validations.each do |key, expected_type|
            next unless preset_config.key?(key)
            next if preset_config[key].is_a?(expected_type)

            raise Error, "Preset '#{preset_name}' key '#{key}' must be a #{expected_type.name}"
          end
        end

        # Validate a single preset configuration (full validation for final config)
        #
        # @param preset_name [String] Name of the preset
        # @param preset_config [Hash] Preset configuration
        def validate_preset!(preset_name, preset_config)
          unless preset_config.is_a?(Hash)
            raise Error, "Preset '#{preset_name}' must be a Hash"
          end

          required_keys = %w[template]
          required_keys.each do |key|
            next if preset_config.key?(key)

            raise Error, "Preset '#{preset_name}' missing required key: #{key}"
          end

          # Validate optional keys have correct types
          type_validations = {
            "description" => String,
            "template" => String,
            "output" => String,
            "chunk_limit" => Integer
          }

          type_validations.each do |key, expected_type|
            next unless preset_config.key?(key)
            next if preset_config[key].is_a?(expected_type)

            raise Error, "Preset '#{preset_name}' key '#{key}' must be a #{expected_type.name}"
          end
        end

        # Merge user configuration with defaults
        #
        # @param config [Hash] User configuration
        # @return [Hash] Merged configuration
        def merge_with_defaults(config)
          merged = deep_merge(DEFAULT_CONFIG, config)

          # Ensure presets maintain proper structure
          if config["presets"]
            merged["presets"] = merge_presets(DEFAULT_CONFIG["presets"], config["presets"])
          end

          merged
        end

        # Merge preset configurations
        #
        # @param default_presets [Hash] Default preset configurations
        # @param user_presets [Hash] User preset configurations
        # @return [Hash] Merged presets
        def merge_presets(default_presets, user_presets)
          merged = default_presets.dup

          user_presets.each do |preset_name, preset_config|
            merged[preset_name] = if merged.key?(preset_name)
              # Merge with existing preset
              deep_merge(merged[preset_name], preset_config)
            else
              # Add new preset
              preset_config
            end
          end

          merged
        end

        # Deep merge two hashes
        #
        # @param hash1 [Hash] Base hash
        # @param hash2 [Hash] Hash to merge in
        # @return [Hash] Merged hash
        def deep_merge(hash1, hash2)
          result = hash1.dup

          hash2.each do |key, value|
            result[key] = if result[key].is_a?(Hash) && value.is_a?(Hash)
              deep_merge(result[key], value)
            else
              value
            end
          end

          result
        end
      end
    end
  end
end
