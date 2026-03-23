# frozen_string_literal: true

require "fileutils"
require "open3"

module Ace
  module Demo
    module Molecules
      class DemoTeardownExecutor
        VALID_TEARDOWN_DIRECTIVES = ["cleanup", "run:"].freeze

        def execute(steps:, sandbox_path:)
          return if steps.nil?

          steps.each do |step|
            execute_teardown_step(step, sandbox_path: sandbox_path)
          end
        end

        private

        def execute_teardown_step(step, sandbox_path:)
          case step
          when "cleanup"
            FileUtils.rm_rf(sandbox_path)
          when Hash
            run = step["run"] || step[:run]
            unless run
              raise ArgumentError,
                "Unknown teardown directive #{step.inspect}. Valid: #{VALID_TEARDOWN_DIRECTIVES.join(", ")}"
            end
            run_shell(run.to_s, chdir: sandbox_path)
          else
            raise ArgumentError,
              "Unknown teardown directive #{step.inspect}. Valid: #{VALID_TEARDOWN_DIRECTIVES.join(", ")}"
          end
        end

        def run_shell(command, chdir:)
          _stdout, stderr, status = Open3.capture3("bash", "-lc", command, chdir: chdir)
          return if status.success?

          raise "Teardown command failed (exit #{status.exitstatus}): #{command}\n#{stderr}"
        end
      end
    end
  end
end
