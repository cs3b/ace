# frozen_string_literal: true

require "ace/core"
require_relative "taskflow/version"
require_relative "taskflow/cli"

module Ace
  module Taskflow
    class Error < StandardError; end
    # Entry point module
  end
end