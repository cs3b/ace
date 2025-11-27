# frozen_string_literal: true

require "ace/core"

module Ace
  module Prompt
    module Molecules
      # Load configuration from ace config cascade
      class ConfigLoader
        # Get gem root using Gem.loaded_specs for more reliable path resolution
        def self.gem_root
          if Gem.loaded_specs["ace-prompt"]
            Gem.loaded_specs["ace-prompt"].full_gem_path
          else
            # Fallback to __dir__ if gem spec not available (development mode)
            File.expand_path("../..", __dir__)
          end
        end

        DEFAULT_CONFIG = {
          "default_dir" => ".cache/ace-prompt/prompts",
          "default_file" => "the-prompt.md",
          "archive_subdir" => "archive",
          # Use gem-relative path with Gem.loaded_specs for reliable resolution
          "template" => File.join(gem_root, "handbook", "templates", "base-prompt.template.md"),
          "context" => {
            "enabled" => false
          },
          "enhancement" => {
            "enabled" => false,
            "model" => "glite",
            "temperature" => 0.3,
            "system_prompt" => "prompt://enhance-instructions.system"
          }
        }.freeze

        # Load configuration with defaults
        # @return [Hash] Configuration hash
        def self.load
          config = Ace::Core.config.get("ace", "prompt") || {}
          deep_merge(DEFAULT_CONFIG, config)
        end

        # Deep merge two hashes
        # @param base [Hash] Base hash
        # @param override [Hash] Override hash
        # @return [Hash] Merged hash
        def self.deep_merge(base, override)
          base.merge(override) do |_key, base_val, override_val|
            if base_val.is_a?(Hash) && override_val.is_a?(Hash)
              deep_merge(base_val, override_val)
            else
              override_val
            end
          end
        end
      end
    end
  end
end
