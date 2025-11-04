# frozen_string_literal: true

require_relative "models/worktree_config"

module Ace
  module Git
    module Worktree
      # Configuration loader using ace-core cascade
      class Configuration
        attr_reader :config

        def initialize
          load_config
        end

        # Load configuration from ace-core cascade
        def load_config
          raw_config = if defined?(Ace::Core) && Ace::Core.respond_to?(:config)
                        # Use ace-core configuration cascade
                        Ace::Core.config.get("git", "worktree") || {}
                      else
                        # Fallback to loading directly from file if ace-core not available
                        load_from_file
                      end

          # Convert string keys to symbols for the model
          symbolized = symbolize_keys(raw_config)
          @config = Models::WorktreeConfig.new(symbolized)

          unless @config.valid?
            raise ConfigurationError, "Invalid configuration: #{@config.errors.join(', ')}"
          end
        end

        # Reload configuration
        def reload!
          load_config
        end

        # Access configuration values
        def method_missing(method_name, *args)
          if @config.respond_to?(method_name)
            @config.send(method_name, *args)
          else
            super
          end
        end

        def respond_to_missing?(method_name, include_private = false)
          @config.respond_to?(method_name) || super
        end

        # Get the full configuration hash
        def to_h
          @config.to_h
        end

        private

        # Fallback method to load configuration from file directly
        def load_from_file
          paths = [
            ".ace/git/worktree.yml",
            ".ace/git/worktree.yaml",
            File.expand_path("~/.ace/git/worktree.yml"),
            File.expand_path("~/.ace/git/worktree.yaml")
          ]

          paths.each do |path|
            if File.exist?(path)
              require 'yaml'
              content = File.read(path)
              return YAML.safe_load(content, permitted_classes: [Symbol]) || {}
            end
          end

          # Return empty hash if no config file found
          {}
        end

        # Convert string keys to symbols recursively
        def symbolize_keys(hash)
          return hash unless hash.is_a?(Hash)

          hash.each_with_object({}) do |(key, value), result|
            new_key = key.is_a?(String) ? key.to_sym : key
            new_value = value.is_a?(Hash) ? symbolize_keys(value) : value
            result[new_key] = new_value
          end
        end
      end
    end
  end
end