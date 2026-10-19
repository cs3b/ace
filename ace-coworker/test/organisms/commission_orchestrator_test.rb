# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"

module Ace
  module Coworker
    module Organisms
      class CommissionOrchestratorTest < AceCoworkerTestCase
        FakePresetLoader = Struct.new(:presets) do
          def self.of(presets)
            new(presets)
          end

          def list
            presets.values.sort_by { |p| p["name"] }
          end

          def fetch(name)
            preset = presets[name]
            raise Error, "unknown role '#{name}' (available: #{presets.keys.sort.join(', ')})" if preset.nil?

            preset
          end
        end

        def setup
          super
          @dir = Dir.mktmpdir("coworker-commission")
          CoworkerFixture.build_task(@dir, id: "8xh.t.ccc")
          CoworkerFixture.build_assignment(@dir, id: "asg01", task_id: "8xh.t.ccc")
          @loader = FakePresetLoader.of(
            "worker" => {
              "name" => "worker", "description" => "Worker", "source" => "gem",
              "instructions" => "wfi://coworker/worker",
              "start_prompt" => "Work as {{role}} on {{task}} via {{assignment}}, overseen by {{overseer}}.",
              "reporting" => "hitl", "errors" => "report"
            }
          )
        end

        def teardown
          FileUtils.remove_entry(@dir)
        end

        def orchestrator(config_path: nil)
          CommissionOrchestrator.new(
            project_root: @dir,
            preset_loader: @loader,
            task_probe: Molecules::TaskProbe.new(project_root: @dir),
            assignment_metadata: Molecules::AssignmentMetadata.new(project_root: @dir),
            config_path: config_path
          )
        end

        def test_happy_path_writes_start_grade_config
          result = orchestrator.call(role: "worker", task: "8xh.t.ccc", assignment: "asg01",
            overseer: "overseer@lab")

          expected_path = File.join(@dir, ".ace-local", "coworker", "config.yml")
          assert_equal expected_path, File.join(@dir, result.config_path)
          assert result.written
          assert_equal "gem", result.preset_source

          # Round trip: the written config passes the same validation `start` runs.
          config = Molecules::ConfigLoader.new(project_root: @dir).load
          assert_equal "worker", config.role
          assert_equal "wfi://coworker/worker", config.instructions
          assert_equal "8xh.t.ccc", config.task
          assert_equal "asg01", config.assignment
          assert_equal "overseer@lab", config.overseer
          assert_equal "hitl", config.reporting_channel
          assert_equal "report", config.on_failure
          assert_equal "Work as worker on 8xh.t.ccc via asg01, overseen by overseer@lab.",
            config.start_prompt
          assert_empty Dir.glob(File.join(@dir, ".ace-local", "coworker", ".commission*"))
        end

        def test_start_prompt_option_overrides_the_preset_template
          orchestrator.call(role: "worker", task: "8xh.t.ccc", assignment: "asg01",
            overseer: "overseer@lab", start_prompt: "Custom literal prompt.")
          config = Molecules::ConfigLoader.new(project_root: @dir).load
          assert_equal "Custom literal prompt.", config.start_prompt
        end

        def test_dry_run_writes_nothing_but_resolves_the_config
          result = orchestrator.call(role: "worker", task: "8xh.t.ccc", assignment: "asg01",
            overseer: "overseer@lab", dry_run: true)
          refute File.exist?(File.join(@dir, ".ace-local", "coworker", "config.yml"))
          refute result.written
          assert result.dry_run
          assert_equal "wfi://coworker/worker", result.config["instructions"]
          assert_includes result.config["start_prompt"], "asg01"
        end

        def test_overwrite_is_refused_without_force_and_allowed_with_it
          orchestrator.call(role: "worker", task: "8xh.t.ccc", assignment: "asg01", overseer: "o@lab")
          error = assert_raises(Error) do
            orchestrator.call(role: "worker", task: "8xh.t.ccc", assignment: "asg01", overseer: "o@lab")
          end
          assert_equal "refusing to overwrite '.ace-local/coworker/config.yml'; use --force", error.message

          orchestrator.call(role: "worker", task: "8xh.t.ccc", assignment: "asg01",
            overseer: "other@lab", force: true)
          config = Molecules::ConfigLoader.new(project_root: @dir).load
          assert_equal "other@lab", config.overseer
        end

        def test_unknown_role_fails_with_available_list
          error = assert_raises(Error) do
            orchestrator.call(role: "architect", task: "8xh.t.ccc", assignment: "asg01", overseer: "o@lab")
          end
          assert_equal "unknown role 'architect' (available: worker)", error.message
          refute File.exist?(File.join(@dir, ".ace-local", "coworker", "config.yml"))
        end

        def test_unresolvable_task_fails_with_start_vocabulary
          error = assert_raises(Error) do
            orchestrator.call(role: "worker", task: "nope.t.xxx", assignment: "asg01", overseer: "o@lab")
          end
          assert_equal "task 'nope.t.xxx' not found in this worktree", error.message
        end

        def test_missing_assignment_fails_with_start_vocabulary
          error = assert_raises(Error) do
            orchestrator.call(role: "worker", task: "8xh.t.ccc", assignment: "ghost", overseer: "o@lab")
          end
          assert_includes error.message, "assignment 'ghost' not found"
        end

        def test_task_mismatch_fails_with_start_vocabulary
          CoworkerFixture.build_assignment(@dir, id: "asg02", task_id: "8xh.t.other")
          error = assert_raises(Error) do
            orchestrator.call(role: "worker", task: "8xh.t.ccc", assignment: "asg02", overseer: "o@lab")
          end
          assert_equal "assignment 'asg02' belongs to task '8xh.t.other', not '8xh.t.ccc'", error.message
        end

        def test_explicit_config_path_is_resolved_root_relative
          orchestrator(config_path: ".ace-local/coworker/worker.yml")
            .call(role: "worker", task: "8xh.t.ccc", assignment: "asg01", overseer: "o@lab")
          assert File.file?(File.join(@dir, ".ace-local", "coworker", "worker.yml"))
          config = Molecules::ConfigLoader.new(project_root: @dir).load(path: ".ace-local/coworker/worker.yml")
          assert_equal "worker", config.role
        end

        def test_config_path_escaping_project_root_is_refused
          outside = File.expand_path(File.join(@dir, "..", "elsewhere-#{File.basename(@dir)}.yml"))
          error = assert_raises(Error) do
            orchestrator(config_path: "../elsewhere-#{File.basename(@dir)}.yml")
              .call(role: "worker", task: "8xh.t.ccc", assignment: "asg01", overseer: "o@lab")
          end
          assert_equal "config path '#{outside}' escapes the project root", error.message
          refute File.exist?(outside)
        end

        def test_absolute_config_path_outside_project_root_is_refused
          outside = File.join(Dir.tmpdir, "coworker-escape-#{Time.now.to_i}-#{$$}.yml")
          error = assert_raises(Error) do
            orchestrator(config_path: outside)
              .call(role: "worker", task: "8xh.t.ccc", assignment: "asg01", overseer: "o@lab")
          end
          assert_equal "config path '#{outside}' escapes the project root", error.message
          refute File.exist?(outside)
        end

        def test_directory_config_target_is_refused_even_with_force
          dir_target = File.join(@dir, ".ace-local", "coworker", "nested")
          FileUtils.mkdir_p(dir_target)
          error = assert_raises(Error) do
            orchestrator(config_path: ".ace-local/coworker/nested")
              .call(role: "worker", task: "8xh.t.ccc", assignment: "asg01", overseer: "o@lab", force: true)
          end
          assert_equal "config path '.ace-local/coworker/nested' is a directory; --config must name a file", error.message
          assert_empty Dir.glob(File.join(dir_target, "*"))
        end
      end
    end
  end
end
