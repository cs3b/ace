# frozen_string_literal: true

require "yaml"
require "fileutils"

module CodingAgentTools
  module Molecules
    module Editor
      # Manages editor configuration settings
      class EditorConfigManager
        CONFIG_FILE_NAME = "config.yml"
        CONFIG_SECTION = "editor"
        
        def initialize
          # Use XDG Base Directory specification for config location
          config_dir = ENV.fetch("XDG_CONFIG_HOME", File.join(Dir.home, ".config"))
          app_config_dir = File.join(config_dir, "coding-agent-tools")
          @config_path = File.join(app_config_dir, CONFIG_FILE_NAME)
        end

        # Load editor configuration
        # @return [Hash] Editor configuration
        def load_config
          return {} unless File.exist?(@config_path)
          
          begin
            full_config = YAML.load_file(@config_path) || {}
            full_config.dig(CONFIG_SECTION) || {}
          rescue Psych::SyntaxError => e
            warn "Warning: Invalid YAML in config file #{@config_path}: #{e.message}"
            {}
          rescue => e
            warn "Warning: Could not load config file #{@config_path}: #{e.message}"
            {}
          end
        end

        # Save editor configuration
        # @param editor_config [Hash] Editor configuration to save
        # @return [Boolean] True if saved successfully
        def save_config(editor_config)
          # Load existing config
          full_config = if File.exist?(@config_path)
            begin
              YAML.load_file(@config_path) || {}
            rescue
              {}
            end
          else
            {}
          end

          # Update editor section
          full_config[CONFIG_SECTION] = editor_config

          # Ensure directory exists
          FileUtils.mkdir_p(File.dirname(@config_path))

          # Save config
          begin
            File.write(@config_path, YAML.dump(full_config))
            true
          rescue => e
            warn "Warning: Could not save config file #{@config_path}: #{e.message}"
            false
          end
        end

        # Set default editor
        # @param editor_command [String] Editor command/path
        # @param options [Hash] Additional editor options
        # @return [Boolean] True if saved successfully
        def set_default_editor(editor_command, options = {})
          config = load_config
          
          config["default"] = editor_command
          config["line_support"] = options[:line_support] if options.key?(:line_support)
          config["args"] = options[:args] if options.key?(:args)
          
          save_config(config)
        end

        # Get default editor
        # @return [String, nil] Default editor command
        def get_default_editor
          config = load_config
          config["default"]
        end

        # Set editor arguments
        # @param args [Array<String>] Command line arguments for editor
        # @return [Boolean] True if saved successfully
        def set_editor_args(args)
          config = load_config
          config["args"] = args
          save_config(config)
        end

        # Get editor arguments
        # @return [Array<String>] Editor arguments
        def get_editor_args
          config = load_config
          config["args"] || []
        end

        # Enable or disable line number support
        # @param enabled [Boolean] Whether line support is enabled
        # @return [Boolean] True if saved successfully
        def set_line_support(enabled)
          config = load_config
          config["line_support"] = enabled
          save_config(config)
        end

        # Check if line number support is enabled
        # @return [Boolean] True if line support is enabled
        def line_support_enabled?
          config = load_config
          config["line_support"] != false # Default to true
        end

        # Get configuration file path
        # @return [String] Path to configuration file
        def config_file_path
          @config_path
        end

        # Check if configuration exists
        # @return [Boolean] True if configuration file exists
        def config_exists?
          File.exist?(@config_path)
        end

        # Reset configuration to defaults
        # @return [Boolean] True if reset successfully
        def reset_config
          config = {
            "default" => nil,
            "line_support" => true,
            "args" => []
          }
          
          save_config(config)
        end

        # Get full configuration for debugging
        # @return [Hash] Complete configuration
        def debug_config
          {
            config_path: @config_path,
            exists: config_exists?,
            editor_config: load_config,
            config_dir: File.dirname(@config_path)
          }
        end
      end
    end
  end
end