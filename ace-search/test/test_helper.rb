# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ace/search"

# Load all components
require "ace/search/atoms/ripgrep_executor"
require "ace/search/atoms/fd_executor"
require "ace/search/atoms/pattern_analyzer"
require "ace/search/atoms/result_parser"
require "ace/search/atoms/tool_checker"

require "ace/search/molecules/preset_manager"
require "ace/search/molecules/git_scope_filter"
require "ace/search/molecules/dwim_analyzer"
require "ace/search/molecules/time_filter"
require "ace/search/molecules/fzf_integrator"

require "ace/search/organisms/unified_searcher"
require "ace/search/organisms/result_formatter"
require "ace/search/organisms/result_aggregator"

require "ace/search/models/search_result"
require "ace/search/models/search_options"
require "ace/search/models/search_preset"

require "minitest/autorun"
require "ace/test_support"

class AceSearchTestCase < AceTestCase
  # Helper to check if external tools are available
  def skip_unless_rg_available
    skip "ripgrep not available" unless Ace::Search::Atoms::ToolChecker.ripgrep_available?
  end

  def skip_unless_fd_available
    skip "fd not available" unless Ace::Search::Atoms::ToolChecker.fd_available?
  end
end
