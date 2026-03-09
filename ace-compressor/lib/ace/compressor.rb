# frozen_string_literal: true

require "yaml"
require "ace/support/config"

require_relative "compressor/version"
require_relative "compressor/models/context_pack"
require_relative "compressor/atoms/markdown_parser"
require_relative "compressor/atoms/canonical_block_transformer"
require_relative "compressor/atoms/compact_policy_classifier"
require_relative "compressor/atoms/retention_reporter"
require_relative "compressor/molecules/cache_store"
require_relative "compressor/organisms/exact_compressor"
require_relative "compressor/organisms/compact_compressor"
require_relative "compressor/organisms/agent_compressor"
require_relative "compressor/organisms/compression_runner"
require_relative "compressor/organisms/benchmark_runner"
require_relative "compressor/cli"

module Ace
  module Compressor
    class Error < StandardError; end

    def self.config
      @config ||= begin
        gem_root = Gem.loaded_specs["ace-compressor"]&.gem_dir ||
                   File.expand_path("../..", __dir__)

        resolver = Ace::Support::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        config = resolver.resolve_namespace("compressor").to_h
        config.empty? ? load_gem_defaults_fallback(gem_root) : config
      end
    end

    def self.reset_config!
      @config = nil
    end

    def self.load_gem_defaults_fallback(gem_root = nil)
      root = gem_root || Gem.loaded_specs["ace-compressor"]&.gem_dir ||
             File.expand_path("../..", __dir__)
      defaults_path = File.join(root, ".ace-defaults", "compressor", "config.yml")
      return {} unless File.exist?(defaults_path)

      YAML.safe_load_file(defaults_path, aliases: true) || {}
    rescue StandardError
      {}
    end
    private_class_method :load_gem_defaults_fallback
  end
end
