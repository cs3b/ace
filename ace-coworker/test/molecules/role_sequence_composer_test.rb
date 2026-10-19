# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"

module Ace
  module Coworker
    module Molecules
      class RoleSequenceComposerTest < AceCoworkerTestCase
        REPO_ROOT = File.expand_path("../..", __dir__)
        SHIPPED_SEQUENCES = File.join(REPO_ROOT, ".ace-defaults", "coworker", "sequences")

        FakePresetLoader = Struct.new(:known) do
          def fetch(name)
            return {"name" => name, "source" => "gem"} if known.include?(name)

            raise Error, "unknown role '#{name}' (available: #{known.sort.join(', ')})"
          end
        end

        def setup
          super
          @root = Dir.mktmpdir("coworker-sequence")
          @composer = RoleSequenceComposer.new(project_root: @root,
            preset_loader: FakePresetLoader.new(%w[worker spec reviewer integrator planner]),
            gem_sequences_dir: SHIPPED_SEQUENCES)
        end

        def teardown
          FileUtils.remove_entry(@root)
          super
        end

        def assignment_yaml(id)
          YAML.safe_load_file(File.join(@root, ".ace-local", "assign", id, "assignment.yaml"),
            permitted_classes: [Time, Date], aliases: true)
        end

        def step_files(id)
          Dir.glob(File.join(@root, ".ace-local", "assign", id, "steps", "*.md")).sort
        end

        def read_steps(id)
          step_files(id).map { |path| File.read(path) }
        end

        def test_composes_one_assignment_per_role_in_dependency_order
          entries = @composer.call(task: "8xg.t.aaa", roles: %w[worker reviewer integrator])

          assert_equal %w[worker reviewer integrator], entries.map { |e| e["role"] }
          assert_equal [1, 2, 3], entries.map { |e| e["position"] }
          assert_equal [3, 3, 3], entries.map { |e| e["of"] }
          assert_equal %w[created created created], entries.map { |e| e["disposition"] }

          entries.each do |entry|
            data = assignment_yaml(entry["assignment"])
            assert_equal "8xg.t.aaa-#{entry['role']}", data["name"]
            assert_equal "8xg.t.aaa", data["task_id"]
            assert_includes data["description"], "sequence #{entry['position']}/3"
            assert_includes data["description"], "expected outcome:"
          end
        end

        def test_worker_and_reviewer_get_different_processes_for_the_same_task
          entries = @composer.call(task: "8xg.t.aaa", roles: %w[worker reviewer])
          worker_steps = read_steps(entries[0]["assignment"])
          reviewer_steps = read_steps(entries[1]["assignment"])

          refute_equal worker_steps, reviewer_steps
          worker_all = worker_steps.join
          reviewer_all = reviewer_steps.join
          assert_includes worker_all, "bin/ace-test"
          assert_includes reviewer_all, "3/2/10"
          assert_includes reviewer_all, "ace-coworker rounds record"
          refute_includes worker_all, "3/2/10"
          refute_includes reviewer_all, "bin/ace-test"
        end

        def test_integrator_step_references_the_gate_and_spec_step_references_hitl
          entries = @composer.call(task: "8xg.t.aaa", roles: %w[spec integrator])
          assert_includes read_steps(entries[0]["assignment"]).join, "ace-hitl question"
          assert_includes read_steps(entries[1]["assignment"]).join, "ace-coworker gate"
        end

        def test_entry_conditions_make_the_order_and_handoff_explicit
          entries = @composer.call(task: "8xg.t.aaa", roles: %w[worker reviewer])
          worker_first = read_steps(entries[0]["assignment"]).first
          reviewer_first = read_steps(entries[1]["assignment"]).first

          refute_includes worker_first, "Entry condition:"
          assert_includes reviewer_first, "Entry condition:"
          assert_includes reviewer_first, entries[0]["assignment"]
          assert_includes reviewer_first, "role worker"
        end

        def test_task_and_role_placeholders_render_in_steps_and_outcome
          entries = @composer.call(task: "8xg.t.aaa", roles: %w[worker])
          refute_includes read_steps(entries[0]["assignment"]).join, "{{task}}"
          assert_includes entries[0]["outcome"], "8xg.t.aaa"
          assert_includes assignment_yaml(entries[0]["assignment"])["description"], "8xg.t.aaa"
        end

        def test_missing_role_process_is_reported_and_nothing_is_written
          error = assert_raises(Error) do
            @composer.call(task: "8xg.t.aaa", roles: %w[worker planner])
          end

          assert_includes error.message, "role 'planner' has no assignment process"
          assert_includes error.message, "refusing to substitute"
          refute File.directory?(File.join(@root, ".ace-local")),
            "a missing process must abort the whole composition (all-or-nothing)"
        end

        def test_unknown_role_is_reported_without_substitution
          error = assert_raises(Error) do
            @composer.call(task: "8xg.t.aaa", roles: %w[worker tailors])
          end

          assert_includes error.message, "unknown role 'tailors'"
          refute File.directory?(File.join(@root, ".ace-local"))
        end

        def test_project_override_wins_over_shipped_default
          override_dir = File.join(@root, ".ace", "coworker", "sequences")
          FileUtils.mkdir_p(override_dir)
          File.write(File.join(override_dir, "worker.yml"), <<~YAML)
            ---
            role: worker
            description: "Project worker process for {{task}}"
            outcome: "Project outcome"
            steps:
              - name: project-step
                instructions:
                  - "Project-defined worker step."
          YAML

          entries = @composer.call(task: "8xg.t.aaa", roles: %w[worker])
          steps = read_steps(entries[0]["assignment"])

          assert_includes steps.join, "Project-defined worker step."
          assert_includes assignment_yaml(entries[0]["assignment"])["description"], "Project worker process"
          assert_equal "Project outcome", entries[0]["outcome"]
        end

        def test_invalid_project_override_is_reported_not_substituted
          override_dir = File.join(@root, ".ace", "coworker", "sequences")
          FileUtils.mkdir_p(override_dir)
          File.write(File.join(override_dir, "worker.yml"), <<~YAML)
            ---
            role: worker
            description: "Broken"
            outcome: "Broken"
            steps: []
          YAML

          error = assert_raises(Error) do
            @composer.call(task: "8xg.t.aaa", roles: %w[worker])
          end

          assert_includes error.message, "invalid assignment process"
          assert_includes error.message, "at least one step is required"
          refute File.directory?(File.join(@root, ".ace-local"))
        end

        def test_recompose_reuses_existing_assignments_without_writes
          entries = @composer.call(task: "8xg.t.aaa", roles: %w[worker reviewer])
          snapshot = step_files(entries[0]["assignment"]).map { |p| File.mtime(p) }

          reentries = @composer.call(task: "8xg.t.aaa", roles: %w[worker reviewer])

          assert_equal %w[existing existing], reentries.map { |e| e["disposition"] }
          assert_equal entries.map { |e| e["assignment"] }, reentries.map { |e| e["assignment"] }
          assert_equal snapshot, step_files(reentries[0]["assignment"]).map { |p| File.mtime(p) }
        end

        def test_existing_assignment_of_a_foreign_task_is_not_reused
          entries = @composer.call(task: "8xg.t.aaa", roles: %w[worker])
          # Corrupt the recorded task id: the name still matches but the
          # assignment belongs to another task, so a new one is composed.
          path = File.join(@root, ".ace-local", "assign", entries[0]["assignment"], "assignment.yaml")
          data = YAML.safe_load_file(path, permitted_classes: [Time, Date], aliases: true)
          data["task_id"] = "8xg.t.bbb"
          File.write(path, YAML.dump(data))

          reentries = @composer.call(task: "8xg.t.aaa", roles: %w[worker])

          assert_equal "created", reentries[0]["disposition"]
          refute_equal entries[0]["assignment"], reentries[0]["assignment"]
        end

        def test_empty_role_sequence_is_rejected
          error = assert_raises(Error) do
            @composer.call(task: "8xg.t.aaa", roles: [])
          end

          assert_includes error.message, "at least one role"
        end

        def test_empty_process_file_is_reported_as_invalid_process
          override_dir = File.join(@root, ".ace", "coworker", "sequences")
          FileUtils.mkdir_p(override_dir)
          File.write(File.join(override_dir, "worker.yml"), "---\n")

          error = assert_raises(Error) do
            @composer.call(task: "8xg.t.aaa", roles: %w[worker])
          end

          assert_includes error.message, "invalid assignment process"
          assert_includes error.message, "process is empty"
          refute File.directory?(File.join(@root, ".ace-local"))
        end

        def test_non_mapping_process_file_is_reported_as_invalid_process
          override_dir = File.join(@root, ".ace", "coworker", "sequences")
          FileUtils.mkdir_p(override_dir)
          File.write(File.join(override_dir, "worker.yml"), "- role: worker\n")

          error = assert_raises(Error) do
            @composer.call(task: "8xg.t.aaa", roles: %w[worker])
          end

          assert_includes error.message, "invalid assignment process"
          assert_includes error.message, "process must be a mapping, got Array"
          refute File.directory?(File.join(@root, ".ace-local"))
        end

        def test_lifecycle_reserved_step_keys_cannot_override_step_frontmatter
          override_dir = File.join(@root, ".ace", "coworker", "sequences")
          FileUtils.mkdir_p(override_dir)
          File.write(File.join(override_dir, "worker.yml"), <<~YAML)
            ---
            role: worker
            description: "Override attempt"
            outcome: "Done"
            steps:
              - name: do
                instructions: "work"
                status: done
                added_by: attacker
                parent: something
          YAML

          entries = @composer.call(task: "8xg.t.aaa", roles: %w[worker])
          step = YAML.safe_load_file(step_files(entries[0]["assignment"]).first,
            permitted_classes: [Time, Date], aliases: true)

          assert_equal "pending", step["status"]
          assert_nil step["added_by"]
          assert_nil step["parent"]
        end

        def test_steps_are_numbered_and_pending_with_workflow_frontmatter
          entries = @composer.call(task: "8xg.t.aaa", roles: %w[worker])
          files = step_files(entries[0]["assignment"])

          assert_equal 2, files.length
          assert_includes File.basename(files[0]), "010"
          assert_includes File.basename(files[1]), "020"
          first = File.read(files[0])
          assert_includes first, "status: pending"
          assert_includes first, "workflow: wfi://coworker/worker"
        end
      end
    end
  end
end
