# frozen_string_literal: true

require_relative "../../test_helper"
require "json"

class StatusCommandTest < AceAssignTestCase
  def run_status_command(cache_base:, **kwargs)
    command = Ace::Assign::CLI::Commands::Status.new
    with_fast_command_executor(command, cache_base: cache_base) do
      command.call(**kwargs)
    end
  end

  def capture_status_command(cache_base:, **kwargs)
    capture_io do
      run_status_command(cache_base: cache_base, **kwargs)
    end
  end

  def complete_all_steps(executor, report_path, count)
    count.times do
      executor.start_step
      executor.advance(report_path)
    end
  end

  EVIDENCE_REF = "refs/ace/execution"

  # Status JSON fixtures own their evidence state end to end: a temporary
  # candidate repository, an evidence journal bound to it, and a coordinator
  # whose lifecycle exclusion stays inside the fixture. Nothing here reaches
  # the invoking checkout's journal, evidence ref, or worktree registrations.
  def build_evidence_repo(cache_dir)
    repo = File.join(cache_dir, "evidence-repo")
    FileUtils.mkdir_p(repo)
    git_in(repo, "init", "-b", "main")
    git_in(repo, "config", "user.name", "test")
    git_in(repo, "config", "user.email", "test@example.com")
    File.write(File.join(repo, "work.txt"), "candidate work\n")
    git_in(repo, "add", "work.txt")
    git_in(repo, "commit", "-m", "candidate base")
    repo
  end

  def build_evidence_journal(cache_dir, repo)
    Ace::Assign::Molecules::EvidenceJournal.new(
      repo_root: repo, ref: EVIDENCE_REF, checkout_root: File.join(cache_dir, "evidence-co")
    )
  end

  def build_evidence_coordinator(cache_dir, repo, journal)
    identity = Ace::Assign::Molecules::ExecutionIdentityResolver::Identity.new(
      actor: "mc", role: "coordinator", runtime: "local:test", adapter: "local"
    )
    resolver = Ace::Assign::Molecules::ExecutionIdentityResolver.new(adapter: "local")
    resolver.define_singleton_method(:resolve) { identity }
    exclusion = Ace::Assign::Molecules::LifecycleExclusion.new(root: File.join(cache_dir, "lifecycle-exclusion"))
    Ace::Assign::Organisms::AttemptCoordinator.new(
      cache_base: cache_dir, repo_root: repo, journal: journal,
      identity_resolver: resolver, lifecycle_exclusion: exclusion
    )
  end

  def accept_evidence_receipt(cache_dir, repo, coordinator, attempt, operation)
    artifact = "artifact-#{attempt.attempt_id}.txt"
    File.write(File.join(repo, artifact), "evidence #{operation}")
    receipt = {
      "attempt_id" => attempt.attempt_id,
      "assignment_id" => attempt.binding.assignment_id,
      "project_id" => attempt.binding.project_id,
      "scope" => attempt.binding.scope,
      "operation" => operation,
      "producer" => {"actor" => "fork-1", "role" => "worker", "runtime" => "fork:1"},
      "head" => git_in(repo, "rev-parse", "HEAD"),
      "verdict" => "succeeded",
      "artifacts" => [{"path" => artifact, "sha256" => Digest::SHA256.hexdigest("evidence #{operation}")}],
      "checks" => [{"name" => "ace-test", "verdict" => "passed"}]
    }
    if operation == "review"
      receipt["review"] = {"reviewer" => {"actor" => "codex", "runtime" => "reviewer:r1"},
        "verdict" => "approved", "head" => receipt["head"]}
    end
    path = File.join(cache_dir, "receipt-#{attempt.attempt_id}.json")
    File.write(path, JSON.generate(receipt))
    coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: path)
  end

  # Deliberate component seam (spec 8ws.t.ibk): route the status command's
  # class-level EvidenceCalculator.calculate call to a real calculator bound
  # to the fixture's cache, repository, and journal, so the calculation and
  # serialization under assertion stay real while ambient state stays out.
  def with_isolated_evidence_calculator(cache_base:, repo_root:, journal:)
    calculator = Ace::Assign::Molecules::EvidenceCalculator.new(
      cache_base: cache_base, repo_root: repo_root, journal: journal
    )
    original = Ace::Assign::Molecules::EvidenceCalculator.singleton_method(:calculate)
    Ace::Assign::Molecules::EvidenceCalculator.define_singleton_method(:calculate) do |**kwargs|
      calculator.calculate(**kwargs)
    end
    yield
  ensure
    if original
      Ace::Assign::Molecules::EvidenceCalculator.define_singleton_method(:calculate, original)
    end
  end

  # Register a running attempt in the local attempt store only (no journal
  # events): mirrors a crash window where journaling never happened.
  def claim_local_store_attempt(manager, assignment, base_head:)
    attempt_binding = Ace::Assign::Models::AttemptBinding.new(
      attempt_id: "atusa01", assignment_id: assignment.id, scope: "010", project_id: "ace",
      actor: "mc", role: "coordinator", runtime: "local:test", base_head: base_head,
      task_id: assignment.task_id, created_at: Time.now.utc
    )
    attempt = Ace::Assign::Models::Attempt.new(binding: attempt_binding, state: "running")
    manager.attempt_store.save(attempt)
    manager.attempt_store.with_lock(assignment.id) { manager.attempt_store.claim(assignment.id, "010", attempt) }
    attempt
  end

  def test_status_without_assignment
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      error = assert_raises(Ace::Support::Cli::Error) do
        run_status_command(cache_base: cache_dir)
      end

      assert_equal 2, error.exit_code
      assert_includes error.message, "No active assignment"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_compact_is_default_and_under_ten_lines
    with_temp_cache do |cache_dir|
      steps = [
        {"name" => "onboard", "instructions" => "Load context"},
        {"name" => "plan", "instructions" => "Plan work"},
        {"name" => "work", "instructions" => "Do work"},
        {"name" => "verify", "instructions" => "Verify output"},
        {"name" => "release", "instructions" => "Release"},
        {"name" => "retro", "instructions" => "Retrospective"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)

      output = capture_status_command(cache_base: cache_dir).first
      lines = output.lines.map(&:chomp)

      assert_operator lines.length, :<=, 10
      assert_includes lines.first, "Assignment:"
      assert_includes lines.first, "Status:"
      assert_includes lines.first, "Status: paused"
      assert_includes lines.first, "Next: 010 onboard"
      assert_equal "Last done: none", lines[1]
      assert_equal "Pending steps:", lines[2]
      assert_includes output, "010 next onboard"
      assert_includes lines.last, "Steps:"
      assert_includes lines.last, "Pending: 6"
      refute_includes output, "Instructions:"
      refute_includes output, "QUEUE - Assignment:"
      refute_includes output, "Preview:"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_progress_mode_prints_single_line
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)

      output = capture_status_command(cache_base: cache_dir, mode: "progress").first
      assert_equal 1, output.lines.count
      assert_includes output, "State: paused"
      assert_includes output, "Progress: 0/3 done"
      assert_includes output, "Next: 010 init"
      refute_includes output, "Preview:"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_uses_marked_batch_parent_as_next_step_globally
    with_temp_cache do |cache_dir|
      steps = [
        {"number" => "000", "name" => "onboard", "instructions" => "Load context"},
        {"number" => "010", "name" => "batch-tasks", "instructions" => "Batch container instructions", "batch_parent" => true, "parallel" => false, "fork_retry_limit" => 1},
        {"number" => "010.01", "name" => "work-on-148", "parent" => "010", "context" => "fork", "instructions" => "Task context:\nWork on task 148"},
        {"number" => "020", "name" => "finalize", "instructions" => "Finalize"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      report = create_report(cache_dir, "done")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      executor.start_step
      executor.advance(report)

      output = capture_status_command(cache_base: cache_dir, assignment: result[:assignment].id).first

      assert_includes output, "Next: 010 batch-tasks"
      refute_includes output, "Next: 010.01 work-on-148"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_uses_pending_fork_root_as_next_step_globally
    with_temp_cache do |cache_dir|
      steps = [
        {"number" => "010", "name" => "precheck", "instructions" => "Precheck"},
        {"number" => "020", "name" => "review-cycle", "instructions" => "Review cycle", "context" => "fork"},
        {"number" => "020.01", "name" => "review-pr", "parent" => "020", "instructions" => "Review PR"},
        {"number" => "030", "name" => "postcheck", "instructions" => "Postcheck"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      report = create_report(cache_dir, "done")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      executor.start_step
      executor.advance(report)

      output = capture_status_command(cache_base: cache_dir, assignment: result[:assignment].id).first

      assert_includes output, "Next: 020 review-cycle"
      refute_includes output, "Next: 020.01 review-pr"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_uses_default_target_env_when_assignment_flag_missing
    with_temp_cache do |cache_dir|
      steps = [
        {"number" => "010", "name" => "precheck", "instructions" => "Precheck"},
        {"number" => "020", "name" => "review-cycle", "instructions" => "Review cycle", "context" => "fork"},
        {"number" => "020.01", "name" => "review-pr", "parent" => "020", "instructions" => "Review PR"},
        {"number" => "020.02", "name" => "release", "parent" => "020", "instructions" => "Release"},
        {"number" => "030", "name" => "postcheck", "instructions" => "Postcheck"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)

      previous = ENV["ACE_ASSIGN_DEFAULT_TARGET"]
      ENV["ACE_ASSIGN_DEFAULT_TARGET"] = "#{result[:assignment].id}@020"

      output = capture_status_command(cache_base: cache_dir).first

      assert_includes output, "Next: 020.01 review-pr"
      refute_includes output, "Next: 010 precheck"
      refute_includes output, "030 next postcheck"
    ensure
      if previous.nil?
        ENV.delete("ACE_ASSIGN_DEFAULT_TARGET")
      else
        ENV["ACE_ASSIGN_DEFAULT_TARGET"] = previous
      end
      Ace::Assign.reset_config!
    end
  end

  def test_status_compact_completed_assignment_reads_cleanly
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report = create_report(cache_dir, "done")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      complete_all_steps(executor, report, 3)

      output = capture_status_command(cache_base: cache_dir, assignment: result[:assignment].id).first
      lines = output.lines.map(&:chomp)

      assert_includes lines[0], "Assignment: #{result[:assignment].id}"
      assert_includes lines[0], "Status: completed"
      assert_equal "Last done: 030 test", lines[1]
      assert_includes lines[2], "Steps:"
      assert_includes lines[2], "3/3 done"
      refute_includes output, "Pending: none"
      refute_includes output, "current: none"
      refute_includes output, "Preview:"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_compact_completed_assignment_hides_failed_retry_history_from_pending_preview
    with_temp_cache do |cache_dir|
      steps = [
        {"name" => "analyze", "instructions" => "Analyze requirements"},
        {"name" => "implement", "instructions" => "Implement change"},
        {"name" => "verify", "instructions" => "Verify output"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      report = create_report(cache_dir, "done")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      executor.start_step
      executor.advance(report)
      executor.start_step

      failed_report = create_report(cache_dir, "HITL: stalled implementation requires fix")
      executor.fail(failed_report)
      output = capture_io do
        Ace::Assign::CLI::Commands::RetryCmd.new.call(step_ref: "020")
      end
      executor.start_step
      executor.advance(report)
      executor.start_step
      executor.advance(report)

      status_output = capture_status_command(cache_base: cache_dir, assignment: result[:assignment].id).first

      assert_includes output.first, "retry of 020"
      assert_includes status_output, "Status: completed"
      refute_includes status_output, "Pending steps:"
      refute_includes status_output, "020 failed implement"
      refute_includes status_output, "Failed steps:"
      assert_includes status_output, "Pending: 0"
      assert_includes status_output, "Failed: 1"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_full_mode_prints_tree_without_instructions
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "fork" => {"provider" => "codex:gpt-fit"},
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)

      output = capture_status_command(cache_base: cache_dir, mode: "full", assignment: "#{result[:assignment].id}@010").first

      assert_includes output, "QUEUE - Assignment:"
      assert_includes output, "Next Step: 010.01 - onboard"
      assert_includes output, "Fork Provider: codex:gpt-fit"
      refute_includes output, "Instructions:"
      refute_includes output, "Fork subtree detected"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_full_mode_shows_hitl_guidance
    with_temp_cache do |cache_dir|
      steps = [
        {"name" => "decision-point", "instructions" => "Need human judgment"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      step_path = File.join(cache_dir, result[:assignment].id, "steps", "010-decision-point.st.md")
      Ace::Assign::Molecules::StepWriter.new.update_frontmatter(
        step_path,
        {"stall_reason" => "HITL: htl123 .ace-local/hitl/next/htl123-need-decision.md"}
      )
      executor.start_step

      output = capture_status_command(cache_base: cache_dir, mode: "full", assignment: result[:assignment].id).first

      assert_includes output, "HITL Guidance:"
      assert_includes output, "ace-hitl show htl123"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_json_reports_active_steps_and_next_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)

      repo = build_evidence_repo(cache_dir)
      journal = build_evidence_journal(cache_dir, repo)
      with_isolated_evidence_calculator(cache_base: cache_dir, repo_root: repo, journal: journal) do
        output = capture_status_command(cache_base: cache_dir, format: "json")
        payload = JSON.parse(output.first)

        assert_equal result[:assignment].id, payload.dig("assignment", "id")
        assert_equal "paused", payload.dig("assignment", "state")
        assert_equal "0/3 done", payload["progress"]
        assert_equal [], payload["active_steps"]
        assert_equal "010", payload.dig("next_step", "number")
        assert_equal "init", payload.dig("next_step", "name")
      end
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_json_evidence_reflects_the_displayed_assignment
    with_temp_cache do |cache_dir|
      repo = build_evidence_repo(cache_dir)
      journal = build_evidence_journal(cache_dir, repo)
      coordinator = build_evidence_coordinator(cache_dir, repo, journal)
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)
      shown = manager.create(name: "shown", source_config: "job.yaml", task_id: "148", project_id: "ace")
      other = manager.create(name: "other", source_config: "job.yaml", task_id: "149", project_id: "ace")
      Ace::Assign.config["cache_dir"] = cache_dir

      shown_attempt = coordinator.start(assignment_id: shown.id, step: "010", project_id: "ace")
      other_attempt = coordinator.start(assignment_id: other.id, step: "010", project_id: "ace")
      accept_evidence_receipt(cache_dir, repo, coordinator, other_attempt, "review")

      with_isolated_evidence_calculator(cache_base: cache_dir, repo_root: repo, journal: journal) do
        payload = JSON.parse(capture_status_command(cache_base: cache_dir, format: "json", assignment: shown.id).first)

        assert_equal shown_attempt.attempt_id, payload.dig("attempt", "attempt_id")
        assert_equal "running", payload.dig("attempt", "state")
        assert_equal shown_attempt.binding.base_head, payload["base_head"]
        assert_nil payload["candidate_head"]
        assert_equal EVIDENCE_REF, payload["evidence_git_ref"]
        assert_equal journal.ref_value, payload["journal_commit"]
        # The other assignment's accepted review receipt must not leak into
        # the displayed assignment's evidence.
        assert_equal "missing", payload["review_receipt"]
        assert_equal "open", payload["feedback_state"]

        other_payload = JSON.parse(capture_status_command(cache_base: cache_dir, format: "json", assignment: other.id).first)
        assert_equal other_attempt.attempt_id, other_payload.dig("attempt", "attempt_id")
        refute_equal shown_attempt.attempt_id, other_payload.dig("attempt", "attempt_id")
        assert_equal "succeeded", other_payload.dig("attempt", "state")
        assert_equal "current", other_payload["review_receipt"]
        assert_equal git_in(repo, "rev-parse", "HEAD"), other_payload["candidate_head"]
      end
    ensure
      Ace::Assign.reset_config!
    end
  end

  # Sentinel repository standing in for the invoking checkout: pre-existing
  # evidence ref, a registered detached worktree, and identifiable files.
  # The status flow runs while the sentinel is the ambient repository; its
  # refs, registrations, and files must be identical before and after.
  def build_sentinel_repo(cache_dir)
    sentinel = File.join(cache_dir, "sentinel")
    FileUtils.mkdir_p(sentinel)
    git_in(sentinel, "init", "-b", "main")
    git_in(sentinel, "config", "user.name", "test")
    git_in(sentinel, "config", "user.email", "test@example.com")
    File.write(File.join(sentinel, "README.md"), "sentinel baseline\n")
    git_in(sentinel, "add", "README.md")
    git_in(sentinel, "commit", "-m", "sentinel base")
    seed_evidence_ref(sentinel)
    git_in(sentinel, "worktree", "add", "--detach", File.join(cache_dir, "sentinel-worktree"), "HEAD")
    File.write(File.join(sentinel, "operator-note.txt"), "operator state\n")
    sentinel
  end

  def seed_evidence_ref(repo)
    empty_tree = git_in(repo, "mktree")
    seed = git_in(repo, "-c", "user.name=test", "-c", "user.email=test@example.com",
      "commit-tree", empty_tree, "-m", "seed: sentinel evidence")
    git_in(repo, "update-ref", EVIDENCE_REF, seed, "0" * 40)
    seed
  end

  def sentinel_snapshot(repo)
    {
      evidence_ref: git_in(repo, "rev-parse", "--verify", "--quiet", EVIDENCE_REF),
      worktrees: git_in(repo, "worktree", "list", "--porcelain"),
      files: Dir.glob(File.join(repo, "**", "*"), File::FNM_DOTMATCH)
        .select { |path| File.file?(path) && !path.include?("/.git/") }
        .sort
        .map { |path| [path.delete_prefix("#{repo}/"), Digest::SHA256.file(path).hexdigest] }
    }
  end

  def with_ambient_repo(repo)
    previous_root = ENV["PROJECT_ROOT_PATH"]
    previous_dir = Dir.pwd
    ENV["PROJECT_ROOT_PATH"] = repo
    Dir.chdir(repo)
    begin
      yield
    ensure
      Dir.chdir(previous_dir)
      if previous_root.nil?
        ENV.delete("PROJECT_ROOT_PATH")
      else
        ENV["PROJECT_ROOT_PATH"] = previous_root
      end
    end
  end

  def test_status_json_leaves_ambient_repository_evidence_state_untouched
    with_temp_cache do |cache_dir|
      sentinel = build_sentinel_repo(cache_dir)
      before = sentinel_snapshot(sentinel)

      repo = build_evidence_repo(cache_dir)
      journal = build_evidence_journal(cache_dir, repo)
      coordinator = build_evidence_coordinator(cache_dir, repo, journal)
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)
      shown = manager.create(name: "shown", source_config: "job.yaml", task_id: "148", project_id: "ace")
      other = manager.create(name: "other", source_config: "job.yaml", task_id: "149", project_id: "ace")
      Ace::Assign.config["cache_dir"] = cache_dir

      shown_attempt = coordinator.start(assignment_id: shown.id, step: "010", project_id: "ace")
      other_attempt = coordinator.start(assignment_id: other.id, step: "010", project_id: "ace")
      accept_evidence_receipt(cache_dir, repo, coordinator, other_attempt, "review")

      with_ambient_repo(sentinel) do
        with_isolated_evidence_calculator(cache_base: cache_dir, repo_root: repo, journal: journal) do
          payload = JSON.parse(capture_status_command(cache_base: cache_dir, format: "json", assignment: shown.id).first)
          assert_equal shown_attempt.attempt_id, payload.dig("attempt", "attempt_id")
          assert_equal shown_attempt.binding.base_head, payload["base_head"]

          other_payload = JSON.parse(capture_status_command(cache_base: cache_dir, format: "json", assignment: other.id).first)
          assert_equal other_attempt.attempt_id, other_payload.dig("attempt", "attempt_id")
        end
      end

      assert_equal before, sentinel_snapshot(sentinel)
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_json_with_absent_fixture_evidence_ref_is_fixture_derived
    with_temp_cache do |cache_dir|
      sentinel = build_sentinel_repo(cache_dir)
      before = sentinel_snapshot(sentinel)

      repo = build_evidence_repo(cache_dir)
      journal = build_evidence_journal(cache_dir, repo)
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)
      shown = manager.create(name: "shown", source_config: "job.yaml", task_id: "148", project_id: "ace")
      Ace::Assign.config["cache_dir"] = cache_dir
      claim_local_store_attempt(manager, shown, base_head: git_in(repo, "rev-parse", "HEAD"))

      with_ambient_repo(sentinel) do
        with_isolated_evidence_calculator(cache_base: cache_dir, repo_root: repo, journal: journal) do
          payload = JSON.parse(capture_status_command(cache_base: cache_dir, format: "json", assignment: shown.id).first)

          assert_equal "atusa01", payload.dig("attempt", "attempt_id")
          assert_nil payload["journal_commit"]
          assert_equal EVIDENCE_REF, payload["evidence_git_ref"]
        end
      end

      assert_equal before, sentinel_snapshot(sentinel)
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_json_with_seed_only_fixture_evidence_ref_is_fixture_derived
    with_temp_cache do |cache_dir|
      sentinel = build_sentinel_repo(cache_dir)
      before = sentinel_snapshot(sentinel)

      repo = build_evidence_repo(cache_dir)
      journal = build_evidence_journal(cache_dir, repo)
      seed = seed_evidence_ref(repo)
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)
      shown = manager.create(name: "shown", source_config: "job.yaml", task_id: "148", project_id: "ace")
      Ace::Assign.config["cache_dir"] = cache_dir
      claim_local_store_attempt(manager, shown, base_head: git_in(repo, "rev-parse", "HEAD"))

      with_ambient_repo(sentinel) do
        with_isolated_evidence_calculator(cache_base: cache_dir, repo_root: repo, journal: journal) do
          payload = JSON.parse(capture_status_command(cache_base: cache_dir, format: "json", assignment: shown.id).first)

          assert_equal "atusa01", payload.dig("attempt", "attempt_id")
          assert_equal seed, payload["journal_commit"]
          assert_equal EVIDENCE_REF, payload["evidence_git_ref"]
        end
      end

      assert_equal before, sentinel_snapshot(sentinel)
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_json_with_stale_fixture_checkout_recovers_within_fixture_repo
    with_temp_cache do |cache_dir|
      repo = build_evidence_repo(cache_dir)
      journal = build_evidence_journal(cache_dir, repo)
      checkout_dir = File.join(cache_dir, "evidence-co", "journal")
      coordinator = build_evidence_coordinator(cache_dir, repo, journal)
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)
      shown = manager.create(name: "shown", source_config: "job.yaml", task_id: "148", project_id: "ace")
      Ace::Assign.config["cache_dir"] = cache_dir

      attempt = coordinator.start(assignment_id: shown.id, step: "010", project_id: "ace")
      assert Dir.exist?(checkout_dir)

      # Drop the fixture checkout, leaving a stale worktree registration in
      # the fixture repository. Recovery must prune and rebuild only there.
      FileUtils.rm_rf(File.join(cache_dir, "evidence-co"))
      transition = Ace::Assign::Models::EvidenceEvent.build(
        type: "transition", attempt_id: attempt.attempt_id,
        payload: {"from" => "running", "to" => "uncertain", "reason" => "fixture stale checkout"}
      )
      journal.append(assignment_id: shown.id, attempt_id: attempt.attempt_id, events: [transition])

      assert Dir.exist?(checkout_dir)
      assert_includes git_in(repo, "worktree", "list", "--porcelain"), File.realpath(checkout_dir)

      with_isolated_evidence_calculator(cache_base: cache_dir, repo_root: repo, journal: journal) do
        payload = JSON.parse(capture_status_command(cache_base: cache_dir, format: "json", assignment: shown.id).first)

        assert_equal attempt.attempt_id, payload.dig("attempt", "attempt_id")
        assert_equal "uncertain", payload.dig("attempt", "state")
        assert_includes payload["unresolved_effects"], "#{attempt.attempt_id}:uncertain"
        assert_equal journal.ref_value, payload["journal_commit"]
      end
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_json_with_scope_uses_scope_root_fork_provider_for_next_step
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "fork" => {"provider" => "codex:gpt-fit"},
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)

      repo = build_evidence_repo(cache_dir)
      journal = build_evidence_journal(cache_dir, repo)
      with_isolated_evidence_calculator(cache_base: cache_dir, repo_root: repo, journal: journal) do
        output = capture_status_command(cache_base: cache_dir, format: "json", assignment: "#{result[:assignment].id}@010")
        payload = JSON.parse(output.first)

        assert_equal [], payload["active_steps"]
        assert_equal "010.01", payload.dig("next_step", "number")
        assert_equal "codex:gpt-fit", payload.dig("next_step", "fork_provider")
      end
    ensure
      Ace::Assign.reset_config!
    end
  end
end
