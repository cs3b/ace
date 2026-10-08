# frozen_string_literal: true

module Ace
  module Lab
    class Error < StandardError; end

    # Raised when topology configuration violates the schema contract
    class InvalidConfigurationError < Error; end
  end
end

