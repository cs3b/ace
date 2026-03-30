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
        @providers ||= filter_active_providers(all_providers)
      end

      # Get all configured provider configurations before allow-list filtering
      def all_providers
        @all_providers ||= begin
          require "ace/support/models"
          Ace::Support::Models::Atoms::ProviderConfigReader.read_all
        end
      end

      # Get provider config by name
      def provider(name)
        normalized = normalize_provider_name(name)
        _name, config = providers.find do |provider_name, provider_config|
          normalize_provider_name(provider_name) == normalized ||
            normalize_provider_name(provider_config["name"]) == normalized
        end
        config
      end

      # Check if provider exists
      def provider?(name)
        !provider(name).nil?
      end

      # Get all provider names
      def provider_names
        providers.keys
      end

      # Reload configuration
      def reload!
        @config = Molecules::ConfigLoader.load
        @all_providers = nil
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

      # Returns true when allow-list filtering is active.
      def provider_filter_applied?
        !active_provider_allow_list.nil?
      end

      # Normalized names of all configured providers.
      def configured_provider_names
        all_providers.map do |provider_name, provider_config|
          normalize_provider_name(provider_config["name"] || provider_name)
        end.uniq.sort
      end

      # Normalized names of active providers after filtering.
      def active_provider_names
        providers.map do |provider_name, provider_config|
          normalize_provider_name(provider_config["name"] || provider_name)
        end.uniq.sort
      end

      # Normalized names that are configured but inactive under active filter.
      def inactive_provider_names
        return [] unless provider_filter_applied?

        configured_provider_names - active_provider_names
      end

      # Returns true when provider exists in config but is excluded by allow-list.
      def provider_inactive?(name)
        normalized = normalize_provider_name(name)
        return false if normalized.empty?
        return false unless provider_filter_applied?

        configured_provider_names.include?(normalized) && !active_provider_names.include?(normalized)
      end

      private

      def filter_active_providers(provider_configs)
        active_allow_list = active_provider_allow_list
        return provider_configs if active_allow_list.nil?

        filtered = provider_configs.select do |provider_name, provider_config|
          normalized = normalize_provider_name(provider_config["name"] || provider_name)
          active_allow_list.include?(normalized)
        end

        warn_on_unknown_active_entries(provider_configs, active_allow_list)
        filtered
      end

      def warn_on_unknown_active_entries(provider_configs, active_allow_list)
        available = provider_configs.map do |provider_name, provider_config|
          normalize_provider_name(provider_config["name"] || provider_name)
        end.uniq

        unknown = active_allow_list - available
        return if unknown.empty?

        warn "Unknown providers in llm.providers.active: #{unknown.join(", ")} (ignored). " \
          "These names do not match configured providers and were skipped. " \
          "Update llm.providers.active to use supported provider names, or run " \
          "`ace-llm --list-providers` for available providers and configuration guidance."
      end

      def active_provider_allow_list
        env_present, env_active = active_provider_allow_list_from_env
        return env_active if env_present

        normalize_provider_allow_list(get("llm.providers.active"))
      end

      def active_provider_allow_list_from_env
        return [false, nil] unless ENV.key?("ACE_LLM_PROVIDERS_ACTIVE")

        raw = ENV["ACE_LLM_PROVIDERS_ACTIVE"].to_s
        parsed = normalize_provider_allow_list(raw.split(","))

        # Empty env explicitly disables filtering (same as no active list).
        [true, parsed]
      end

      def normalize_provider_allow_list(value)
        normalized = Array(value).map { |entry| normalize_provider_name(entry) }.reject(&:empty?).uniq
        normalized.empty? ? nil : normalized
      end

      def normalize_provider_name(name)
        name.to_s.strip.downcase.gsub(/[-_]/, "")
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
