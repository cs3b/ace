# frozen_string_literal: true

require "open3"

module Ace
  module Demo
    module Molecules
      class VhsExecutor
        INSTALL_URL = "https://github.com/charmbracelet/vhs"

        def vhs_available?(vhs_bin: "vhs")
          _stdout, _stderr, status = Open3.capture3(vhs_bin, "--version")
          status.success?
        rescue Errno::ENOENT
          false
        end

        def run(cmd, vhs_bin: "vhs", chdir: nil)
          options = {}
          options[:chdir] = chdir if chdir
          stdout, stderr, status = Open3.capture3(*cmd, **options)
          result = Models::ExecutionResult.new(
            stdout: stdout.strip,
            stderr: stderr.strip,
            success: status.success?,
            exit_code: status.exitstatus
          )

          return result if result.success?

          raise VhsExecutionError, "VHS execution failed: #{result.stderr}"
        rescue Errno::ENOENT
          raise VhsNotFoundError, "VHS not found. Install: #{INSTALL_URL}"
        end
      end
    end
  end
end
