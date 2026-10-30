# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/molecules/event_observation"

class OverseerEventObservationTest < AceOverseerTestCase
  # Local sources stubbed off for the HITL-adoption semantics; the merged
  # projection has its own tests below.
  def no_local_sources
    -> { {"events" => [], "sources" => {}} }
  end

  def test_actual_task_adoption_keeps_unaccepted_and_incomplete_continuation_but_suppresses_closed_history
    Dir.mktmpdir do |tmp|
      tasks = Ace::Task::Organisms::TaskManager.new(root_dir: File.join(tmp, "tasks"))
      manager = tasks.create("Manager", status: "in-progress")
      tasks.update(manager.id, set: {"project_task" => "8xg.t.abc"}, move_to: "_overseer")
      step = tasks.create_subtask(manager.id, "Worker", status: "in-progress")
      tasks.update(step.id, set: {"assignment" => "worker-1"})
      root = File.join(tmp, "hitl")
      hitl = Ace::Hitl::Organisms::HitlManager.new(root_dir: root,
        config: {"hitl" => {"root_dir" => root, "recipients" => {"self" => {"machine" => "lab", "panel" => "w7:p1"}}}})
      event = hitl.create("Worker result", type: "report", result: "success", to: "self", assignment: "worker-1", task: "8xg.t.abc")
      projection = Ace::Hitl::Molecules::EventObservation.new(manager: hitl)
      observer = Ace::Overseer::Molecules::EventObservation.new(hitl: projection, task_manager: tasks,
        local_sources: no_local_sources)
      original = observer.call(owner: "self")
      assert_equal [event.id], original["events"].map { |row| row["id"] }
      # Adoption alone is not continuation: retain the original semantic revision.
      tasks.update(step.id, set: {"processed_report" => event.id, "report_result" => "success"})
      assert_equal original, observer.call(owner: "self")
      tasks.update(step.id, set: {"status" => "done"})
      # Auto-archive/parent closure belongs to TaskManager, not the observer.
      assert_equal "done", tasks.show(manager.id).status
      assert_empty observer.call(owner: "self")["events"]
      assert_equal original["events"], observer.call(owner: "self")["settled"]
      assert_equal "success", tasks.show(step.id).metadata["report_result"]
    end
  end

  def test_merged_projection_carries_local_rows_and_source_health
    Dir.mktmpdir do |tmp|
      tasks = Ace::Task::Organisms::TaskManager.new(root_dir: File.join(tmp, "tasks"))
      tasks.create("Local work", status: "pending")
      root = File.join(tmp, "hitl")
      hitl = Ace::Hitl::Organisms::HitlManager.new(root_dir: root,
        config: {"hitl" => {"root_dir" => root, "recipients" => {"self" => {"machine" => "lab", "panel" => "w7:p1"}}}})
      projection = Ace::Hitl::Molecules::EventObservation.new(manager: hitl)
      local = -> {
        {"events" => [{"key" => "task:8xs.t.zz9", "revision" => "r1", "type" => "task",
                       "id" => "8xs.t.zz9", "status" => "pending"}],
         "sources" => {"project_tasks" => {"status" => "ok"},
                       "worktrees" => {"status" => "degraded", "error" => "RuntimeError: boom"}}}
      }
      observer = Ace::Overseer::Molecules::EventObservation.new(hitl: projection, task_manager: tasks,
        local_sources: local)

      result = observer.call(owner: "self")

      assert_equal "ace.hitl.observation/v1", result["schema"]
      keys = result["events"].map { |row| row["key"] }
      assert_includes keys, "task:8xs.t.zz9"
      assert_equal({"status" => "ok"}, result["sources"]["hitl"])
      assert_equal "degraded", result["sources"]["worktrees"]["status"]
    end
  end

  def test_degraded_hitl_keeps_local_sources_projecting
    Dir.mktmpdir do |tmp|
      tasks = Ace::Task::Organisms::TaskManager.new(root_dir: File.join(tmp, "tasks"))
      failing_hitl = Object.new
      def failing_hitl.call(**)
        raise ArgumentError, "unknown recipient"
      end
      local = -> {
        {"events" => [{"key" => "task:8xs.t.zz9", "revision" => "r1", "type" => "task"}],
         "sources" => {"project_tasks" => {"status" => "ok"}}}
      }
      observer = Ace::Overseer::Molecules::EventObservation.new(hitl: failing_hitl,
        task_manager: tasks, local_sources: local)

      result = observer.call(owner: "self")

      assert_equal "degraded", result["sources"]["hitl"]["status"]
      assert_match(/unknown recipient/, result["sources"]["hitl"]["error"])
      marker = result["events"].find { |row| row["type"] == "source-health" }
      assert_equal "source:hitl", marker["key"]
      # the healthy local source still projects
      assert_includes result["events"].map { |row| row["key"] }, "task:8xs.t.zz9"
    end
  end
end
