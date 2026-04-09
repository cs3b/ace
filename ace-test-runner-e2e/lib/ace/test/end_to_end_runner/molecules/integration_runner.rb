# frozen_string_literal: true

require "fileutils"
require "open3"
require "rbconfig"
require "yaml"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Runs deterministic Minitest integration files inside the E2E sandbox.
        class IntegrationRunner
          INTEGRATION_TEST_ID = "INTEGRATION".freeze

          def initialize(base_dir: Dir.pwd, sandbox_builder: nil, config: nil)
            @base_dir = File.expand_path(base_dir)
            @config = config || ConfigLoader.load
            @sandbox_builder = sandbox_builder || PipelineSandboxBuilder.new(config_root: @base_dir)
          end

          def discover(package:)
            discoverer.find_integration_tests(package: package, base_dir: @base_dir)
          end

          def run(package:, run_id:, output: $stdout)
            files = discover(package: package)
            return skipped_result(package, run_id) if files.empty?

            started_at = Time.now
            sandbox_path = File.join(cache_dir, "#{run_id}-#{short_package(package)}-integration")
            report_dir = "#{sandbox_path}-reports"
            sandbox_package_root = File.join(sandbox_path, package)

            output.puts "Phase 1/2: sandboxed integration Minitest (#{files.size} file#{files.size == 1 ? "" : "s"})"

            env = @sandbox_builder.build(
              scenario: integration_scenario(package),
              sandbox_path: sandbox_path
            )

            FileUtils.mkdir_p(report_dir)

            relative_files = files.map { |path| relative_integration_path(path, package) }
            command = build_command(relative_files)
            merged_env = ENV.to_h.merge(env).merge("BUNDLE_GEMFILE" => File.join(@base_dir, "Gemfile"))

            stdout, stderr, status = Open3.capture3(merged_env, *command, chdir: sandbox_package_root)
            completed_at = Time.now

            write_report(
              report_dir: report_dir,
              package: package,
              run_id: run_id,
              files: relative_files,
              command: command,
              stdout: stdout,
              stderr: stderr,
              exitstatus: status.exitstatus,
              started_at: started_at,
              completed_at: completed_at
            )

            result = Models::TestResult.new(
              test_id: INTEGRATION_TEST_ID,
              status: status.success? ? "pass" : "fail",
              test_cases: [
                {
                  id: INTEGRATION_TEST_ID,
                  description: "Sandboxed deterministic integration suite",
                  status: status.success? ? "pass" : "fail",
                  notes: "#{files.size} file#{files.size == 1 ? "" : "s"}"
                }
              ],
              summary: status.success? ? "#{files.size} integration file(s) passed" : "#{files.size} integration file(s) failed",
              started_at: started_at,
              completed_at: completed_at,
              report_dir: report_dir,
              error: status.success? ? nil : stderr.to_s.strip
            )

            output.puts "Integration Result: #{result.status.upcase} (#{result.summary})"
            output.puts "Integration Report: #{report_dir}"

            result
          rescue => e
            completed_at = Time.now
            FileUtils.mkdir_p(report_dir) if report_dir
            File.write(File.join(report_dir, "error.log"), "#{e.class}: #{e.message}\n") if report_dir

            Models::TestResult.new(
              test_id: INTEGRATION_TEST_ID,
              status: "error",
              test_cases: [
                {
                  id: INTEGRATION_TEST_ID,
                  description: "Sandboxed deterministic integration suite",
                  status: "fail",
                  notes: e.message
                }
              ],
              summary: "Integration phase errored",
              started_at: started_at || Time.now,
              completed_at: completed_at,
              report_dir: report_dir,
              error: "#{e.class}: #{e.message}"
            )
          end

          private

          def discoverer
            @discoverer ||= TestDiscoverer.new(config: @config)
          end

          def cache_dir
            File.join(@base_dir, @config.dig("paths", "cache_dir") || ".ace-local/test-e2e")
          end

          def short_package(package)
            package.to_s.sub(/\Aace-/, "")
          end

          def integration_scenario(package)
            Models::TestScenario.new(
              test_id: INTEGRATION_TEST_ID,
              title: "Sandboxed integration phase",
              area: "integration",
              package: package,
              file_path: File.join(@base_dir, package, @config.dig("paths", "integration") || "test-e2e/integration"),
              content: ""
            )
          end

          def relative_integration_path(path, package)
            path.sub(%r{\A#{Regexp.escape(File.join(@base_dir, package))}/?}, "")
          end

          def build_command(relative_files)
            script = relative_files.map do |file|
              escaped = "./#{file}".gsub("'", "\\\\'")
              "begin; require '#{escaped}'; rescue LoadError => e; STDERR.puts(\"Failed to load #{escaped}: \" + e.message); exit(1); end"
            end.join("; ")

            [
              "bundle",
              "exec",
              RbConfig.ruby,
              "-Ilib:test",
              "-e",
              "#{script}; exit_code = Minitest.autorun; exit(exit_code)"
            ]
          end

          def write_report(report_dir:, package:, run_id:, files:, command:, stdout:, stderr:, exitstatus:, started_at:, completed_at:)
            File.write(File.join(report_dir, "stdout.log"), stdout.to_s)
            File.write(File.join(report_dir, "stderr.log"), stderr.to_s)
            File.write(File.join(report_dir, "command.txt"), command.join(" ") + "\n")
            File.write(
              File.join(report_dir, "metadata.yml"),
              YAML.dump(
                {
                  "phase" => "integration",
                  "package" => package,
                  "run-id" => run_id,
                  "status" => exitstatus.zero? ? "pass" : "fail",
                  "files" => files,
                  "started" => started_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
                  "completed" => completed_at.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
                  "exitstatus" => exitstatus
                }
              )
            )
          end

          def skipped_result(package, run_id)
            report_dir = File.join(cache_dir, "#{run_id}-#{short_package(package)}-integration-reports")
            Models::TestResult.new(
              test_id: INTEGRATION_TEST_ID,
              status: "skip",
              test_cases: [],
              summary: "No integration tests found",
              report_dir: report_dir
            )
          end
        end
      end
    end
  end
end
