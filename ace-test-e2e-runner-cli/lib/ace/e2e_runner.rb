# frozen_string_literal: true

require "ace/core"
require_relative "e2e_runner/version"

# Models
require_relative "e2e_runner/models/test_scenario"
require_relative "e2e_runner/models/test_result"

# Atoms
require_relative "e2e_runner/atoms/test_discoverer"
require_relative "e2e_runner/atoms/frontmatter_parser"
require_relative "e2e_runner/atoms/prompt_builder"
require_relative "e2e_runner/atoms/result_parser"

# Molecules
require_relative "e2e_runner/molecules/config_loader"
require_relative "e2e_runner/molecules/test_executor"
require_relative "e2e_runner/molecules/report_writer"

# Organisms
require_relative "e2e_runner/organisms/test_orchestrator"
require_relative "e2e_runner/organisms/suite_orchestrator"

# CLI and commands
require_relative "e2e_runner/cli"

module Ace
  module E2eRunner
    class Error < StandardError; end

    # Define module namespaces
    module Atoms; end
    module Molecules; end
    module Organisms; end
    module Models; end
    module Commands; end
  end
end
