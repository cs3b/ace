# frozen_string_literal: true

require "ace/support/cli/toolchain"

require "open3"
require "json"

module Ace
  module Coworker
    module Molecules
      # Probes assignment truth via `ace-assign status --assignment <id> --format json`
      # with an injectable runner (ADR-031: argv array + explicit cwd).
      class AssignmentProbe
        DEFAULT_RUNNER = ->(argv, cwd) { Open3.capture3(Ace::Support::Cli::Toolchain.child_environment, *argv, chdir: cwd) }

        def initialize(project_root:, runner: DEFAULT_RUNNER)
          @project_root = project_root
          @runner = runner
        end

        # @return [Models::AssignmentSnapshot]
        # @raise [Error] when the assignment is unknown or status cannot be read
        def snapshot(assignment_id)
          argv = [assign_binary, "status", "--assignment", assignment_id.to_s, "--format", "json"]
          begin
            out, err, status = run(argv)
          rescue Errno::ENOENT
            raise Error, "required CLI '#{assign_binary}' not found; install the ace-assign gem"
          end
          unless status.success?
            message = err.to_s.strip.empty? ? out.to_s.strip : err.to_s.strip
            raise Error, "cannot read assignment '#{assignment_id}': #{message}"
          end

          begin
            payload = JSON.parse(out)
          rescue JSON::ParserError => e
            raise Error, "cannot parse ace-assign status for '#{assignment_id}': #{e.message}"
          end

          Models::AssignmentSnapshot.from_status_json(payload)
        end

        private

        def run(argv)
          @runner.call(argv, @project_root)
        end

        # Prefer the repo binstub when present (agent shells do not activate
        # mise, so bare ace-* may resolve to stale installed gems).
        def assign_binary
          return Ace::Support::Cli::Toolchain.executable("ace-assign") if Ace::Support::Cli::Toolchain.installed?

          binstub = File.join(@project_root, "bin", "ace-assign")
          File.executable?(binstub) ? binstub : "ace-assign"
        end
      end
    end
  end
end
