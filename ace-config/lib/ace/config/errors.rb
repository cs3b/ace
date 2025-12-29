# frozen_string_literal: true

require "ace/support/fs"

module Ace
  module Config
    # Base error class for all ace-config errors
    class Error < StandardError; end

    # Raised when configuration file is not found
    class ConfigNotFoundError < Error; end

    # Raised when YAML parsing fails
    class YamlParseError < Error; end

    # Raised when a path cannot be resolved
    class PathError < Error; end

    # Raised when merge strategy is invalid
    class MergeStrategyError < Error; end
  end
end
