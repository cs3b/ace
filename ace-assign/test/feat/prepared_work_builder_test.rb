# frozen_string_literal: true
require_relative "../test_helper"
require "ace/assign/organisms/prepared_work_builder"

module Ace
  module Assign
    class PreparedWorkBuilderTest < AceAssignTestCase
      TASK = "8wr.t.abc"
      DEP = "8wr.t.qjl"

      def with_builder(status: "pending", dependencies: [])
        Dir.mktmpdir("prepared-builder-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0700, root)
          task_root = File.join(root, "tasks")
          FileUtils.mkdir_p(task_root)
          write_task(task_root, TASK, status: status, dependencies: dependencies)
          tasks = Ace::Task::Organisms::TaskManager.new(root_dir: task_root, config: {})
          executor = Organisms::AssignmentExecutor.new(cache_base: File.join(root, "assign"))
          loader = Ace::Bundle::Organisms::BundleLoader.new(base_dir: root)
          builder = Organisms::PreparedWorkBuilder.new(export_root: root, task_manager: tasks,
            executor: executor, bundle_loader: loader)
          Ace::Assign.stub(:cache_dir, File.join(root, "assign")) do
            yield builder, root, task_root, tasks, executor, loader
          end
        end
      end

      def write_task(root, id, status: "done", dependencies: [])
        directory = File.join(root, id + "-fixture")
        FileUtils.mkdir_p(directory)
        path = File.join(directory, id + "-fixture.s.md")
        File.write(path, "---\n" + YAML.dump({"id" => id, "title" => "Fixture", "status" => status,
          "needs_review" => false, "dependencies" => dependencies}).delete_prefix("---\n") + "---\nReviewed #{id}.\n")
        path
      end

      def test_actual_task_bundle_and_managed_default_graph_export_exact_selected_inputs
        with_builder(dependencies: [DEP]) do |builder, root, task_root, tasks, _executor, _loader|
          write_task(task_root, DEP)
          result = builder.call(task_ref: TASK, project_id: "ace", dependency_reports: [])
          work = Authority::PreparedWork.admit(root: root, bytes: result.fetch("bundle"), size: result.fetch("bytes"),
            sha256: result.fetch("sha256"), head: result.fetch("head"), tree: result.fetch("tree"))
          assert_equal [DEP, TASK].sort, work.manifest.fetch("context").map { |entry| entry.fetch("task_id") }
          assert_equal File.read(tasks.show(TASK).file_path), work.files.fetch("context/#{TASK}/spec.md")
          assert_includes work.files.fetch("context/#{DEP}/bundle.txt"), "Reviewed #{DEP}"
          assert_equal "ace", work.definition.fetch("project_id")
          assert_equal TASK, work.definition.fetch("task_id")
          refute_equal "010", result.fetch("scope")
          assert work.manifest.fetch("steps").all? { |step| step.fetch("number").start_with?(result.fetch("scope")) }
          refute work.files.key?("steps/000-onboard.st.md")
        end
      end

      def test_draft_refuses_before_managed_creation
        with_builder(status: "draft") do |builder, _root, _task_root, _tasks, executor, _loader|
          assert_raises(AttemptErrors::ReceiptRejected) do
            builder.call(task_ref: TASK, project_id: "ace", dependency_reports: [])
          end
          assert_empty executor.assignment_manager.list
        end
      end

      def test_explicit_reviewed_child_captures_only_its_selected_subtree
        with_builder do |builder, root, _task_root, tasks, _executor, _loader|
          child = tasks.create_subtask(TASK, "Selected child", status: "pending")
          sibling = tasks.create_subtask(TASK, "Unselected sibling", status: "pending")
          result = builder.call(task_ref: child.id, project_id: "ace", dependency_reports: [])
          work = Authority::PreparedWork.admit(root: root, bytes: result.fetch("bundle"), size: result.fetch("bytes"),
            sha256: result.fetch("sha256"), head: result.fetch("head"), tree: result.fetch("tree"))
          assert_equal child.id, work.definition.fetch("task_id")
          assert_equal [child.id], work.manifest.fetch("context").map { |entry| entry.fetch("task_id") }
          assert work.manifest.fetch("steps").all? { |entry|
            entry.fetch("number") == result.fetch("scope") || entry.fetch("number").start_with?(result.fetch("scope") + ".")
          }
          refute work.files.key?("context/#{sibling.id}/spec.md")
          refute work.files.key?("context/#{TASK}/spec.md")
        end
      end

      def test_parent_with_children_refuses_before_creating_an_assignment
        with_builder do |builder, _root, _task_root, tasks, executor, _loader|
          tasks.create_subtask(TASK, "First child", status: "pending")
          tasks.create_subtask(TASK, "Second child", status: "pending")
          error = assert_raises(AttemptErrors::ReceiptRejected) do
            builder.call(task_ref: TASK, project_id: "ace", dependency_reports: [])
          end
          assert_includes error.message, "not a reviewed leaf"
          assert_empty executor.assignment_manager.list
        end
      end

      def test_cycle_refuses_before_managed_creation
        with_builder(dependencies: [DEP]) do |builder, _root, task_root, _tasks, executor, _loader|
          write_task(task_root, DEP, dependencies: [TASK])
          error = assert_raises(AttemptErrors::ReceiptRejected) do
            builder.call(task_ref: TASK, project_id: "ace", dependency_reports: [])
          end
          assert_includes error.message, "dependency cycle"
          assert_empty executor.assignment_manager.list
        end
      end

      def test_missing_dependency_and_unreviewed_spec_refuse_before_preparation
        with_builder(dependencies: [DEP]) do |builder, _root, _task_root, _tasks, executor, _loader|
          assert_raises(AttemptErrors::ReceiptRejected) do
            builder.call(task_ref: TASK, project_id: "ace", dependency_reports: [])
          end
          assert_empty executor.assignment_manager.list
        end
        with_builder do |builder, _root, _task_root, tasks, executor, _loader|
          path = tasks.show(TASK).file_path
          File.write(path, File.read(path).sub("needs_review: false", "needs_review: true"))
          error = assert_raises(AttemptErrors::ReceiptRejected) do
            builder.call(task_ref: TASK, project_id: "ace", dependency_reports: [])
          end
          assert_includes error.message, "needs review"
          assert_empty executor.assignment_manager.list
        end
      end

      def test_bundle_owner_error_does_not_become_captured_instructions
        with_builder do |builder, _root, _task_root, _tasks, executor, loader|
          loader.define_singleton_method(:load_file) do |_path|
            Ace::Bundle::Models::BundleData.new(content: "partial", metadata: {error: "missing source"})
          end
          assert_raises(AttemptErrors::ReceiptRejected) do
            builder.call(task_ref: TASK, project_id: "ace", dependency_reports: [])
          end
          assert_empty executor.assignment_manager.list
        end
      end

      def test_context_change_during_capture_never_exports
        with_builder do |builder, _root, _task_root, tasks, _executor, loader|
          original = loader.method(:load_file)
          calls = 0
          loader.define_singleton_method(:load_file) do |path|
            result = original.call(path)
            calls += 1
            File.open(tasks.show(TASK).file_path, "a") { |file| file.write("Changed instructions.\n") } if calls == 1
            result
          end
          error = assert_raises(AttemptErrors::ReceiptRejected) do
            builder.call(task_ref: TASK, project_id: "ace", dependency_reports: [])
          end
          assert_includes error.message, "captured input changed"
        end
      end

      def test_explicit_dependency_report_is_captured_from_actual_managed_report_owner
        with_builder(dependencies: [DEP]) do |builder, root, task_root, _tasks, executor, _loader|
          write_task(task_root, DEP)
          config = File.join(root, "dependency.yaml")
          File.write(config, YAML.dump({"steps" => [{"name" => "verify", "instructions" => "Check dependency."}]}))
          assignment = executor.start(config, task_id: DEP, project_id: "ace").fetch(:assignment)
          executor.start_step
          executor.finish_step(report_content: "Actual dependency report.")
          selection = {"task_id" => DEP, "assignment_id" => assignment.id, "number" => "010"}
          result = builder.call(task_ref: TASK, project_id: "ace", dependency_reports: [selection])
          work = Authority::PreparedWork.admit(root: root, bytes: result.fetch("bundle"), size: result.fetch("bytes"),
            sha256: result.fetch("sha256"), head: result.fetch("head"), tree: result.fetch("tree"))
          record = work.manifest.fetch("context").find { |entry| entry.fetch("task_id") == DEP }.fetch("reports").fetch(0)
          assert_equal assignment.id, record.fetch("assignment_id")
          assert_includes work.files.fetch(record.fetch("file").fetch("filename")), "Actual dependency report."
          assert_raises(AttemptErrors::ReceiptRejected) do
            builder.call(task_ref: TASK, project_id: "other", dependency_reports: [selection])
          end
          assert_raises(AttemptErrors::ReceiptRejected) do
            builder.call(task_ref: TASK, project_id: "ace", dependency_reports: [selection, selection])
          end
        end
      end
    end
  end
end
