# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "version"
# Commands
require_relative "cli/commands/test"

module Ace
  module TestRunner
    # CLI namespace for ace-test-runner command classes.
    module CLI
      PROGRAM_NAME = "ace-test"
    end
  end
end
