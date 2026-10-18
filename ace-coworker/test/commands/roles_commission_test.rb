# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"
require "json"

module Ace
  module Coworker
    module CLI
      module Commands
        class RolesCommissionTest < AceCoworkerTestCase
          def setup
            super
            @dir = Dir.mktmpdir("coworker-commands")
            CoworkerFixture.build_task(@dir, id: "8xh.t.ddd")
            CoworkerFixture.build_assignment(@dir, id: "asg09", task_id: "8xh.t.ddd")

            @gem_roles = File.join(@dir, "gem-roles")
            FileUtils.mkdir_p(@gem_roles)
            File.write(File.join(@gem_roles, "worker.yml"), <<~YAML)
              ---
              name: worker
              description: Fixture worker
              instructions: wfi://coworker/worker
              start_prompt: "Drive {{assignment}} for {{task}}."
            YAML
            File.write(File.join(@gem_roles, "spec.yml"), <<~YAML)
              ---
              name: spec
              description: Fixture spec
              instructions: wfi://coworker/spec
              start_prompt: "Specify {{task}}."
            YAML
            File.write(File.join(@gem_roles, "reviewer.yml"), <<~YAML)
              ---
              name: reviewer
              description: Fixture reviewer
              instructions: wfi://coworker/reviewer
              start_prompt: "Review {{assignment}} on {{task}} as {{role}} for {{overseer}}."
              reporting:
                channel: hitl
              errors:
                on_failure: report
            YAML
            @loader = Molecules::RolePresetLoader.new(project_root: @dir, gem_roles_dir: @gem_roles)
          end

          def teardown
            FileUtils.remove_entry(@dir)
            Ace::Coworker.reset_config!
          end

          def test_roles_table_lists_presets_with_sources
            out, = capture_io do
              Roles.new(preset_loader: @loader).call(format: "table")
            end
            assert_includes out, "Coworker roles:"
            assert_includes out, "spec       gem      Fixture spec"
            assert_includes out, "worker     gem      Fixture worker"
            assert_includes out, "reviewer   gem      Fixture reviewer"
            assert_includes out, "instructions: wfi://coworker/worker"
          end

          def test_roles_json_is_machine_readable
            out, = capture_io do
              Roles.new(preset_loader: @loader).call(format: "json")
            end
            payload = JSON.parse(out)
            assert_equal %w[reviewer spec worker], payload["roles"].map { |r| r["name"] }
            assert_equal "gem", payload["roles"].first["source"]
          end

          def test_roles_empty_catalog_renders_explicit_empty_state
            empty_dir = File.join(@dir, "empty")
            FileUtils.mkdir_p(empty_dir)
            empty_loader = Molecules::RolePresetLoader.new(project_root: @dir, gem_roles_dir: empty_dir)
            out, = capture_io do
              Roles.new(preset_loader: empty_loader).call(format: "table")
            end
            assert_includes out, "Coworker roles: none found"
          end

          def test_roles_invalid_preset_file_fails_with_specific_cli_error
            File.write(File.join(@gem_roles, "broken.yml"), <<~YAML)
              ---
              description: no identity
            YAML
            error = assert_raises(Ace::Support::Cli::Error) do
              Roles.new(preset_loader: @loader).call(format: "table")
            end
            assert_includes error.message, "invalid role preset"
            assert_includes error.message, "broken.yml"
            assert_includes error.message, "missing required field 'name'"
          end

          def commission_command
            Commission.new(orchestrator: Organisms::CommissionOrchestrator.new(
              project_root: @dir,
              preset_loader: @loader,
              task_probe: Molecules::TaskProbe.new(project_root: @dir),
              assignment_metadata: Molecules::AssignmentMetadata.new(project_root: @dir),
              config_path: ".ace-local/coworker/config.yml"
            ))
          end

          def test_commission_writes_config_and_renders_table
            out, = capture_io do
              commission_command.call(role: "worker", task: "8xh.t.ddd", assignment: "asg09",
                overseer: "overseer@lab", format: "table", force: false, dry_run: false)
            end
            assert_includes out, "Coworker commission"
            assert_includes out, "role:          worker (preset source: gem)"
            assert_includes out, "result:        written"
            assert_includes out, "config_path:   .ace-local/coworker/config.yml"
            config = Molecules::ConfigLoader.new(project_root: @dir).load
            assert_equal "worker", config.role
            assert_equal "Drive asg09 for 8xh.t.ddd.", config.start_prompt
          end

          def test_commission_json_output_is_machine_readable
            out, = capture_io do
              commission_command.call(role: "spec", task: "8xh.t.ddd", assignment: "asg09",
                overseer: "overseer@lab", format: "json", force: false, dry_run: false)
            end
            payload = JSON.parse(out)
            assert_equal "spec", payload["role"]
            assert payload["written"]
            assert_equal "wfi://coworker/spec", payload["config"]["instructions"]
          end

          def test_commission_dry_run_writes_nothing
            out, = capture_io do
              commission_command.call(role: "worker", task: "8xh.t.ddd", assignment: "asg09",
                overseer: "overseer@lab", format: "table", force: false, :"dry-run" => true)
            end
            assert_includes out, "resolved (dry-run, nothing written)"
            refute File.exist?(File.join(@dir, ".ace-local", "coworker", "config.yml"))
          end

          def test_commission_refused_overwrite_and_unknown_role_surface_as_cli_errors
            commission_command.call(role: "worker", task: "8xh.t.ddd", assignment: "asg09",
              overseer: "overseer@lab", format: "table", force: false, dry_run: false)
            error = assert_raises(Ace::Support::Cli::Error) do
              commission_command.call(role: "worker", task: "8xh.t.ddd", assignment: "asg09",
                overseer: "overseer@lab", format: "table", force: false, dry_run: false)
            end
            assert_includes error.message, "refusing to overwrite"

            error = assert_raises(Ace::Support::Cli::Error) do
              commission_command.call(role: "ghost", task: "8xh.t.ddd", assignment: "asg09",
                overseer: "overseer@lab", format: "table", force: false, dry_run: false)
            end
            assert_includes error.message, "unknown role 'ghost'"
          end

          def test_commission_requires_all_identity_flags
            error = assert_raises(Ace::Support::Cli::Error) do
              commission_command.call(role: "worker", task: "", assignment: "", overseer: "",
                format: "table", force: false, dry_run: false)
            end
            assert_includes error.message, "--task, --assignment, --overseer are required"
          end

          def test_commission_reviewer_dry_run_renders_substituted_config_without_writing
            out, = capture_io do
              commission_command.call(role: "reviewer", task: "8xh.t.ddd", assignment: "asg09",
                overseer: "overseer@lab", format: "json", force: false, :"dry-run" => true)
            end
            payload = JSON.parse(out)
            assert_equal "reviewer", payload["role"]
            assert_equal "gem", payload["preset_source"]
            refute payload["written"]
            config = payload["config"]
            assert_equal "wfi://coworker/reviewer", config["instructions"]
            assert_equal "Review asg09 on 8xh.t.ddd as reviewer for overseer@lab.", config["start_prompt"]
            refute config["start_prompt"].include?("{{")
            assert_equal({"channel" => "hitl"}, config["reporting"])
            assert_equal({"on_failure" => "report"}, config["errors"])
            refute File.exist?(File.join(@dir, ".ace-local", "coworker", "config.yml"))
          end
        end
      end
    end
  end
end
