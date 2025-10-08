# frozen_string_literal: true

require "test_helper"

module Ace
  module Search
    module Atoms
      class TestToolChecker < AceSearchTestCase
        def test_ripgrep_availability
          # This should be true in CI and dev environments
          result = ToolChecker.ripgrep_available?
          assert [true, false].include?(result), "Should return boolean"
        end

        def test_fd_availability
          result = ToolChecker.fd_available?
          assert [true, false].include?(result), "Should return boolean"
        end

        def test_fzf_availability
          result = ToolChecker.fzf_available?
          assert [true, false].include?(result), "Should return boolean"
        end

        def test_check_tool_returns_boolean
          result = ToolChecker.check_tool("rg")
          assert [true, false].include?(result)
        end

        def test_check_all_tools
          tools = ToolChecker.check_all_tools

          assert tools.key?(:ripgrep)
          assert tools.key?(:fd)
          assert tools.key?(:fzf)

          assert_includes [true, false], tools[:ripgrep][:available]
          assert_includes [true, false], tools[:fd][:available]
          assert_includes [true, false], tools[:fzf][:available]
          assert_equal false, tools[:fzf][:required]
        end

        def test_tool_version
          skip_unless_rg_available

          version = ToolChecker.tool_version("rg")
          refute_nil version
          assert_match(/\d+\.\d+/, version)
        end
      end
    end
  end
end
