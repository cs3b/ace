# frozen_string_literal: true

module Ace
  module Core
    # Base error class for all ace-core errors
    class Error < StandardError; end

    # Raised when configuration file is not found
    class ConfigNotFoundError < Error; end

    # Raised when configuration file is invalid
    class ConfigInvalidError < Error; end

    # Raised when YAML parsing fails
    class YamlParseError < Error; end

    # Raised when environment file parsing fails
    class EnvParseError < Error; end

    # Raised when a path cannot be resolved
    class PathError < Error; end

    # Raised when merge strategy is invalid
    class MergeStrategyError < Error; end
  end
end