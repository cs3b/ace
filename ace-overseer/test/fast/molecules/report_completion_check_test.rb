# frozen_string_literal: true
require_relative "../../test_helper"

class ReportCompletionCheckTest < AceOverseerTestCase
  Task = Struct.new(:metadata)

  def setup
    @event = {"id" => "8xuk0q", "task" => "8xu.t.jh8", "assignment" => "8xujj4"}
    @manager = Task.new({"project_task" => "8xu.t.jh8"})
    @step = Task.new({"assignment" => "8xujj4", "role" => "bootstrap-worker", "worktree" => "/tmp/commission"})
    @legs = [{"assignment" => "8xujj4", "role" => "bootstrap-worker"}]
    @state = "completed"
    @steps = [{number: 10, name: "bootstrap", status: "done"}]
    @identity = "8xujj4"
    @finder = Object.new
    @finder.define_singleton_method(:switch) do |task|
      raise "wrong task" unless task == "8xu.t.jh8"
      {success: true, worktree_path: "/tmp/commission"}
    end
  end

  def check
    legs = @legs
    handoff = Object.new
    handoff.define_singleton_method(:probe) do |root, task_id:|
      raise "wrong root" unless root == "/tmp/commission"
      raise "wrong task" unless task_id == "8xu.t.jh8"
      {legs: legs}
    end
    snapshot = Ace::Coworker::Models::AssignmentSnapshot.new(id: @identity,
      name: "bootstrap-worker", state: @state, steps: @steps, progress: "1/1")
    probe = Object.new
    probe.define_singleton_method(:snapshot) do |id|
      raise "wrong assignment" unless id == "8xujj4"
      snapshot
    end
    Ace::Overseer::Molecules::ReportCompletionCheck.new(handoff_probe: handoff, worktree_finder: @finder,
      assignment_probe_factory: ->(_root) { probe }).call(event: @event, manager: @manager, step: @step)
  end

  def test_completed_nonempty_owner_assignment_and_real_role_are_accepted
    assert_nil check
  end

  def test_empty_incomplete_failed_or_wrong_identity_cannot_be_accepted
    @steps = []
    assert_includes check, "empty"
    @steps = [{number: 10, name: "bootstrap", status: "active"}]
    assert_includes check, "active"
    @steps.first[:status] = "failed"
    assert_includes check, "failed"
    @steps.first[:status] = "done"
    @state = "running"
    assert_includes check, "not completed"
    @state = "completed"
    @identity = "different"
    assert_includes check, "different identity"
  end

  def test_missing_ambiguous_or_wrong_role_owner_allocation_refuses
    @legs = []
    assert_includes check, "no unique allocation"
    @legs = [{"assignment" => "8xujj4", "role" => "bootstrap-verifier"}]
    assert_includes check, "role disagrees"
    @legs *= 2
    assert_includes check, "no unique allocation"
  end

  def test_missing_commission_fields_and_conflicting_report_task_refuse
    @event["task"] = nil
    assert_includes check, "task disagrees"
    @event["task"] = "8xu.t.jh8"
    @step.metadata.delete("role")
    assert_includes check, "recorded project task, role and worktree"
  end

  def test_unavailable_assignment_owner_is_a_refusal
    probe = Object.new
    probe.define_singleton_method(:probe) { |*args, **kwargs| raise Ace::Coworker::Error, "unavailable" }
    reason = Ace::Overseer::Molecules::ReportCompletionCheck.new(handoff_probe: probe, worktree_finder: @finder)
      .call(event: @event, manager: @manager, step: @step)
    assert_includes reason, "could not be verified"
  end

  def test_confirm_start_never_accepts_an_executor_completion
    @step.metadata["role"] = "confirm-start"
    assert_includes check, "coordinator session evidence"
  end
end
