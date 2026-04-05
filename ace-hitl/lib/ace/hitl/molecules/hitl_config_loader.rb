# frozen_string_literal: true

require "yaml"
require "ace/support/config"
require "ace/support/fs"

module Ace
  module Hitl
    module Molecules
      class HitlConfigLoader
        DEFAULT_ROOT_DIR = ".ace-local/hitl"
        DEFAULT_KIND = "clarification"

        def self.load(gem_root: nil)
          gem_root ||= File.expand_path("../../../..", __dir__)
          resolver = Ace::Support::Config.create(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: gem_root
          )
          {"hitl" => resolver.resolve_namespace("hitl").data}
        rescue StandardError => e
          warn "ace-hitl: Could not load config: #{e.class} - #{e.message}" if Ace::Hitl.respond_to?(:debug?) && Ace::Hitl.debug?
          load_defaults_fallback(gem_root: gem_root)
        end

        def self.root_dir(config = nil)
          config ||= load
          dir = config.dig("hitl", "root_dir") || DEFAULT_ROOT_DIR

          if dir.start_with?("/")
            dir
          else
            File.join(Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current, dir)
          end
        end

        def self.load_defaults_fallback(gem_root:)
          defaults_path = File.join(gem_root, ".ace-defaults", "hitl", "config.yml")
          return {} unless File.exist?(defaults_path)

          YAML.safe_load_file(defaults_path, permitted_classes: [Date, Time, Symbol], aliases: true) || {}
        rescue StandardError
          {}
        end
        private_class_method :load_defaults_fallback
      end
    end
  end
end
