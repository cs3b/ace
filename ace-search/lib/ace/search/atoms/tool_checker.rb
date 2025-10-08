# frozen_string_literal: true

require "open3"

module Ace
  module Search
    module Atoms
      # ToolChecker verifies availability of external tools (rg, fd, fzf)
      # This is an atom - pure function for tool availability checking
      module ToolChecker
        module_function

        # Check if ripgrep is available
        def ripgrep_available?
          check_tool("rg")
        end

        # Check if fd is available
        def fd_available?
          check_tool("fd")
        end

        # Check if fzf is available
        def fzf_available?
          check_tool("fzf")
        end

        # Check if a tool is available in PATH
        def check_tool(tool_name)
          stdout, _stderr, status = Open3.capture3("which #{tool_name}")
          status.success? && !stdout.strip.empty?
        rescue
          false
        end

        # Get tool version
        def tool_version(tool_name)
          stdout, _stderr, status = Open3.capture3("#{tool_name} --version")
          return nil unless status.success?

          # Extract version number from output
          version_match = stdout.match(/([\d.]+)/)
          version_match ? version_match[1] : nil
        rescue
          nil
        end

        # Check all required tools and return status
        def check_all_tools
          {
            ripgrep: {
              available: ripgrep_available?,
              version: ripgrep_available? ? tool_version("rg") : nil
            },
            fd: {
              available: fd_available?,
              version: fd_available? ? tool_version("fd") : nil
            },
            fzf: {
              available: fzf_available?,
              version: fzf_available? ? tool_version("fzf") : nil,
              required: false
            }
          }
        end
      end
    end
  end
end
