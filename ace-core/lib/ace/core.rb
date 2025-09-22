# frozen_string_literal: true

require_relative "core/version"
require_relative "core/errors"

# Main API
require_relative "core/organisms/config_resolver"
require_relative "core/organisms/environment_manager"
require_relative "core/config_discovery"

module Ace
  module Core
    # Main module providing config cascade and environment management
    class << self
      # Resolve configuration with cascade
      # @param search_paths [Array<String>] Optional search paths
      # @return [Models::Config] Resolved configuration
      def config(search_paths: nil)
        resolver = Organisms::ConfigResolver.new(search_paths: search_paths)
        resolver.resolve
      end

      # Get configuration value by key path
      # @param keys [Array<String,Symbol>] Key path to value
      # @return [Object] Configuration value
      def get(*keys)
        resolver = Organisms::ConfigResolver.new
        resolver.get(*keys)
      end

      # Load environment variables
      # @param root [String] Project root path
      # @return [Hash] Loaded variables
      def load_environment(root: Dir.pwd)
        manager = Organisms::EnvironmentManager.new(root_path: root)
        manager.load
      end

      # Create default configuration
      # @param path [String] Where to create config
      # @return [Models::Config] Created config
      def create_default_config(path = "./.ace/core/config.yml")
        Organisms::ConfigResolver.create_default(path)
      end

      # Get environment manager
      # @param root [String] Project root
      # @return [Organisms::EnvironmentManager] Environment manager
      def environment(root: Dir.pwd)
        Organisms::EnvironmentManager.new(root_path: root)
      end
    end
  end
end
