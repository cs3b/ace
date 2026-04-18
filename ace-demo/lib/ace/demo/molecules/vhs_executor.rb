# frozen_string_literal: true

require "open3"
require "shellwords"

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
          stdout, stderr, status = Open3.capture3(browser_environment, *cmd, **options)
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

        private

        def browser_environment
          browser = resolve_browser_path
          return {} unless browser

          {
            "BROWSER" => browser,
            "CHROME_BIN" => browser,
            "CHROMIUM_BIN" => browser
          }
        end

        def resolve_browser_path
          %w[chromium google-chrome].each do |candidate|
            path = which(candidate)
            return path if path
          end

          nil
        end

        def which(command)
          stdout, _stderr, status = Open3.capture3("bash", "-lc", "command -v #{Shellwords.escape(command)}")
          return nil unless status.success?

          resolved = stdout.strip
          resolved.empty? ? nil : resolved
        rescue Errno::ENOENT
          nil
        end
      end
    end
  end
end
