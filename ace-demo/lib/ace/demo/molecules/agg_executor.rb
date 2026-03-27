# frozen_string_literal: true

require "open3"

module Ace
  module Demo
    module Molecules
      class AggExecutor
        INSTALL_URL = "https://github.com/asciinema/agg"

        def agg_available?(agg_bin: "agg")
          _stdout, _stderr, status = Open3.capture3(agg_bin, "--version")
          status.success?
        rescue Errno::ENOENT
          false
        end

        def run(cmd, agg_bin: "agg", chdir: nil)
          effective_bin = cmd.first || agg_bin
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

          raise AggExecutionError, "Agg execution failed: #{result.stderr}"
        rescue Errno::ENOENT
          raise AggNotFoundError, "Agg not found (#{effective_bin}). Install: #{INSTALL_URL}"
        end
      end
    end
  end
end
