# frozen_string_literal: true

require "fileutils"
require "open3"
require "shellwords"
require "ace/test_support/sandbox_package_copy"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Runs deterministic integration tests inside a sandboxed package copy.
        class IntegrationRunner
          def initialize(base_dir: Dir.pwd, package_copy: nil)
            @base_dir = File.expand_path(base_dir)
            @package_copy = package_copy || Ace::TestSupport::SandboxPackageCopy.new(source_root: @base_dir)
          end

          def run(package:, files:, timestamp:, output: $stdout)
            return nil if files.nil? || files.empty?

            started_at = Time.now
            sandbox_root = File.join(@base_dir, ".ace-local", "test-e2e", "#{timestamp}-#{package}-integration")
            FileUtils.mkdir_p(sandbox_root)

            package_copy_result = @package_copy.prepare(package_name: package, sandbox_root: sandbox_root)
            package_root = resolve_package_root(sandbox_root, package)
            env = package_copy_result[:env] || {}

            test_cases = files.map do |file|
              run_file(package_root, file, env, output)
            end

            status = if test_cases.any? { |tc| tc[:status] == "error" }
              "error"
            elsif test_cases.any? { |tc| tc[:status] == "fail" }
              "fail"
            else
              "pass"
            end

            Models::TestResult.new(
              test_id: "INTEGRATION",
              status: status,
              test_cases: test_cases,
              summary: integration_summary(status, test_cases),
              started_at: started_at,
              completed_at: Time.now,
              metadata: {
                phase: "integration",
                package: package,
                sandbox_root: sandbox_root
              }
            )
          end

          private

          def run_file(package_root, file, env, output)
            relative = file.sub(%r{\A#{Regexp.escape(@base_dir)}/?}, "")
            package_relative = relative.sub(%r{\A[^/]+/}, "")

            stdout, stderr, status = Open3.capture3(
              env,
              "ace-test",
              package_relative,
              chdir: package_root
            )

            output.puts "Integration: #{package_relative} (#{status.success? ? "pass" : "fail"})"

            {
              id: package_relative,
              description: package_relative,
              status: status.success? ? "pass" : "fail",
              actual: stdout,
              notes: stderr,
              metadata: {
                phase: "integration",
                exit_status: status.exitstatus,
                command: Shellwords.join(["ace-test", package_relative])
              }
            }
          rescue StandardError => e
            output.puts "Integration: #{package_relative} (error)"

            {
              id: package_relative,
              description: package_relative,
              status: "error",
              actual: "",
              notes: e.message,
              metadata: {
                phase: "integration",
                command: Shellwords.join(["ace-test", package_relative])
              }
            }
          end

          def resolve_package_root(sandbox_root, package)
            candidate = File.join(sandbox_root, package)
            return candidate if Dir.exist?(candidate)

            sandbox_root
          end

          def integration_summary(status, test_cases)
            passed = test_cases.count { |tc| tc[:status] == "pass" }
            total = test_cases.size
            prefix =
              case status
              when "pass" then "Integration passed"
              when "fail" then "Integration failed"
              else "Integration errored"
              end
            "#{prefix}: #{passed}/#{total} files passed"
          end
        end
      end
    end
  end
end
