# frozen_string_literal: true

module Ace
  module Core
    # Base error class for all ace-core errors
    class Error < StandardError; end

    # Raised when configuration file is invalid (ace-specific)
    class ConfigInvalidError < Error; end

    # Raised when environment file parsing fails (ace-specific)
    class EnvParseError < Error; end

    # Note: The following errors are now aliases to ace-config errors,
    # defined in lib/ace/core.rb for backward compatibility:
    # - ConfigNotFoundError -> Ace::Support::Config::ConfigNotFoundError
    # - YamlParseError -> Ace::Support::Config::YamlParseError
    # - PathError -> Ace::Support::Config::PathError
    # - MergeStrategyError -> Ace::Support::Config::MergeStrategyError
  end
end
