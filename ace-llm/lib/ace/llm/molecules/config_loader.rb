# frozen_string_literal: true

require "ace/support/config"

module Ace
  module LLM
    module Molecules
      # Config loader for ace-llm using Ace::Support::Config cascade
      class ConfigLoader
        class << self
          # Load configuration from cascade (project → home → gem)
          def load
            Ace::Support::Config.create(
              config_dir: ".ace",
              defaults_dir: ".ace-defaults",
              gem_path: gem_root
            ).resolve
          end

          # Get configuration value by path
          def get(path)
            config = load
            path.split(".").each do |key|
              config = config[key] || break
            end
            config
          end

          # Find gem root directory
          def gem_root
            @gem_root ||= File.expand_path("../../..", __dir__)
          end
        end
      end
    end
  end
end
