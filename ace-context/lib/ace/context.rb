# frozen_string_literal: true

require 'ace/core'
require_relative 'context/version'

# Main API
require_relative 'context/organisms/context_loader'
require_relative 'context/molecules/preset_manager'
require_relative 'context/molecules/context_file_writer'

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

      # Load multiple presets and merge them
      # @param preset_names [Array<String>] Names of presets to load
      # @param options [Hash] Additional options
      # @return [Models::ContextData] Merged context data
      def load_multiple_presets(preset_names, options = {})
        loader = Organisms::ContextLoader.new(options)
        loader.load_multiple_presets(preset_names)
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

      # Load with auto-detection
      # @param input [String] File path, inline YAML, or preset name
      # @param options [Hash] Additional options
      # @return [Models::ContextData] Loaded context data
      def load_auto(input, options = {})
        loader = Organisms::ContextLoader.new(options)
        loader.load_auto(input)
      end

      # Load multiple inputs and merge them
      # @param inputs [Array<String>] Array of inputs to load
      # @param options [Hash] Additional options
      # @return [Models::ContextData] Merged context data
      def load_multiple(inputs, options = {})
        loader = Organisms::ContextLoader.new(options)
        loader.load_multiple(inputs)
      end

      # Write context output to file with optional chunking
      # @param context [Models::ContextData] Context to write
      # @param output_path [String] Output file path
      # @param options [Hash] Additional options
      # @return [Hash] Write result with success status
      def write_output(context, output_path, options = {})
        writer = Molecules::ContextFileWriter.new
        writer.write_with_chunking(context, output_path, options)
      end
    end
  end
end