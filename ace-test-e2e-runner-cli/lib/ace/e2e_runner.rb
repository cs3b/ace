# frozen_string_literal: true

require "ace/core"
require_relative "e2e_runner/version"
require_relative "e2e_runner/cli"

module Ace
  module E2eRunner
    class Error < StandardError; end

    # Namespace for CLI commands (Hanami pattern)
    module Commands; end
  end
end
