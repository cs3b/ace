# frozen_string_literal: true

require "json"
require "open3"
require "test_helper"

module Ace
  module Herdr
    module CLI
      module Commands
        class TabTest < Minitest::Test
          # Loader stub serving the tab preset under test
          class StubLoader
            def load(type, name)
              {"tabs" => {"agent" => {"label" => "agent", "panes" => [{"label" => "agent"}]}}}[type][name]
            end

            def list(type)
              type == "tabs" ? %w[agent] : []
            end

            def to_lookup(type)
              ->(name) { load(type, name) }
            end
          end

          def setup
            @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
              tab_create: Molecules::ExecutionResult.new(
                stdout: JSON.generate(result: {tab: {tab_id: "w1:t9"}, root_pane: {pane_id: "w1:p9"}}),
                stderr: "", success: true, exit_code: 0
              )
            })
            @control = Organisms::ControlSurface.new(
              executor: @executor, preset_loader: StubLoader.new
            )
            @cmd = Tab.new(executor: @executor, control: @control)
          end

          def test_outputs_tab_payload_json
            out, = with_env("HERDR_WORKSPACE_ID" => "w1") do
              capture_io { @cmd.call(preset: "agent", workspace: nil, cwd: nil, quiet: nil) }
            end

            parsed = JSON.parse(out)
            assert_equal "w1:t9", parsed["tab"]
            assert_equal ["w1:p9"], parsed["panes"]
          end

          def test_passes_explicit_workspace
            capture_io do
              with_env("HERDR_WORKSPACE_ID" => "w1") do
                @cmd.call(preset: "agent", workspace: "w2", cwd: nil, quiet: true)
              end
            end

            call = @executor.calls_of(:tab_create).first
            assert_equal "w2", call[:args][:workspace_id]
          end

          def test_requires_preset_argument
            error = assert_raises(Ace::Support::Cli::Error) do
              @cmd.call(preset: nil, workspace: nil, cwd: nil, quiet: nil)
            end

            assert_match(/preset name is required/, error.message)
          end

          def test_materialization_failure_translates_to_a_cli_error
            failing = Class.new(Organisms::ControlSurface) do
              def create_tab(*)
                raise TabMaterializationError.new(
                  tab_id: "w1:t9",
                  message: "Runtime::Error: agent start failed after native create"
                )
              end
            end.new(executor: @executor, preset_loader: StubLoader.new)
            cmd = Tab.new(executor: @executor, control: failing)

            error = assert_raises(Ace::Support::Cli::Error) do
              with_env("HERDR_WORKSPACE_ID" => "w1") do
                capture_io { cmd.call(preset: "agent", workspace: nil, cwd: nil, quiet: nil) }
              end
            end

            assert_match(/agent start failed after native create/, error.message)
          end

          def test_materialization_failure_through_the_executable_is_a_standard_cli_error
            bin_dir = Dir.mktmpdir("herdr-fake-bin")
            work_dir = Dir.mktmpdir("herdr-subprocess")
            journal = File.join(work_dir, "journal.log")
            File.write(File.join(bin_dir, "herdr"), <<~FAKE)
              #!/usr/bin/env ruby
              require "json"
              File.open(ENV.fetch("HERDR_FAKE_JOURNAL"), "a") { |f| f.puts ARGV.join(" ") }
              if ARGV[0] == "tab" && ARGV[1] == "create"
                puts JSON.generate(result: {tab: {tab_id: "w1:t9"}, root_pane: {pane_id: "w1:p9"}})
              elsif ARGV[0] == "agent" && ARGV[1] == "start"
                warn JSON.generate(error: {code: "agent_start_failed", message: "agent start refused"})
                exit 1
              end
            FAKE
            FileUtils.chmod(0o755, File.join(bin_dir, "herdr"))

            pkg_libs = %w[ace-hitl-contract ace-runtime ace-support-cli ace-support-config ace-support-core]
              .map { |pkg| File.expand_path("../../../../#{pkg}/lib", __dir__) }
            env = {
              "PATH" => "#{bin_dir}#{File::PATH_SEPARATOR}#{ENV['PATH']}",
              "RUBYLIB" => [File.expand_path("../../../lib", __dir__), *pkg_libs].join(File::PATH_SEPARATOR),
              "RUBYOPT" => "",
              "HOME" => work_dir,
              "HERDR_FAKE_JOURNAL" => journal
            }
            exe = File.expand_path("../../../exe/ace-herdr", __dir__)
            stdout, stderr, status = Open3.capture3(env, Gem.ruby, exe, "tab", "agent", "--workspace", "w1",
              chdir: work_dir)

            # Standard CLI failure: nonzero, actionable message on stderr, no
            # success payload, and no ordinary-mode stack trace.
            refute status.success?
            assert_empty stdout.strip
            assert_match(/agent_start_failed/, stderr)
            refute stderr.include?(".rb:"), "expected no stack trace, got:\n#{stderr}"

            # The failed tab is never reported as success and no tab — native
            # or foreign — is closed through this entrypoint.
            assert_path_exists journal, "fake herdr journal missing (executable failed before first call)"
            calls = File.readlines(journal).map(&:strip)
            assert calls.any? { |line| line.start_with?("tab create") }
            assert_empty calls.grep(/\Atab close\b/)
          ensure
            [bin_dir, work_dir].each { |dir| FileUtils.remove_entry(dir) if dir }
          end
        end
      end
    end
  end
end
