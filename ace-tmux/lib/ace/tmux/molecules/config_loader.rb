# frozen_string_literal: true

require "ace/support/config"

module Ace
  module Tmux
    module Molecules
      # Loads general tmux configuration via the ACE config cascade
      module ConfigLoader
        module_function

        # Load tmux config from cascade
        #
        # @param gem_root [String] Gem root directory
        # @return [Hash] Merged configuration hash
        def load(gem_root:)
          resolver = Ace::Support::Config.create(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: gem_root
          )

          config = resolver.resolve_namespace("tmux")
          config.data
        rescue => e
          warn "ace-tmux: Could not load config: #{e.class} - #{e.message}" if Tmux.debug?
          load_fallback(gem_root)
        end

        # Load gem defaults directly as fallback
        #
        # @param gem_root [String] Gem root directory
        # @return [Hash] Defaults hash or empty hash
        def load_fallback(gem_root)
          defaults_path = File.join(gem_root, ".ace-defaults", "tmux", "config.yml")
          return {} unless File.exist?(defaults_path)

          require "yaml"
          YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
        rescue
          {}
        end
      end
    end
  end
end
