# frozen_string_literal: true

require "yaml"
require "date"

module Ace
  module Lint
    module Atoms
      # Loads skill validation schema from configuration cascade
      # Follows ADR-022: Configuration Default and Override Pattern
      class SkillSchemaLoader
        class << self
          # Load skills configuration using ace-config cascade
          # @return [Hash] Configuration hash with defaults merged
          def config
            @config ||= load_config
          end

          # Get schema for a specific file type
          # @param type [Symbol] File type (:skill, :workflow, :agent)
          # @return [Hash] Schema definition for the type
          def schema_for(type)
            schemas = config["schemas"] || {}
            schemas[type.to_s] || {}
          end

          # Get list of known tools
          # @return [Array<String>] List of known tool names
          def known_tools
            config["known_tools"] || []
          end

          # Get list of known Bash prefixes
          # @return [Array<String>] List of known Bash command prefixes
          def known_bash_prefixes
            config["known_bash_prefixes"] || []
          end

          def known_integration_providers
            config["known_integration_providers"] || []
          end

          # Reset configuration cache (useful for testing)
          def reset_cache!
            @config = nil
          end

          private

          def load_config
            gem_root = Gem.loaded_specs["ace-lint"]&.gem_dir ||
              File.expand_path("../../../..", __dir__)

            resolver = Ace::Support::Config.create(
              config_dir: ".ace",
              defaults_dir: ".ace-defaults",
              gem_path: gem_root
            )

            # Resolve skills-specific config
            config = resolver.resolve_namespace("lint", filename: "skills")
            config.data
          rescue => e
            warn "Warning: Could not load skills config: #{e.message}" if Ace::Lint.debug?
            load_gem_defaults_fallback
          end

          def load_gem_defaults_fallback
            gem_root = Gem.loaded_specs["ace-lint"]&.gem_dir ||
              File.expand_path("../../../..", __dir__)
            defaults_path = File.join(gem_root, ".ace-defaults", "lint", "skills.yml")

            return {} unless File.exist?(defaults_path)

            YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
          rescue
            {}
          end
        end
      end
    end
  end
end
