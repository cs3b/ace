# frozen_string_literal: true
require_relative "../test_helper"
require "timeout"
require_relative "../generation_fixtures"

# Only the paid model boundary is replaced. Real preset resolution, prompts,
# files, locks, publication, gallery and selection run end to end.
class GenerationTest < DesignTest
  include GenerationFixtures
  def test_session_without_task_scope_or_design_snapshot_has_actionable_error
    with_runner do |runner, agent, _|
      root = runner.prepare(surface: "app", prompt: "Workspace")["session"]
      metadata_path = File.join(root, "session.json")
      metadata = JSON.parse(File.read(metadata_path))
      File.write(metadata_path, JSON.generate(metadata.reject { |key, _| key == "kind" }))
      error = assert_raises(Ace::Design::Error) { controller(root, agent) }
      assert_includes error.message, "create a new session"
      File.write(metadata_path, JSON.generate(metadata))
      state_path = File.join(root, "run.json")
      state = JSON.parse(File.read(state_path))
      state.fetch("inputs").delete("design.md")
      File.write(state_path, JSON.generate(state))
      error = assert_raises(Ace::Design::Error) { controller(root, agent) }
      assert_includes error.message, "create a new session"
      assert_empty agent.calls
    end
  end
  def test_three_duplicate_model_slots_receive_shared_inputs_and_distinct_extra_prompts
    with_runner do |runner, agent, base|
      fixture = File.join(base, "data.json")
      bytes = "{\n  \"title\": \"Do not rewrite\"\n}\n"
      File.write(fixture, bytes)
      prompt_file = File.join(base, "b.md")
      File.write(prompt_file, "Customer history")
      result = runner.generate(surface: "app", prompt: "Support workspace", fixtures: fixture,
        variant_prompts: ["a=Fast, clear queue", "a=Keyboard first"], variant_prompt_files: ["b=#{prompt_file}"])
      root = result.fetch("session")
      assert_equal "succeeded", result["status"], result.inspect
      assert_match(/\A[0-9a-z]+\z/, File.basename(root))
      assert_equal %w[a b c preparation], agent.calls.map { |c| c[:id] }.sort
      assert_equal 1, agent.calls.map { |c| c[:model] }.uniq.size
      assert_equal bytes, File.binread(File.join(root, "fixtures.json"))
      a = agent.calls.find { |c| c[:id] == "a" }
      b = agent.calls.find { |c| c[:id] == "b" }
      assert_includes a[:prompt], "Fast, clear queue\n\nKeyboard first"
      assert_includes b[:prompt], "Customer history"
      refute_includes b[:prompt], "Keyboard first"
      assert_equal 3, File.read(result["gallery"]).scan("<iframe").size
      agent.calls.each { |c| assert_equal bytes, File.binread(File.join(c[:workspace], "fixtures.json")) }
      assert File.file?(File.join(a[:workspace], "prompt.md"))
    end
  end
  def test_failed_worker_resumes_without_repeating_preparation_or_successes
    with_runner do |runner, agent, _|
      agent.failure = "b"
      result = runner.generate(surface: "site", prompt: "Course page")
      root = result["session"]
      assert_equal "incomplete", result["status"]
      assert_equal 2, File.read(result["gallery"]).scan("<iframe").size
      assert_includes File.read(result["gallery"]), "b (failed)"
      refute_includes File.read(result["gallery"]), 'http-equiv="refresh"' 
      before = File.binread(File.join(root, "variants/a/index.html"))
      agent.failure = nil
      result = controller(root, agent).resume
      assert_equal "succeeded", result["status"]
      assert_equal before, File.binread(File.join(root, "variants/a/index.html"))
      assert_equal 2, agent.calls.count { |c| c[:id] == "b" }
      assert_equal 1, agent.calls.count { |c| c[:id] == "preparation" }
      assert_equal 1, result.fetch("preparation_attempts").size
      assert_equal 1, agent.calls.count { |c| c[:id] == "c" }
    end
  end
  def test_revision_failure_preserves_selection_then_success_invalidates_only_changed_variant
    with_runner do |runner, agent, _|
      root = runner.generate(surface: "app", prompt: "Workspace")["session"]
      controller = controller(root, agent)
      original = hashes(root)
      controller.select(variant: "b", decisions: ["Keep hierarchy"])
      agent.failure = "b"
      result = controller.revise(variant: "b", prompt: "Less dense, keep hierarchy")
      assert_equal "failed", result["workers"]["b"]["status"]
      assert_equal original, hashes(root)
      assert File.file?(File.join(root, "selection.json"))
      agent.failure = nil
      result = controller.resume
      assert_equal "succeeded", result["status"]
      current = hashes(root)
      assert_equal original.values_at("a", "c"), current.values_at("a", "c")
      refute_equal original["b"], current["b"]
      refute File.exist?(File.join(root, "selection.json"))
      assert_includes agent.calls.last[:prompt], "Less dense, keep hierarchy"
      assert_includes File.read(File.join(root, "feedback.md")), "Less dense"
      assert_equal 1, Dir.glob(File.join(root, "history/b/*/index.html")).size
      controller.select(variant: "a", decisions: ["Choose A"])
      controller.revise(variant: "b", prompt: "More whitespace")
      assert File.file?(File.join(root, "selection.json"))
    end
  end
  def test_changed_shared_input_or_worker_tampering_is_rejected
    with_runner do |runner, agent, _|
      agent.change_shared = "b"
      result = runner.generate(surface: "site", prompt: "Studio")
      assert_equal "failed", result["workers"]["b"]["status"]
      assert_includes result["workers"]["b"]["attempts"].last["error"], "modified shared input"
      root = result["session"]
      File.write(File.join(root, "fixtures.json"), '{}')
      error = assert_raises(Ace::Design::Error) { controller(root, agent).resume }
      assert_includes error.message, "create a new session"
    end
  end
  def test_dry_run_saves_templates_without_execution_and_invalid_id_creates_nothing
    with_runner do |runner, agent, base|
      assert_raises(Ace::Design::Error) do
        runner.generate(surface: "site", prompt: "Site", variant_prompts: ["unknown=Hello"])
      end
      assert_empty agent.calls
      refute Dir.exist?(File.join(base, "runs"))
      result = runner.prepare(surface: "site", prompt: "Site")
      assert_equal "prepared", result["status"]
      assert_empty agent.calls
      assert_includes File.read(File.join(result["session"], "prompts/a.md")), "will be prepared"
      assert_equal "succeeded", controller(result["session"], agent).resume["status"]
    end
  end
  def test_context_snapshot_is_reused_on_resume
    with_runner do |runner, agent, _|
      # Use a project-local file because the bundle boundary confines configured context.
      context = File.join(Dir.pwd, ".ace-local/design/context-test-#{Process.pid}.md")
      FileUtils.mkdir_p(File.dirname(context))
      File.write(context, "Original brand reference")
      begin
        result = runner.prepare(surface: "site", prompt: "Site", input: [context])
        File.write(context, "Changed later")
        controller(result["session"], agent).resume
        snapshot = File.read(File.join(result["session"], "context.md"))
        assert_includes snapshot, "Original brand reference"
        refute_includes snapshot, "Changed later"
      ensure
        File.delete(context)
      end
    end
  end
  def test_custom_slots_and_bounded_parallelism_use_preset_configuration
    with_runner do |runner, agent, base|
      FileUtils.mkdir_p(File.join(base, ".ace/design/presets"))
      File.write(File.join(base, ".ace/design/presets/custom.yml"), <<~YAML)
        concurrency: 2
        variants:
          - id: compact
            model: fixture:one
            role: Queue designer
            prompt: Keep controls visible
            focus: Dense but readable
          - id: detail
            model: fixture:two
            execution_preset: rw
          - id: overview
          - id: editorial
      YAML
      # A barrier proves two workers overlap, without a timing assertion.
      entered = Queue.new
      release = Queue.new
      agent.gate = ->(id) { entered << id; release.pop }
      result = nil
      Dir.chdir(base) do
        thread = Thread.new { result = runner.generate(surface: "app", prompt: "Custom", preset: "custom") }
        begin
          2.times do
            2.times { Timeout.timeout(5) { entered.pop } }
            2.times { release << true }
          end
          thread.value
        ensure
          4.times { release << true }
          thread.join
        end
      end
      assert_equal "succeeded", result["status"]
      assert_equal 2, agent.peak
      assert_equal %w[compact detail overview editorial], result["workers"].keys
      assert_equal "fixture:two", agent.calls.find { |c| c[:id] == "detail" }[:model]
      assert_equal 4, File.read(result["gallery"]).scan("<iframe").size
      controller(result["session"], agent).select(variant: "editorial", decisions: ["Keep it"])
    end
  end

  def test_cancellation_records_interrupted_workers_and_releases_session_lock
    with_runner do |runner, agent, _|
      root = runner.prepare(surface: "app", prompt: "Workspace")["session"]
      entered = Queue.new
      hold = Queue.new
      agent.gate = ->(id) { entered << id; hold.pop }
      thread = Thread.new do
        controller(root, agent).resume
      rescue Interrupt
        :cancelled
      end
      begin
        3.times { Timeout.timeout(5) { entered.pop } }
        error = assert_raises(Ace::Design::Error) { controller(root, agent).resume }
        assert_includes error.message, "active operation"
        thread.raise(Interrupt)
        assert_equal :cancelled, Timeout.timeout(5) { thread.value }
        saved = controller(root, agent).status
        assert_equal "interrupted", saved["status"]
        assert saved["workers"].values.all? { |w| w["status"] == "interrupted" }
        agent.gate = nil
        assert_equal "succeeded", controller(root, agent).resume["status"]
      ensure
        3.times { hold << true }
        thread.join(1)
      end
    end
  end

  def test_publication_recovery_restores_previous_revision_after_interrupted_rename
    with_runner do |runner, agent, _|
      root = runner.generate(surface: "app", prompt: "Workspace")["session"]
      previous = hashes(root)
      controller(root, agent).select(variant: "b", decisions: ["Keep B"])
      state_path = File.join(root, "run.json")
      state = JSON.parse(File.read(state_path))
      backup = File.join(root, "history/b/crash")
      FileUtils.mkdir_p(File.dirname(backup))
      File.rename(File.join(root, "variants/b"), backup)
      state["workers"]["b"]["status"] = "running"
      archived_selection = File.join(root, "history/selection-crash.json")
      File.rename(File.join(root, "selection.json"), archived_selection)
      state["publication"] = {"id" => "b", "backup" => backup, "previous" => previous["b"],
        "digest" => "uncommitted", "selection_backup" => archived_selection}
      File.write(state_path, JSON.generate(state))
      agent.failure = "b"
      controller(root, agent).resume
      assert_equal previous, hashes(root)
      assert_equal "b", Ace::Design::Molecules::Session.new(root).validate_selection["variant"]
      assert_nil controller(root, agent).status["publication"]
    end
  end

  def test_resume_from_another_project_does_not_use_its_provider_policy
    with_runner do |runner, agent, base|
      root = runner.prepare(surface: "app", prompt: "Workspace")["session"]
      result = Dir.chdir(base) { controller(root, agent).resume }
      assert_equal "failed", result["status"]
      assert_includes result["preparation"]["error"], "ace-llm policies"
      assert_empty agent.calls
    end
  end

  def test_blank_leading_lines_and_command_exit_status_do_not_abort_the_host
    with_runner do |runner, agent, _|
      agent.failure = "b"
      status = nil
      output, = capture_io do
        Ace::Design::Organisms::Generator.stub(:new, runner) do
          status = Ace::Design::CLI.start(["explore", "--json", "--surface", "site", "--prompt", "\n\nUseful title"])
        end
      end
      assert_equal 2, status
      root = JSON.parse(output).fetch("session")
      assert_equal "Useful title", JSON.parse(File.read(File.join(root, "session.json"))).fetch("title")
    end
  end

  def test_preparation_save_failure_does_not_mask_the_original_error
    with_runner do |runner, agent, _|
      root = runner.prepare(surface: "app", prompt: "Workspace")["session"]
      artifacts = Ace::Design::Molecules::Artifacts
      original = artifacts.method(:json)
      injected = false
      writer = lambda do |path, value|
        if !injected && path.end_with?("run.json") && value.dig("preparation", "status") == "running"
          injected = true
          raise Errno::ENOSPC, "test disk full"
        end
        original.call(path, value)
      end
      result = artifacts.stub(:json, writer) { controller(root, agent).resume }
      assert_equal "failed", result["status"]
      assert_includes result["preparation"]["error"], "test disk full"
      assert_kind_of Numeric, result["preparation"]["duration"]
      assert_empty agent.calls
    end
  end

  def test_persistent_preparation_write_failure_preserves_first_error_and_can_resume
    with_runner do |runner, agent, _|
      root = runner.prepare(surface: "app", prompt: "Workspace")["session"]
      artifacts = Ace::Design::Molecules::Artifacts
      original = artifacts.method(:json)
      writes = 0
      writer = lambda do |path, value|
        if path.end_with?("run.json")
          writes += 1
          raise Errno::ENOSPC, writes == 1 ? "original write failure" : "secondary write failure"
        end
        original.call(path, value)
      end
      error = assert_raises(Errno::ENOSPC) do
        artifacts.stub(:json, writer) { controller(root, agent).resume }
      end
      assert_includes error.message, "original write failure"
      assert_empty agent.calls
      assert_equal "succeeded", controller(root, agent).resume["status"]
    end
  end

  def test_worker_error_survives_persistent_diagnostic_write_failure
    with_runner do |runner, agent, _|
      root = runner.generate(surface: "app", prompt: "Workspace")["session"]
      before = hashes(root)
      disk_failed = false
      agent.failure = "b"
      agent.gate = ->(_) { disk_failed = true }
      artifacts = Ace::Design::Molecules::Artifacts
      original = artifacts.method(:json)
      writer = lambda do |path, value|
        raise Errno::ENOSPC, "secondary write failure" if disk_failed && path.end_with?("run.json")
        original.call(path, value)
      end
      error = assert_raises(RuntimeError) do
        artifacts.stub(:json, writer) { controller(root, agent).revise(variant: "b", prompt: "Less dense") }
      end
      assert_equal "Worker b failed", error.message
      assert_equal before, hashes(root)
      agent.failure = agent.gate = nil
      result = controller(root, agent).resume
      assert_equal "succeeded", result["status"]
      assert_equal before.values_at("a", "c"), hashes(root).values_at("a", "c")
    end
  end

  def test_missing_original_project_has_actionable_policy_error
    with_runner do |runner, agent, base|
      root = runner.prepare(surface: "app", prompt: "Workspace")["session"]
      file = File.join(root, "run.json")
      state = JSON.parse(File.read(file))
      state["project_root"] = File.join(base, "deleted-project")
      File.write(file, JSON.generate(state))
      result = controller(root, agent).resume
      assert_includes result["preparation"]["error"], "Run model operations from"
      assert_empty agent.calls
    end
  end

  def test_resume_inside_an_unrelated_rescue_does_not_reraise_the_handled_error
    with_runner do |runner, agent, _|
      root = runner.prepare(surface: "app", prompt: "Workspace")["session"]
      begin
        raise "Unrelated handled error"
      rescue RuntimeError
        assert_equal "succeeded", controller(root, agent).resume["status"]
      end
    end
  end

  def test_transient_interrupt_recording_failure_preserves_interrupt_and_publications
    with_runner do |runner, agent, _|
      root = runner.generate(surface: "app", prompt: "Workspace")["session"]
      before = hashes(root)
      agent.gate = ->(_) { raise Interrupt }
      artifacts = Ace::Design::Molecules::Artifacts
      original = artifacts.method(:json)
      injected = false
      writer = lambda do |path, value|
        if !injected && path.end_with?("run.json") && value.dig("workers", "b", "status") == "interrupted"
          injected = true
          raise Errno::ENOSPC, "transient recording failure"
        end
        original.call(path, value)
      end
      assert_raises(Interrupt) do
        artifacts.stub(:json, writer) { controller(root, agent).revise(variant: "b", prompt: "Less dense") }
      end
      assert injected
      assert_equal before, hashes(root)
      agent.gate = nil
      assert_equal "succeeded", controller(root, agent).resume["status"]
    end
  end

  def test_successful_preparation_does_not_swallow_its_final_persistence_error
    with_runner do |runner, agent, _|
      root = runner.prepare(surface: "app", prompt: "Workspace")["session"]
      artifacts = Ace::Design::Molecules::Artifacts
      original = artifacts.method(:json)
      writer = lambda do |path, value|
        if path.end_with?("run.json") && value.dig("preparation", "status") == "succeeded"
          raise Errno::ENOSPC, "cannot persist success"
        end
        original.call(path, value)
      end
      error = assert_raises(Errno::ENOSPC) do
        artifacts.stub(:json, writer) { controller(root, agent).resume }
      end
      assert_includes error.message, "cannot persist success"
      assert_equal ["preparation"], agent.calls.map { |c| c[:id] }
      assert_equal "succeeded", controller(root, agent).resume["status"]
    end
  end

  def test_component_session_freezes_personalized_assumptions_across_adjust_resume_and_revision
    with_runner do |runner, agent, base|
      composer = Object.new
      def composer.validate_model(*)
      end
      def composer.call(workspace:, **)
        request = JSON.parse(File.read(File.join(workspace, "request.json")))
        nodes = request.fetch("contexts").to_h do |node|
          [node.fetch("id"), {"design" => "Composed component assumptions", "added_rules" => [],
            "preserved_exceptions" => [], "omitted_defaults" => []}]
        end
        File.write(File.join(workspace, "result.json"), JSON.generate({"contexts" => nodes, "conflicts" => []}))
        {"execution" => {"status" => "succeeded"}}
      end
      Dir.chdir(base) do
        adjuster = Ace::Design::Organisms::Adjuster.new(executor: composer)
        adjuster.adjust(surface: "app", kind: "component", profile: "app/component/table", prompt: "Keep inline actions")
        result = runner.prepare(surface: "app", kind: "component", profile: "app/component/table",
          prompt: "Interactive customer table")
        root = result.fetch("session")
        saved = File.binread(File.join(root, "design.md"))
        assert_includes saved, "Keep inline actions"
        assert_equal "component", JSON.parse(File.read(File.join(root, "session.json")))["kind"]
        adjuster.adjust(surface: "app", kind: "component", profile: "app/component/table",
          prompt: "Now use a larger action area")
        assert_equal "succeeded", controller(root, agent).resume["status"]
        controller(root, agent).revise(variant: "b", prompt: "Make rows clearer")
        assert_equal saved, File.binread(File.join(root, "design.md"))
        agent.calls.each do |call|
          assert_equal saved, File.binread(File.join(call[:workspace], "design.md"))
          assert_includes call[:prompt], "One component in a minimal preview host"
          refute_includes call[:prompt], "Fast queue workflow"
        end
        File.open(File.join(root, "design.md"), "a") { |file| file.puts "Changed" }
        assert_raises(Ace::Design::Error) { controller(root, agent).resume }
      end
    end
  end

end
