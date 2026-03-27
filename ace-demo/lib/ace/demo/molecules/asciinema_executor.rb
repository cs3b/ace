# frozen_string_literal: true

require "open3"

module Ace
  module Demo
    module Molecules
      class AsciinemaExecutor
        INSTALL_URL = "https://docs.asciinema.org/getting-started/"

        def asciinema_available?(asciinema_bin: "asciinema")
          _stdout, _stderr, status = Open3.capture3(asciinema_bin, "--version")
          status.success?
        rescue Errno::ENOENT
          false
        end

        def run(cmd, asciinema_bin: "asciinema", chdir: nil)
          effective_bin = cmd.first || asciinema_bin
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

          raise AsciinemaExecutionError, "Asciinema execution failed: #{result.stderr}"
        rescue Errno::ENOENT
          raise AsciinemaNotFoundError, "Asciinema not found (#{effective_bin}). Install: #{INSTALL_URL}"
        end
      end
    end
  end
end
