# frozen_string_literal: true

require "yaml"
require "ace/support/config"

require_relative "compressor/version"
require_relative "compressor/models/context_pack"
require_relative "compressor/atoms/markdown_parser"
require_relative "compressor/molecules/cache_store"
require_relative "compressor/organisms/exact_compressor"
require_relative "compressor/organisms/compression_runner"
require_relative "compressor/cli"

module Ace
  module Compressor
    class Error < StandardError; end

    def self.config
      @config ||= begin
        resolver = Ace::Support::Config.create
        resolver.resolve_namespace("compressor").to_h
      end
    end

    def self.reset_config!
      @config = nil
    end
  end
end
