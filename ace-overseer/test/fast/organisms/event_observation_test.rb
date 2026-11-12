# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/molecules/event_observation"
require "open3"

class OverseerEventObservationTest < AceOverseerTestCase
  def test_source_recovery_revises_the_same_wire_event_even_when_work_is_unchanged
    failing = false
    hitl = lambda do |**|
      raise Errno::EACCES, "case store" if failing

      {"schema" => "ace.hitl.observation/v1", "events" => []}
    end
    tasks = Object.new
    def tasks.list(**) = []
    observer = Ace::Overseer::Molecules::EventObservation.new(hitl: hitl,
      task_manager: tasks, local_sources: no_local_sources, config: {})
    healthy_projection = observer.call(owner: "self")
    failing = true
    degraded_projection = observer.call(owner: "self")
    failing = false
    recovered_projection = observer.call(owner: "self")
    healthy, degraded, recovered = [healthy_projection, degraded_projection, recovered_projection].map do |projection|
      projection.fetch("events").find { |row| row["source_key"] == "source:hitl" }
    end

    assert_equal "degraded", degraded.fetch("status")
    assert_equal "ok", recovered.fetch("status")
    assert_equal degraded.fetch("key"), recovered.fetch("key")
    refute_equal degraded.fetch("revision"), recovered.fetch("revision")
    assert_equal healthy, recovered

    source = File.expand_path("../ace-wake/handbook/extensions/ace-wake/wake/eyes.js", Ace::Overseer.gem_root)
    script = <<~JS
      import assert from 'node:assert/strict';
      import {pathToFileURL} from 'node:url';
      const {Eyes} = await import(pathToFileURL(process.argv[1]));
      let data = ''; for await (const chunk of process.stdin) data += chunk;
      const [healthy, degraded, recovered] = JSON.parse(data);
      const deliveries = [];
      let current, saved;
      const observer = () => new Eyes({snapshot: saved, save: (snapshot) => { saved = snapshot; },
        observe: async () => current, deliver: async (batch) => { deliveries.push(batch); return true; }});
      let eyes = observer();
      eyes.start({});
      for (current of [healthy, healthy, degraded, degraded, recovered, recovered, degraded]) {
        if (current === recovered && deliveries.length === 2) {
          eyes.dispose();
          eyes = observer();
        }
        const previous = deliveries.length;
        await eyes.tick();
        if (deliveries.length > previous) {
          const [[key, {revision}]] = deliveries.at(-1);
          eyes.ack(key, revision);
        }
      }
      assert.deepEqual(deliveries.map(([[, {revision}]]) => revision),
        [healthy, degraded, recovered, degraded].map(p => p.events[0].revision));
    JS
    _, err, status = Open3.capture3("node", "--input-type=module", "-e", script, source,
      stdin_data: JSON.generate([healthy_projection, degraded_projection, recovered_projection]))
    assert status.success?, err
  end

  # Local sources stubbed off for the HITL-adoption semantics; the merged
  # projection has its own tests below.
  def no_local_sources
    -> { {"events" => [], "sources" => {}} }
  end

  def work_events(projection)
    projection.fetch("events").reject { |row| row["type"] == "source-health" }
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
      assert_equal [event.id], work_events(original).map { |row| row["id"] }
      # Adoption alone is not continuation: retain the original semantic revision.
      tasks.update(step.id, set: {"processed_report" => event.id, "report_result" => "success"})
      assert_equal original, observer.call(owner: "self")
      tasks.update(step.id, set: {"status" => "done"})
      # Auto-archive/parent closure belongs to TaskManager, not the observer.
      assert_equal "done", tasks.show(manager.id).status
      receipt = work_events(original).first.slice("key", "revision").merge("cleanup" => "complete", "continuation" => "complete")
      tasks.update(step.id, set: {"report_receipt" => receipt})
      assert_empty work_events(observer.call(owner: "self"))
      assert_equal work_events(original), observer.call(owner: "self")["settled"]
      assert_equal "success", tasks.show(step.id).metadata["report_result"]
    end
  end

  def test_project_report_is_settled_only_by_the_lab_private_manager
    Dir.mktmpdir do |tmp|
      tasks = Ace::Task::Organisms::TaskManager.new(root_dir: File.join(tmp, "tasks"))
      manager = tasks.create("Project bootstrap", status: "in-progress")
      tasks.update(manager.id, set: {"project_task" => "8xg.t.abc"}, move_to: "_overseer")
      step = tasks.create_subtask(manager.id, "Worker", status: "in-progress")
      tasks.update(step.id, set: {"assignment" => "worker-1"})
      event = {"id" => "report-1", "key" => "scoped-project-key", "revision" => "rev-1",
        "type" => "report", "result" => "success", "task" => "8xg.t.abc", "assignment" => "worker-1",
        "project_root" => "/lab/ace"}
      hitl = ->(**) { {"schema" => "ace.hitl.observation/v1", "events" => [], "settled" => []} }
      projects = ->(**) { {"events" => [event], "sources" => {"project:ace:hitl" => {"status" => "ok"}}} }
      observer = Ace::Overseer::Molecules::EventObservation.new(hitl: hitl, task_manager: tasks,
        local_sources: no_local_sources, project_observations: projects)
      assert_equal [event], work_events(observer.call(owner: "overseer"))
      tasks.update(step.id, set: {"processed_report" => "report-1", "report_result" => "success"})
      assert_equal [event], work_events(observer.call(owner: "overseer"))
      tasks.update(step.id, set: {"status" => "done"})
      # A settled allocation without the matching project binding cannot
      # suppress another project's report, even when IDs coincide.
      assert_equal [event], work_events(observer.call(owner: "overseer"))
      tasks.update(manager.id, set: {"project_root" => "/lab/other"})
      assert_equal [event], work_events(observer.call(owner: "overseer"))
      tasks.update(manager.id, set: {"project_root" => "/lab/ace"})
      receipt = event.slice("key", "revision").merge("cleanup" => "complete", "continuation" => "complete")
      tasks.update(step.id, set: {"report_receipt" => receipt})
      settled = observer.call(owner: "overseer")
      assert_empty work_events(settled)
      assert_equal [event], settled["settled"]
      assert_equal "/lab/ace", settled["settled"].first["project_root"]
      event["revision"] = "rev-2"
      assert_equal [event], work_events(observer.call(owner: "overseer")), "a changed report is not the accepted revision"
      assert_empty observer.call(owner: "overseer")["settled"]
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
      keys = result["events"].map { |row| row["source_key"] || row["key"] }
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
      marker = result["events"].find { |row| row["type"] == "source-health" && row["status"] == "degraded" }
      assert_equal "source:hitl", marker["source_key"]
      # the healthy local source still projects
      assert_includes result["events"].map { |row| row["source_key"] || row["key"] }, "task:8xs.t.zz9"
    end
  end

  def test_unreadable_private_managers_degrade_only_their_source_and_never_settle_reports
    report = {"id" => "worker-report", "key" => "report-key", "revision" => "report-rev",
      "type" => "report", "result" => "success", "task" => "task-1", "assignment" => "assignment-1"}
    tasks = Object.new
    tasks.define_singleton_method(:list) { |**| raise Errno::EACCES, "private manager tree" }
    local = -> {
      {"events" => [{"key" => "source:overseer_tasks", "type" => "source-health", "revision" => "old"},
                    {"key" => "task:public", "type" => "task", "revision" => "public-rev"}],
       "sources" => {"project_tasks" => {"status" => "ok"}, "overseer_tasks" => {"status" => "degraded"}}}
    }
    projects = ->(**) { {"events" => [], "sources" => {}} }
    hitl = ->(**) { {"schema" => "ace.hitl.observation/v1", "events" => [report], "settled" => []} }
    observer = Ace::Overseer::Molecules::EventObservation.new(hitl: hitl, task_manager: tasks,
      local_sources: local, project_observations: projects, config: {})

    result = observer.call(owner: "overseer")
    assert_equal "degraded", result.fetch("sources").fetch("overseer_tasks").fetch("status")
    assert_match(/EACCES.*private manager tree/, result["sources"]["overseer_tasks"]["error"])
    assert_equal "ok", result["sources"]["project_tasks"]["status"]
    assert_equal "ok", result["sources"]["hitl"]["status"]
    assert_includes result["events"], report
    assert_empty result["settled"]
    assert_equal 1, result["events"].count { |row| row["source_key"] == "source:overseer_tasks" }
    assert_equal result, observer.call(owner: "overseer")
  end

  def test_configured_issue_source_is_projected_as_an_eyes_event
    Dir.mktmpdir do |tmp|
      tasks = Ace::Task::Organisms::TaskManager.new(root_dir: File.join(tmp, "tasks"))
      hitl = Object.new
      def hitl.call(**) = {"schema" => "ace.hitl.observation/v1", "events" => []}
      issue = Ace::Git::ProviderIssue.new(server_name: "forge", number: 7, title: "work",
        state: :open, author: "user", url: "http://forge/issues/7", labels: [])
      provider = Object.new
      provider.define_singleton_method(:recent_issues) { |limit:| [issue] }
      remote = Ace::Overseer::Molecules::RemoteSources.new(provider_factory: ->(_) { provider })
      observer = Ace::Overseer::Molecules::EventObservation.new(hitl: hitl, task_manager: tasks,
        local_sources: no_local_sources, remote_sources: remote,
        config: {"observe" => {"remote" => {"issues" => [{"server" => "forge"}]}}})

      result = observer.call(owner: "self")
      row = work_events(result).fetch(0)
      assert_equal "issues:forge", row.fetch("source_key")
      assert_match(/\A[a-f0-9]{64}\z/, row.fetch("key"))
      assert_equal [7], row.fetch("issue_numbers")
      assert_equal({"status" => "ok"}, result.fetch("sources").fetch("issues:forge"))
      source = File.expand_path("../ace-wake/handbook/extensions/ace-wake/wake/eyes.js", Ace::Overseer.gem_root)
      script = <<~JS
        import {pathToFileURL} from 'node:url';
        const {Eyes} = await import(pathToFileURL(process.argv[1]));
        const eyes = new Eyes({save:()=>{}, observe:async()=>{}, deliver:async()=>{}});
        let data=''; for await (const chunk of process.stdin) data+=chunk;
        eyes.validate(JSON.parse(data));
      JS
      _, err, status = Open3.capture3("node", "--input-type=module", "-e", script, source,
        stdin_data: JSON.generate(result))
      assert status.success?, err
    end
  end

  def test_real_local_source_projection_is_accepted_by_the_shipped_eyes_validator
    Dir.mktmpdir do |tmp|
      tasks = Ace::Task::Organisms::TaskManager.new(root_dir: File.join(tmp, "tasks"))
      tasks.create("Bootstrap ACE", status: "pending")
      tasks.create("Verify ACE", status: "pending")
      worktrees = Object.new
      def worktrees.list_all = {success: true, worktrees: []}
      local = Ace::Overseer::Molecules::LocalSources.new(task_manager: tasks, worktree_manager: worktrees)
      hitl = Object.new
      def hitl.call(**) = {"schema" => "ace.hitl.observation/v1", "events" => []}
      observer = Ace::Overseer::Molecules::EventObservation.new(hitl: hitl, task_manager: tasks, local_sources: local)
      result = observer.call(owner: "self")
      refute_empty result.fetch("events")
      error = assert_raises(ArgumentError) { observer.call(owner: "self", limit: 1) }
      assert_match(/exceeding limit/, error.message)

      source = File.expand_path("../ace-wake/handbook/extensions/ace-wake/wake/eyes.js", Ace::Overseer.gem_root)
      script = <<~JS
        import {pathToFileURL} from 'node:url';
        const {Eyes} = await import(pathToFileURL(process.argv[1]));
        const eyes = new Eyes({save:()=>{}, observe:async()=>{}, deliver:async()=>{}});
        let data=''; for await (const chunk of process.stdin) data+=chunk;
        eyes.validate(JSON.parse(data));
      JS
      _, err, status = Open3.capture3("node", "--input-type=module", "-e", script, source,
        stdin_data: JSON.generate(result))
      assert status.success?, err
      assert_equal result, observer.call(owner: "self"), "unchanged state keeps the same wire revisions"
    end
  end

end
