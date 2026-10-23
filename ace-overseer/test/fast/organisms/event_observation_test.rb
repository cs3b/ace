# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/molecules/event_observation"

class OverseerEventObservationTest < AceOverseerTestCase
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
      observer = Ace::Overseer::Molecules::EventObservation.new(hitl: projection, task_manager: tasks)
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
end
