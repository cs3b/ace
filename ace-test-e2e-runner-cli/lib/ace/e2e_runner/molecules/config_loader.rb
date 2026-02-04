# frozen_string_literal: true

require "yaml"
require "ostruct"
require "ace/support/config"

module Ace
  module E2eRunner
    module Molecules
      class ConfigLoader
        def load(config_path = nil)
          gem_root = Gem.loaded_specs["ace-test-e2e-runner-cli"]&.gem_dir ||
                     File.expand_path("../../../..", __dir__)

          resolver = Ace::Support::Config.create(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: gem_root
          )

          config = resolver.resolve_file(["e2e/config.yml"]).data

          if config_path && File.exist?(config_path)
            user_config = load_from_file(config_path)
            config = Ace::Support::Config::Atoms::DeepMerger.merge(config, user_config)
          end

          config = deep_symbolize_keys(config)
          normalize_config(config)
        rescue StandardError => e
          warn "Warning: Could not load ace-test-e2e-runner-cli config: #{e.message}" if ENV["DEBUG"]
          normalize_config({})
        end

        def merge_with_options(config, options)
          merged = deep_copy(config)
          merged[:defaults] ||= {}
          merged[:execution] ||= {}

          merged[:defaults][:provider] = options[:provider] if options[:provider]
          merged[:defaults][:timeout] = options[:timeout] if options[:timeout]
          merged[:defaults][:temperature] = options[:temperature] if options[:temperature]
          merged[:defaults][:max_tokens] = options[:max_tokens] if options[:max_tokens]
          merged[:defaults][:report_dir] = options[:report_dir] if options[:report_dir]
          merged[:defaults][:format] = options[:format] if options[:format]

          merged[:execution][:max_parallel] = options[:parallel] if options[:parallel]

          OpenStruct.new(merged)
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

        def normalize_config(config)
          config[:defaults] ||= {}
          config[:execution] ||= {}
          config
        end

        def deep_copy(obj)
          Marshal.load(Marshal.dump(obj))
        end
      end
    end
  end
end
