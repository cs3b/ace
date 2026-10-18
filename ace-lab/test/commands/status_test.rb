# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    module CLI
      module Commands
        class StatusCommandTest < Minitest::Test
          def build_status(dir)
            Organisms::Status.new(
              project_dir: dir,
              documents: [{path: File.join(dir, ".ace/lab/config.yml"), document: {}, defaults: false}],
              config: {"schema_version" => 1, "topology" => {
                "projects" => [{"id" => "atlas"}],
                "agents" => [{"id" => "a1", "project" => "atlas", "role" => "worker",
                  "capabilities" => ["work"], "binding" => {"kind" => "runtime"}}],
                "services" => [{"id" => "s1", "project" => "atlas", "capabilities" => ["search"],
                  "endpoint" => {"kind" => "http", "url" => "https://s1.example/internal"},
                  "binding" => {"kind" => "service"}}]
              }}
            )
          end

          def with_project_dir
            Dir.mktmpdir("lab-status-cmd") do |dir|
              FileUtils.mkdir_p(File.join(dir, ".ace-tasks"))
              FileUtils.mkdir_p(File.join(dir, ".ace-local", "hitl"))
              FileUtils.touch(File.join(dir, ".ace-tasks", "one.md"))
              yield dir
            end
          end

          def test_table_renders_configuration_state_files_and_pointer
            with_project_dir do |dir|
              cmd = Status.new(status: build_status(dir))

              out, = capture_io do
                cmd.call(format: nil, quiet: nil)
              end

              assert_includes out, "Lab configuration: configured"
              assert_includes out, "projects: 1"
              assert_includes out, "Local state:"
              assert_includes out, ".ace-tasks"
              assert_includes out, "present (1 entries)"
              assert_includes out, "not present (coworker start/status is planned (L3))"
              assert_includes out, "Worktree view: run `ace-git-worktree list`"
            end
          end

          def test_json_output_matches_schema
            with_project_dir do |dir|
              cmd = Status.new(status: build_status(dir))

              out, = capture_io do
                cmd.call(format: "json", quiet: nil)
              end

              parsed = JSON.parse(out)
              assert_equal "configured", parsed.dig("configuration", "state")
              assert parsed["state_files"].all? { |e| e.key?("present") }
              assert_equal "ace-git-worktree list", parsed["worktree_view"]
            end
          end

          def test_not_configured_renders_marker_not_ready_lab
            with_project_dir do |dir|
              status = Organisms::Status.new(project_dir: dir,
                documents: [{path: File.join(Ace::Lab.gem_root, ".ace-defaults/lab/config.yml"),
                             document: {}, defaults: true}])
              cmd = Status.new(status: status)

              out, = capture_io do
                cmd.call(format: nil, quiet: nil)
              end

              assert_includes out, "Lab configuration: not configured"
              assert_includes out, "no .ace/lab/config.yml"
            end
          end

          def test_quiet_prints_nothing
            with_project_dir do |dir|
              cmd = Status.new(status: build_status(dir))

              out, = capture_io do
                cmd.call(format: nil, quiet: true)
              end

              assert_equal "", out
            end
          end

          def test_invalid_format_is_a_usage_error
            with_project_dir do |dir|
              cmd = Status.new(status: build_status(dir))

              error = assert_raises(Ace::Support::Cli::Error) do
                cmd.call(format: "yaml", quiet: nil)
              end
              assert_includes error.message, "table or json"
            end
          end
        end
      end
    end
  end
end
