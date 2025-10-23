# frozen_string_literal: true

module Ace
  module GitDiff
    module Molecules
      # Load and merge diff configuration from cascade
      class ConfigLoader
        class << self
          # Load configuration using ace-core cascade with complete override
          # @param instance_config [Hash] Instance-level configuration (highest priority)
          # @return [Models::DiffConfig] Merged configuration
          def load(instance_config = {})
            # Get global config from ace-core
            global_config = Ace::GitDiff.config || {}

            # Instance config completely overrides global (no merging)
            config_hash = instance_config.empty? ? global_config : instance_config

            Models::DiffConfig.from_hash(config_hash)
          end

          # Load configuration for a specific gem integration
          # @param gem_config [Hash] Gem-specific configuration
          # @param instance_config [Hash] Instance-level overrides
          # @return [Models::DiffConfig] Merged configuration
          def load_for_gem(gem_config, instance_config = {})
            # Start with global config
            global_config = Ace::GitDiff.config || {}

            # Apply gem config (overrides global)
            config_hash = gem_config.empty? ? global_config : gem_config

            # Apply instance config (overrides everything)
            config_hash = instance_config unless instance_config.empty?

            Models::DiffConfig.from_hash(config_hash)
          end

          # Extract diff configuration from various config formats
          # Supports both diff: key and legacy formats
          # @param config [Hash] Configuration hash
          # @return [Hash] Extracted diff configuration
          def extract_diff_config(config)
            return {} if config.nil? || config.empty?

            # Check for explicit diff: key
            if config.key?("diff") || config.key?(:diff)
              diff_config = config["diff"] || config[:diff]
              return diff_config if diff_config.is_a?(Hash)
            end

            # Check for legacy diffs: array format
            if config.key?("diffs") || config.key?(:diffs)
              diffs = config["diffs"] || config[:diffs]
              return { ranges: Array(diffs) } if diffs
            end

            # Check for legacy filters format (ace-docs)
            if config.key?("filters") || config.key?(:filters)
              filters = config["filters"] || config[:filters]
              return { paths: Array(filters) } if filters
            end

            {}
          end
        end
      end
    end
  end
end
