# frozen_string_literal: true

require "yaml"
require "ace/support/config"

module Ace
  module Scheduler
    module Molecules
      class ConfigLoader
        def load(config_path = nil)
          gem_root = Gem.loaded_specs["ace-scheduler"]&.gem_dir ||
                     File.expand_path("../../../..", __dir__)

          resolver = Ace::Support::Config.create(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: gem_root
          )

          config = resolver.resolve_file(["scheduler/config.yml"]).data

          if config_path && File.exist?(config_path)
            user_config = load_from_file(config_path)
            config = Ace::Support::Config::Atoms::DeepMerger.merge(config, user_config)
          end

          deep_symbolize_keys(config)
        rescue StandardError => e
          warn "Warning: Could not load ace-scheduler config: #{e.message}" if ENV["DEBUG"]
          { version: 1, tasks: {}, events: {}, state_dir: ".ace/scheduler/state" }
        end

        private

        def load_from_file(path)
          YAML.safe_load_file(path, permitted_classes: [], aliases: true) || {}
        rescue StandardError => e
          warn "Warning: Failed to load config from #{path}: #{e.message}"
          {}
        end

        def deep_symbolize_keys(obj)
          case obj
          when Hash
            obj.each_with_object({}) do |(key, value), result|
              result[key.to_sym] = deep_symbolize_keys(value)
            end
          when Array
            obj.map { |item| deep_symbolize_keys(item) }
          else
            obj
          end
        end
      end
    end
  end
end
