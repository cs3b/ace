# frozen_string_literal: true

require "fileutils"
require "open3"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Builds deterministic sandbox state for standalone execution.
        class PipelineSandboxBuilder
          # @param config_root [String] Project root used for provider symlink/bin path
          def initialize(config_root: Dir.pwd)
            @config_root = File.expand_path(config_root)
          end

          # @param scenario [Models::TestScenario]
          # @param sandbox_path [String]
          # @param test_cases [Array<String>, nil] Optional TC filter
          # @return [Hash] Environment variables for subprocess execution
          def build(scenario:, sandbox_path:, test_cases: nil)
            sandbox_path = File.expand_path(sandbox_path)
            FileUtils.mkdir_p(sandbox_path)
            FileUtils.mkdir_p(File.join(sandbox_path, ".ace-local", "e2e"))
            FileUtils.mkdir_p(File.join(sandbox_path, "reports"))

            initialize_git_repo(sandbox_path)
            ensure_package_available(scenario.package, sandbox_path)
            link_provider_configs(sandbox_path)
            create_result_directories(scenario, sandbox_path, test_cases: test_cases)
            verify_tool_access(scenario, sandbox_path)

            {
              "PROJECT_ROOT_PATH" => sandbox_path
            }
          end

          private

          def ensure_package_available(package_name, sandbox_path)
            package_name = package_name.to_s.strip
            return if package_name.empty?

            package_source = File.join(@config_root, package_name)
            package_target = File.join(sandbox_path, package_name)

            return if File.exist?(package_target)

            unless File.directory?(package_source)
              raise "Scenario package not found: #{package_name} (expected #{package_source})"
            end

            FileUtils.cp_r(package_source, package_target)
          end

          def initialize_git_repo(sandbox_path)
            return if Dir.exist?(File.join(sandbox_path, ".git"))

            _stdout, stderr, status = Open3.capture3("git", "init", "-b", "main", chdir: sandbox_path)
            return if status.success?

            raise "Sandbox git init failed: #{stderr}".strip
          end

          def link_provider_configs(sandbox_path)
            source = File.join(@config_root, ".ace", "llm", "providers")
            target = File.join(sandbox_path, ".ace", "llm", "providers")
            FileUtils.mkdir_p(File.dirname(target))

            FileUtils.rm_f(target) if File.symlink?(target)
            FileUtils.rm_rf(target) if File.directory?(target)

            if File.directory?(source)
              File.symlink(source, target)
            else
              FileUtils.mkdir_p(target)
            end
          end

          def create_result_directories(scenario, sandbox_path, test_cases:)
            result_dirs = resolve_result_dirs(scenario, test_cases: test_cases)
            result_dirs.each do |relative_dir|
              FileUtils.mkdir_p(File.join(sandbox_path, relative_dir))
            end
          end

          def resolve_result_dirs(scenario, test_cases:)
            all_cases = scenario.test_cases || []
            case_positions = all_cases.each_with_index.to_h do |tc, idx|
              [tc.tc_id.to_s.upcase, idx + 1]
            end

            selected_positions = if test_cases && !test_cases.empty?
              test_cases.filter_map { |tc_id| case_positions[tc_id.to_s.upcase] }.uniq.sort
            else
              case_positions.values.sort
            end

            selected_positions = (1..all_cases.size).to_a if selected_positions.empty? && !all_cases.empty?

            layout_keys = (scenario.sandbox_layout || {}).keys
            if layout_keys.any?
              selected_from_layout = layout_keys.select do |key|
                idx = extract_result_dir_index(key)
                idx.nil? || selected_positions.include?(idx)
              end
              return selected_from_layout unless selected_from_layout.empty?
            end

            selected_positions.map { |idx| "results/tc/#{format('%02d', idx)}" }
          end

          def extract_result_dir_index(path)
            match = path.to_s.match(%r{results/tc/(\d{1,3})/?})
            match ? match[1].to_i : nil
          end

          def verify_tool_access(scenario, sandbox_path)
            tool = scenario.tool_under_test.to_s.strip
            return if tool.empty?

            _stdout, stderr, status = Open3.capture3(tool, "--help", chdir: sandbox_path)
            return if status.success?

            raise "Sandbox tool check failed for #{tool}: #{stderr}".strip
          end
        end
      end
    end
  end
end
