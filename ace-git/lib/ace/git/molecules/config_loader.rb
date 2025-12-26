# frozen_string_literal: true

module Ace
  module Git
    module Molecules
      # Load and merge diff configuration from cascade
      # Follows ADR-022: Configuration Default and Override Pattern
      # Migrated from ace-git-diff
      class ConfigLoader
        class << self
          # Load configuration using ace-core cascade with deep merge
          # Priority: instance_config merged over global config (which is already defaults + user)
          # @param instance_config [Hash] Instance-level configuration (highest priority)
          # @return [Models::DiffConfig] Merged configuration
          def load(instance_config = {})
            # Get global config from ace-git (already merged defaults + user per ADR-022)
            global_config = Ace::Git.config || {}

            # Extract diff config from the global config (handles diff: namespace)
            global_diff_config = extract_diff_config(global_config)

            # Deep merge instance config over global (instance overrides, but preserves unset defaults)
            config_hash = Ace::Core::Atoms::DeepMerger.merge(global_diff_config, instance_config)

            Models::DiffConfig.from_hash(config_hash)
          end

          # Load configuration for a specific gem integration
          # Priority: instance_config > gem_config > global_config (all deep merged)
          # @param gem_config [Hash] Gem-specific configuration
          # @param instance_config [Hash] Instance-level overrides
          # @return [Models::DiffConfig] Merged configuration
          def load_for_gem(gem_config, instance_config = {})
            # Start with global config (already merged defaults + user per ADR-022)
            global_config = Ace::Git.config || {}

            # Extract diff config from global (handles diff: namespace)
            global_diff_config = extract_diff_config(global_config)

            # Deep merge gem config over global
            gem_diff_config = extract_diff_config(gem_config)
            config_hash = Ace::Core::Atoms::DeepMerger.merge(global_diff_config, gem_diff_config)

            # Deep merge instance config over result
            config_hash = Ace::Core::Atoms::DeepMerger.merge(config_hash, instance_config)

            Models::DiffConfig.from_hash(config_hash)
          end

          # Extract diff configuration from various config formats
          # Supports both diff: key and legacy/direct formats
          # When config contains both top-level diff keys AND a nested diff: section,
          # merges them (nested overrides top-level) to preserve defaults
          # @param config [Hash] Configuration hash
          # @return [Hash] Extracted diff configuration
          def extract_diff_config(config)
            return {} if config.nil? || config.empty?

            # First, collect any top-level diff keys (flattened defaults)
            diff_keys = %w[exclude_patterns exclude_whitespace exclude_renames
                           exclude_moves max_lines ranges paths since format timeout]
            diff_sym_keys = diff_keys.map(&:to_sym)

            top_level_diff = {}
            diff_keys.each { |k| top_level_diff[k] = config[k] if config.key?(k) }
            diff_sym_keys.each { |k| top_level_diff[k.to_s] = config[k] if config.key?(k) }

            # Check for explicit diff: key (nested under git: from config cascade)
            if config.key?("diff") || config.key?(:diff)
              diff_config = config["diff"] || config[:diff]
              if diff_config.is_a?(Hash)
                # Merge nested diff over top-level to preserve defaults not overridden
                return Ace::Core::Atoms::DeepMerger.merge(top_level_diff, diff_config)
              end
            end

            # Return top-level diff keys if we found any
            return top_level_diff unless top_level_diff.empty?

            # Check for legacy diffs: array format
            if config.key?("diffs") || config.key?(:diffs)
              diffs = config["diffs"] || config[:diffs]
              return { "ranges" => Array(diffs) } if diffs
            end

            # Check for legacy filters format (ace-docs)
            if config.key?("filters") || config.key?(:filters)
              filters = config["filters"] || config[:filters]
              return { "paths" => Array(filters) } if filters
            end

            # No diff config found
            {}
          end
        end
      end
    end
  end
end
