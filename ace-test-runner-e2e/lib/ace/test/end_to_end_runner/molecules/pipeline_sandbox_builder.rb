# frozen_string_literal: true

require "fileutils"
require "open3"
require "yaml"
require "ace/test_support/sandbox_package_copy"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Builds deterministic sandbox state for standalone execution.
        class PipelineSandboxBuilder
          # @param config_root [String] Project root used for provider symlink/bin path
          def initialize(config_root: Dir.pwd, package_copy: nil, runtime_builder: nil, config: nil)
            @config_root = File.expand_path(config_root)
            @config = config || Molecules::ConfigLoader.load
            @package_copy = package_copy || Ace::TestSupport::SandboxPackageCopy.new(source_root: @config_root)
            @runtime_builder = runtime_builder || Molecules::SandboxRuntimeBuilder.new(
              source_root: @config_root,
              ruby_version: @config.dig("sandbox", "ruby_version") || Molecules::ConfigLoader.default_sandbox_ruby_version
            )
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
            package_copy_result = ensure_package_available(scenario.package, sandbox_path)
            sync_protocol_sources(sandbox_path)
            runtime_result = @runtime_builder.prepare(
              sandbox_root: sandbox_path,
              env: package_copy_result[:env],
              tool_names: scenario.requires.fetch("tools", [])
            )
            link_provider_configs(sandbox_path)
            create_result_directories(scenario, sandbox_path, test_cases: test_cases)
            run_default_bootstrap(scenario, sandbox_path, runtime_result[:env])
            verify_tool_access(scenario, sandbox_path, runtime_result[:env])

            runtime_result[:env]
          end

          # Prepare only the runner/verifier layout for a sandbox that was
          # already created by the deterministic setup path.
          #
          # This must not mutate tracked sandbox contents by copying packages,
          # syncing protocol sources, or replacing config directories with
          # symlinks after the scenario setup has already established git state.
          #
          # @param scenario [Models::TestScenario]
          # @param sandbox_path [String]
          # @param test_cases [Array<String>, nil] Optional TC filter
          # @return [Hash] Additional environment variables (none required)
          def prepare_existing_sandbox(scenario:, sandbox_path:, test_cases: nil)
            sandbox_path = File.expand_path(sandbox_path)
            FileUtils.mkdir_p(sandbox_path)
            FileUtils.mkdir_p(File.join(sandbox_path, ".ace-local", "e2e"))
            FileUtils.mkdir_p(File.join(sandbox_path, "reports"))
            create_result_directories(scenario, sandbox_path, test_cases: test_cases)
            {}
          end

          # Sync protocol source manifests and backing directories into a
          # prepared sandbox before deterministic setup runs.
          #
          # This is safe before setup because no scenario-owned git baseline has
          # been established yet. It is intentionally separate from
          # prepare_existing_sandbox so the post-setup pipeline path remains
          # non-mutating.
          #
          # @param sandbox_path [String]
          # @return [void]
          def sync_protocol_sources_into(sandbox_path)
            sync_protocol_sources(File.expand_path(sandbox_path))
          end

          private

          def ensure_package_available(package_name, sandbox_path)
            package_name = package_name.to_s.strip
            if package_name.empty?
              return {
                env: {
                  "PROJECT_ROOT_PATH" => sandbox_path,
                  "ACE_E2E_SOURCE_ROOT" => @config_root
                }
              }
            end

            @package_copy.prepare(package_name: package_name, sandbox_root: sandbox_path)
          end

          def initialize_git_repo(sandbox_path)
            return if Dir.exist?(File.join(sandbox_path, ".git"))

            _stdout, stderr, status = Open3.capture3("git", "init", "-b", "main", chdir: sandbox_path)
            return if status.success?

            raise "Sandbox git init failed: #{stderr}".strip
          end

          def sync_protocol_sources(sandbox_path)
            %w[skill wfi].each do |protocol|
              Dir.glob(File.join(@config_root, "*", ".ace-defaults", "nav", "protocols",
                "#{protocol}-sources", "*.yml")).sort.each do |manifest_path|
                sync_protocol_source_manifest(protocol, manifest_path, sandbox_path)
              end
            end
          end

          def sync_protocol_source_manifest(protocol, manifest_path, sandbox_path)
            source_data = YAML.safe_load_file(manifest_path) || {}
            relative_path = source_data.dig("config", "relative_path").to_s.strip
            return if relative_path.empty?

            package_root = File.expand_path("../../../../..", manifest_path)
            package_name = File.basename(package_root)
            target_package_root = File.join(sandbox_path, package_name)
            target_manifest_path = File.join(
              target_package_root,
              ".ace-defaults",
              "nav",
              "protocols",
              "#{protocol}-sources",
              File.basename(manifest_path)
            )
            source_dir = File.join(package_root, relative_path)
            target_dir = File.join(target_package_root, relative_path)

            FileUtils.mkdir_p(File.dirname(target_manifest_path))
            FileUtils.cp(manifest_path, target_manifest_path) unless File.exist?(target_manifest_path)
            return unless File.directory?(source_dir)
            return if File.exist?(target_dir)

            FileUtils.mkdir_p(File.dirname(target_dir))
            FileUtils.cp_r(source_dir, target_dir)
          rescue Psych::SyntaxError
            nil
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

            selected_positions.map { |idx| "results/tc/#{format("%02d", idx)}" }
          end

          def extract_result_dir_index(path)
            match = path.to_s.match(%r{results/tc/(\d{1,3})/?})
            match ? match[1].to_i : nil
          end

          def verify_tool_access(scenario, sandbox_path, env)
            tool = scenario.tool_under_test.to_s.strip
            return if tool.empty?

            _stdout, stderr, status = Open3.capture3(env, tool, "--help", chdir: sandbox_path)
            return if status.success?

            raise "Sandbox tool check failed for #{tool}: #{stderr}".strip
          end

          def run_default_bootstrap(scenario, sandbox_path, env)
            return unless scenario.sandbox_profile == "ace-default"

            stdout, stderr, status = Open3.capture3(
              env,
              "bash", "--noprofile", "--norc", "-c", "ace-config sync ace-llm-providers-cli && ace-handbook sync",
              chdir: sandbox_path
            )
            return if status.success?

            raise [
              "Default sandbox bootstrap failed for #{scenario.test_id}",
              stdout.to_s.strip,
              stderr.to_s.strip
            ].reject(&:empty?).join("\n")
          end
        end
      end
    end
  end
end
