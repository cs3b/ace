# frozen_string_literal: true

require 'ace/core'
require_relative 'context/version'

# Main API
require_relative 'context/organisms/context_loader'
require_relative 'context/molecules/preset_manager'

module Ace
  module Context
    class << self
      # Load context using preset
      # @param preset_name [String] Name of the preset to load
      # @param options [Hash] Additional options
      # @return [Models::ContextData] Loaded context data
      def load_preset(preset_name, options = {})
        loader = Organisms::ContextLoader.new(options)
        loader.load_preset(preset_name)
      end

      # List available presets
      # @return [Array<Hash>] List of available presets
      def list_presets
        manager = Molecules::PresetManager.new
        manager.list_presets
      end

      # Load context from file
      # @param path [String] Path to context file
      # @param options [Hash] Additional options
      # @return [Models::ContextData] Loaded context data
      def load_file(path, options = {})
        loader = Organisms::ContextLoader.new(options)
        loader.load_file(path)
      end

      # Get configuration
      # @return [Hash] Context configuration
      def config
        @config ||= Ace::Core::Organisms::ConfigResolver.new(
          search_paths: ['.ace'],
          file_patterns: ['context.yml', 'context.yaml']
        ).resolve
      end
    end
  end
end