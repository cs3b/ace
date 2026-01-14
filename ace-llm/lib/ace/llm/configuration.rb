# frozen_string_literal: true

require_relative "molecules/config_loader"

module Ace
  module LLM
    # Central configuration management for ace-llm
    class Configuration
      attr_reader :config

      def initialize
        @config = Molecules::ConfigLoader.load
      end

      # Get all provider configurations from the cascade
      # Uses ProviderConfigReader which handles project → home → gem discovery
      def providers
        @providers ||= begin
          require "ace/support/models"
          Ace::Support::Models::Atoms::ProviderConfigReader.read_all
        end
      end

      # Get provider config by name
      def provider(name)
        providers[name]
      end

      # Check if provider exists
      def provider?(name)
        providers.key?(name)
      end

      # Get all provider names
      def provider_names
        providers.keys
      end

      # Reload configuration
      def reload!
        @config = Molecules::ConfigLoader.load
        @providers = nil
        self
      end

      # Get configuration value by path
      def get(path)
        Molecules::ConfigLoader.get(path)
      end

      # Check if configuration exists
      def configured?
        !config.empty?
      end
    end

    # Module-level configuration accessor
    def self.configuration
      @configuration ||= Configuration.new
    end

    # Configure block
    def self.configure
      yield(configuration)
    end

    # Reset configuration
    def self.reset_configuration!
      @configuration = Configuration.new
    end

    # Get all providers (convenience method)
    def self.providers
      configuration.providers
    end

    # Get provider config by name (convenience method)
    def self.provider(name)
      configuration.provider(name)
    end
  end
end
