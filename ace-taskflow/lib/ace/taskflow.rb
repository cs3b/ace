# frozen_string_literal: true

require "ace/core"
require_relative "taskflow/version"
require_relative "taskflow/configuration"
require_relative "taskflow/cli"

module Ace
  module Taskflow
    class Error < StandardError; end

    # Define module namespaces
    module Atoms; end
    module Molecules; end
    module Organisms; end
    module Models; end
    module Commands; end
  end
end