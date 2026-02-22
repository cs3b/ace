# frozen_string_literal: true

require "ace/core"
require_relative "taskflow/version"
require_relative "taskflow/configuration"

# Molecules that need to be available for cache clearing
require_relative "taskflow/molecules/task_loader"
require_relative "taskflow/molecules/release_resolver"

require_relative "taskflow/cli"
require_relative "taskflow/cli/task_cli"
require_relative "taskflow/cli/idea_cli"
require_relative "taskflow/cli/release_cli"
require_relative "taskflow/cli/retro_cli"

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