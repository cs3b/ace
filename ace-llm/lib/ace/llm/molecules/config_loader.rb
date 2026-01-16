# frozen_string_literal: true

require "ace/support/config"

module Ace
  module LLM
    module Molecules
      # Config loader for ace-llm using Ace::Support::Config cascade
      class ConfigLoader
        class << self
          # Load configuration from cascade (project → home → gem)
          # Uses resolve_namespace("llm") to load from llm/ subfolder
          def load
            Ace::Support::Config.create(
              config_dir: ".ace",
              defaults_dir: ".ace-defaults",
              gem_path: gem_root
            ).resolve_namespace("llm")
          end

          # Get configuration value by path
          # @param path [String] Dot-separated path like "llm.timeout"
          # @return [Object] Value at path or nil
          def get(path)
            config = load
            keys = path.split(".")
            config.get(*keys)
          end

          # Find gem root directory
          # From lib/ace/llm/molecules/config_loader.rb, go 4 levels up to ace-llm/
          def gem_root
            @gem_root ||= File.expand_path("../../../..", __dir__)
          end
        end
      end
    end
  end
end
