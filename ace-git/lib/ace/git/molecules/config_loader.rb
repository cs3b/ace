# frozen_string_literal: true

require "ace/support/config"

module Ace
  module Git
    module Molecules
      # Load and merge diff configuration from cascade
      # Follows ADR-022: Configuration Default and Override Pattern
      # Uses Config.merge() for consistent merge strategy support
      # Migrated from ace-git-diff
      class ConfigLoader
        class << self
          # Load configuration using ace-config cascade with deep merge
          # Priority: instance_config merged over global config (which is already defaults + user)
          # @param instance_config [Hash] Instance-level configuration (highest priority)
          # @return [Models::DiffConfig] Merged configuration
          def load(instance_config = {})
            # Get global config from ace-git (already merged defaults + user per ADR-022)
            global_config = Ace::Git.config || {}

            # Extract diff config from the global config (handles diff: namespace)
            global_diff_config = extract_diff_config(global_config)

            # Use Config.merge() for consistent merge strategy support
            # This enables future per-key merge strategies via _merge directive
            config_hash = Ace::Support::Config::Models::Config.new(global_diff_config, source: "git_global")
              .merge(instance_config)
              .to_h

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
            gem_diff_config = extract_diff_config(gem_config)

            # Use Config.merge() cascade: global -> gem -> instance
            # This enables future per-key merge strategies via _merge directive
            config_hash = Ace::Support::Config::Models::Config.new(global_diff_config, source: "git_global")
              .merge(gem_diff_config)
              .merge(instance_config)
              .to_h

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
              exclude_moves max_lines ranges paths since format timeout grouped_stats]
            diff_sym_keys = diff_keys.map(&:to_sym)

            top_level_diff = {}
            diff_keys.each { |k| top_level_diff[k] = config[k] if config.key?(k) }
            diff_sym_keys.each { |k| top_level_diff[k.to_s] = config[k] if config.key?(k) }

            # Check for explicit diff: key (nested under git: from config cascade)
            if config.key?("diff") || config.key?(:diff)
              diff_config = config["diff"] || config[:diff]
              if diff_config.is_a?(Hash)
                # Merge nested diff over top-level using Config.merge()
                return Ace::Support::Config::Models::Config.new(top_level_diff, source: "git_diff_extract")
                    .merge(diff_config)
                    .to_h
              end
            end

            # Return top-level diff keys if we found any
            return top_level_diff unless top_level_diff.empty?

            # Check for legacy diffs: array format
            if config.key?("diffs") || config.key?(:diffs)
              diffs = config["diffs"] || config[:diffs]
              return {"ranges" => Array(diffs)} if diffs
            end

            # Check for legacy filters format (ace-docs)
            if config.key?("filters") || config.key?(:filters)
              filters = config["filters"] || config[:filters]
              return {"paths" => Array(filters)} if filters
            end

            # No diff config found
            {}
          end
        end
      end
    end
  end
end
