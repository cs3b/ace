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

          def discover(package:, test_id: nil)
            discoverer.find_integration_tests(package: package, test_id: test_id, base_dir: @base_dir)
          end

          def run(package:, run_id:, output: $stdout, test_id: nil)
            files = discover(package: package, test_id: test_id)
            return skipped_result(package, run_id) if files.empty?

            started_at = Time.now
            report_dir = nil
            output.puts "Phase 1/2: sandboxed integration Minitest (#{files.size} file#{files.size == 1 ? "" : "s"})"
            file_results = files.each_with_index.map do |file, index|
              run_file(package: package, file: file, run_id: run_id, index: index, output: output)
            end
            completed_at = file_results.map { |result| result[:completed_at] }.max || Time.now
            test_cases = file_results.flat_map { |result| result[:test_cases] }
            files_passed = file_results.count { |result| result[:status] == "pass" }
            total_cases = test_cases.size
            passed_cases = test_cases.count { |test_case| test_case[:status] == "pass" }
            failed_files = file_results.reject { |result| result[:status] == "pass" }

            result = Models::TestResult.new(
              test_id: INTEGRATION_TEST_ID,
              status: failed_files.empty? ? "pass" : "fail",
              test_cases: test_cases,
              summary: "#{files_passed}/#{file_results.size} file(s) passed, #{passed_cases}/#{total_cases} case(s) passed",
              started_at: started_at,
              completed_at: completed_at,
              report_dir: file_results.first&.dig(:report_dir),
              error: failed_files.empty? ? nil : failed_files.map { |result_hash| format_failure(result_hash) }.join("\n"),
              metadata: {
                "kind" => "integration",
                "package" => package,
                "files_total" => file_results.size,
                "files_passed" => files_passed,
                "total_cases" => total_cases,
                "passed_cases" => passed_cases,
                "file_results" => file_results.map do |result_hash|
                  {
                    "file" => result_hash[:file],
                    "status" => result_hash[:status],
                    "report_dir" => result_hash[:report_dir],
                    "tcs_total" => result_hash[:test_cases].size,
                    "tcs_passed" => result_hash[:test_cases].count { |test_case| test_case[:status] == "pass" }
                  }
                end
              }
            )

            output.puts "Integration Result: #{result.status.upcase} (#{result.summary})"

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
              error: "#{e.class}: #{e.message}",
              metadata: {
                "kind" => "integration",
                "package" => package,
                "files_total" => 0,
                "files_passed" => 0,
                "total_cases" => 0,
                "passed_cases" => 0,
                "file_results" => []
              }
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

          def run_file(package:, file:, run_id:, index:, output:)
            relative_file = relative_integration_path(file, package)
            file_id = File.basename(file, ".rb")
            started_at = Time.now
            sandbox_path = File.join(cache_dir, "#{run_id}-#{short_package(package)}-#{format("%02d", index + 1)}-#{file_id}")
            report_dir = "#{sandbox_path}-reports"
            sandbox_package_root = File.join(sandbox_path, package)
            env = @sandbox_builder.build(
              scenario: integration_scenario(package),
              sandbox_path: sandbox_path
            )

            FileUtils.mkdir_p(report_dir)
            command = build_command(relative_file)
            merged_env = ENV.to_h.merge(env).merge("BUNDLE_GEMFILE" => File.join(@base_dir, "Gemfile"))
            stdout, stderr, status = Open3.capture3(merged_env, *command, chdir: sandbox_package_root)
            completed_at = Time.now
            test_cases = parse_test_cases(relative_file, stdout, status, stderr)
            file_status = determine_file_status(status, test_cases)

            write_report(
              report_dir: report_dir,
              package: package,
              run_id: run_id,
              files: [relative_file],
              command: command,
              stdout: stdout,
              stderr: stderr,
              exitstatus: status.exitstatus,
              started_at: started_at,
              completed_at: completed_at,
              test_cases: test_cases
            )

            passed_cases = test_cases.count { |test_case| test_case[:status] == "pass" }
            output.puts "  #{package}/#{File.basename(relative_file)}: #{file_status.upcase} (#{passed_cases}/#{test_cases.size} cases)"
            output.puts "    Report: #{report_dir}"

            {
              file: relative_file,
              report_dir: report_dir,
              status: file_status,
              started_at: started_at,
              completed_at: completed_at,
              test_cases: test_cases,
              error: status.success? ? nil : stderr.to_s.strip
            }
          end

          def build_command(relative_file)
            [
              "bundle",
              "exec",
              RbConfig.ruby,
              "-Ilib:test",
              "./#{relative_file}",
              "--verbose"
            ]
          end

          def parse_test_cases(relative_file, stdout, status, stderr)
            cases = stdout.to_s.each_line.filter_map do |line|
              match = line.match(/^[^#]+#(?<name>test_[A-Za-z0-9_]+)\s*=.*=\s*(?<status>[\.FS])$/)
              next unless match

              method_name = match[:name]
              {
                id: extract_case_id(method_name) || method_name,
                description: "#{File.basename(relative_file)}##{method_name}",
                status: status_from_symbol(match[:status]),
                notes: nil
              }
            end

            return cases unless cases.empty?

            [
              {
                id: File.basename(relative_file, ".rb"),
                description: "#{File.basename(relative_file)} integration file",
                status: status.success? ? "pass" : "fail",
                notes: stderr.to_s.lines.first.to_s.strip
              }
            ]
          end

          def extract_case_id(method_name)
            match = method_name.to_s.match(/tc[_-](\d{3})/i)
            "TC-#{match[1]}" if match
          end

          def status_from_symbol(symbol)
            case symbol
            when "."
              "pass"
            when "S"
              "skip"
            else
              "fail"
            end
          end

          def determine_file_status(status, test_cases)
            return "error" if !status.success? && test_cases.empty?
            return "fail" if test_cases.any? { |test_case| test_case[:status] == "fail" }

            status.success? ? "pass" : "fail"
          end

          def format_failure(result_hash)
            "#{result_hash[:file]}: #{result_hash[:error].to_s.lines.first.to_s.strip}"
          end

          def write_report(report_dir:, package:, run_id:, files:, command:, stdout:, stderr:, exitstatus:, started_at:, completed_at:, test_cases:)
            File.write(File.join(report_dir, "stdout.log"), stdout.to_s)
            File.write(File.join(report_dir, "stderr.log"), stderr.to_s)
            File.write(File.join(report_dir, "command.txt"), command.join(" ") + "\n")
            File.write(File.join(report_dir, "results.yml"), YAML.dump(test_cases.map { |row| row.transform_keys(&:to_s) }))
            File.write(
              File.join(report_dir, "metadata.yml"),
              YAML.dump(
                {
                  "phase" => "integration",
                  "package" => package,
                  "run-id" => run_id,
                  "status" => exitstatus.zero? ? "pass" : "fail",
                  "files" => files,
                  "tcs-total" => test_cases.size,
                  "tcs-passed" => test_cases.count { |test_case| test_case[:status] == "pass" },
                  "failed_test_cases" => test_cases.select { |test_case| test_case[:status] == "fail" }.map { |test_case| test_case[:id] },
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
              report_dir: report_dir,
              metadata: {
                "kind" => "integration",
                "package" => package,
                "files_total" => 0,
                "files_passed" => 0,
                "total_cases" => 0,
                "passed_cases" => 0,
                "file_results" => []
              }
            )
          end
        end
      end
    end
  end
end
