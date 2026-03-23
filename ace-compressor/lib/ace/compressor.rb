# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "yaml"
require "ace/support/config"

require_relative "compressor/version"
require_relative "compressor/models/context_pack"
require_relative "compressor/atoms/markdown_parser"
require_relative "compressor/atoms/canonical_block_transformer"
require_relative "compressor/atoms/compact_policy_classifier"
require_relative "compressor/atoms/retention_reporter"
require_relative "compressor/molecules/cache_store"
require_relative "compressor/molecules/input_resolver"
require_relative "compressor/organisms/exact_compressor"
require_relative "compressor/organisms/compact_compressor"
require_relative "compressor/organisms/agent_compressor"
require_relative "compressor/organisms/compression_runner"
require_relative "compressor/organisms/benchmark_runner"
require_relative "compressor/cli"

module Ace
  module Compressor
    class Error < StandardError; end

    # Compress a content string directly (Ruby API for other gems).
    # @param text [String] markdown/text content
    # @param label [String] display label (original file path)
    # @param mode [String] compression mode ("exact" or "agent")
    # @return [String] compressed ContextPack records
    def self.compress_text(text, label:, mode: "exact")
      case mode
      when "exact"
        compressor = Organisms::ExactCompressor.new([], mode_label: mode)
        compressor.compress_text(text, label: label)
      when "agent"
        compress_text_via_file(text, label: label, mode: mode)
      else
        raise Error, "compress_text only supports exact and agent modes, got: #{mode}"
      end
    end

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
    rescue
      {}
    end

    def self.compress_text_via_file(text, label:, mode:)
      return text if text.to_s.strip.empty?

      Dir.mktmpdir("ace_compressor_text") do |tmpdir|
        source = File.join(tmpdir, label.to_s)
        FileUtils.mkdir_p(File.dirname(source))
        File.write(source, text)

        compressor = build_text_compressor(mode, source)
        output = compressor.compress_sources([source])
        strip_context_pack_header(output)
      end
    end
    private_class_method :compress_text_via_file

    def self.build_text_compressor(mode, source)
      case mode
      when "agent"
        Organisms::AgentCompressor.new([source])
      else
        raise Error, "Unsupported text compressor mode: #{mode}"
      end
    end
    private_class_method :build_text_compressor

    def self.strip_context_pack_header(output)
      lines = output.to_s.lines
      lines.shift if lines.first&.start_with?("H|ContextPack/")
      lines.join.strip
    end
    private_class_method :strip_context_pack_header

    private_class_method :load_gem_defaults_fallback
  end
end
