# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../search"
# Commands
require_relative "cli/commands/search"
# Atoms
require_relative "atoms/search_path_resolver"
require_relative "atoms/debug_logger"
require_relative "atoms/tool_checker"
require_relative "atoms/ripgrep_executor"
require_relative "atoms/fd_executor"
require_relative "atoms/result_parser"
require_relative "atoms/pattern_analyzer"
# Molecules
require_relative "molecules/fzf_integrator"
require_relative "molecules/preset_manager"
require_relative "molecules/time_filter"
require_relative "molecules/dwim_analyzer"
# Organisms
require_relative "organisms/unified_searcher"
require_relative "organisms/result_formatter"

module Ace
  module Search
    # CLI namespace for ace-search command loading.
    #
    # ace-search now uses a single-command ace-support-cli entrypoint that calls
    # CLI::Commands::Search directly from the executable.
    module CLI
    end
  end
end
