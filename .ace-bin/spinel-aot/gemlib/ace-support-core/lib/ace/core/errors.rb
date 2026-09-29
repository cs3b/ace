# frozen_string_literal: true

module Ace
  module Core
    # Base error class for all ace-core errors
    class Error < StandardError; end

    # Raised when configuration file is invalid (ace-specific)
    class ConfigInvalidError < Error; end

    # Raised when environment file parsing fails (ace-specific)
    class EnvParseError < Error; end
  end
end
