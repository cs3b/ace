# frozen_string_literal: true

require_relative "../test_helper"
require "ace/herdr"

class AssignmentRecoveryTest < AceAssignTestCase
  A = Ace::Assign
  H = Ace::Herdr
  THREAD = "0123abcd-0000-4000-8000-000000000001"

  class Executor
    attr_reader :calls
    attr_accessor :thread
    def initialize
      @thread = THREAD
      @calls = []
    end
    def agent_prompt_bounded(**options)
      @calls << options
      raise H::ExecutorError, "submission outcome lost"
    end
    def pane_get_bounded(_id)
      H::Molecules::ExecutionResult.new(stdout: JSON.generate("result" => {"pane" => {
        "pane_id" => "p1", "workspace_id" => "ws1", "terminal_id" => "term1",
        "agent" => "codex", "agent_status" => "busy",
        "agent_session" => {"agent" => "codex", "kind" => "id", "value" => thread}}}),
        stderr: "", success: true, exit_code: 0)
    end
  end

  def setup
    super
    @dir = Dir.mktmpdir("assignment-recovery")
    @repo = File.join(@dir, "repo")
    FileUtils.mkdir_p(@repo)
    %w[init].each { |arg| git(arg) }
    git("config", "user.name", "test")
    git("config", "user.email", "test@example.com")
    File.write(File.join(@repo, "work.txt"), "preserved work")
    git("add", "work.txt")
    git("commit", "-m", "base")
    @cache = File.join(@dir, "assign")
    @assignment = A::Molecules::AssignmentManager.new(cache_base: @cache).create(
      name: "recover", source_config: "job.yml", task_id: "8wq.t.1w5", project_id: "ace")
    @identity = A::Molecules::ExecutionIdentityResolver::Identity.new(actor: "supervisor", role: "service",
      runtime: "native:thread", adapter: "service", process_pid: Process.pid)
    @deliveries = File.join(@repo, ".ace-local/herdr/deliveries")
    @executor = Executor.new
    @inbox = inbox
    @coordinator = coordinator
    @attempt = @coordinator.start(assignment_id: @assignment.id, step: "010", project_id: "ace",
      identity: @identity)
    @event = "inb-recovery"
    @inbox.enqueue(event: @event, attempt: @attempt.attempt_id,
      ref: {"session" => "ws1", "pane" => "p1"}, payload: "work instruction")
    @coordinator.bind_inbox(attempt_id: @attempt.attempt_id, event_id: @event, inbox: @inbox, identity: @identity)
    @record = @inbox.deliver(event: @event)
  end

  def teardown
    FileUtils.rm_rf(@dir)
    super
  end

  def git(*args)
    output, error, status = Open3.capture3("git", *args, chdir: @repo)
    assert status.success?, error
    output
  end

  def coordinator
    A::Organisms::AttemptCoordinator.new(cache_base: @cache, repo_root: @repo,
      journal: A::Molecules::EvidenceJournal.new(repo_root: @repo,
        checkout_root: File.join(@dir, "journal")),
      lifecycle_exclusion: A::Molecules::LifecycleExclusion.new(root: File.join(@dir, "exclusion")))
  end

  def inbox
    H::Organisms::Inbox.new(executor: @executor, deliveries_dir: @deliveries)
  end

  def test_managed_runtime_owner_is_produced_by_adapter_and_reobserved_after_restart
    require "ace/tmux"
    native = Object.new
    target = {"session" => "$1", "pane" => "%2", "shell_pid" => Process.ppid}
    native.define_singleton_method(:process_target) { |_pane| target }
    native.define_singleton_method(:context) { {in_runtime: true, session: "$1", pane: "%2"} }
    adapter = Ace::Tmux::RuntimeAdapter.new(backend: native)
    runtime = Object.new
    runtime.define_singleton_method(:detect) { |env:| :tmux }
    runtime.define_singleton_method(:resolve) { |_name| adapter }
    resolver = A::Molecules::ExecutionIdentityResolver.new(adapter: "local", runtime_resolver: runtime,
      caller_pid: Process.pid, env: {"ACE_RUNTIME" => "tmux", "HERDR_SESSION" => "inherited", "HERDR_PANE" => "old"})
    identity = resolver.resolve
    assert_equal Process.pid, identity.process_pid
    assert_equal "tmux", identity.runtime_binding["runtime"]
    attempt = @coordinator.start(assignment_id: @assignment.id, step: "020", project_id: "ace", identity: identity)
    Ace::Runtime.stub(:resolve, adapter) do
      snapshot = coordinator.recovery_snapshot(@assignment.id)
      projection = snapshot["attempts"].find { |item| item["attempt_id"] == attempt.attempt_id }
      assert_equal "adopt", projection["decision"]
      target["pane"] = "%reused"
      projection = coordinator.recovery_snapshot(@assignment.id)["attempts"]
        .find { |item| item["attempt_id"] == attempt.attempt_id }
      assert_equal "reconcile-required", projection["decision"]
      assert_equal "unknown", projection["liveness"]
    end
  end

  def test_uncertain_submission_after_restart_never_resends_or_changes_attempt
    before = git("rev-parse", "HEAD")
    assert_equal "uncertain", inbox.deliver(event: @event)["state"]
    snapshot = coordinator.recovery_snapshot(@assignment.id)
    assert_equal "uncertain", snapshot["inbox_events"].first["state"]
    assert_equal "running", snapshot["attempts"].first["state"]
    assert_equal "adopt", snapshot["attempts"].first["decision"]
    assert_equal 1, @executor.calls.length
    assert_equal before, git("rev-parse", "HEAD")
  end

  def test_registered_live_and_archived_records_fail_closed_when_replaced
    original = H::Molecules::DeliveryRecordStore.load(@deliveries, @event).to_h
    changes = [
      ->(data) { data["inbox"]["attempt_id"] = "different-attempt" },
      ->(data) { data["answer"] = "replaced"; data["answer_digest"] = Digest::SHA256.hexdigest("replaced") }
    ]
    changes.each do |change|
      [false, true].each do |archive|
        data = Marshal.load(Marshal.dump(original))
        change.call(data)
        path = H::Molecules::DeliveryRecordStore.save(H::Models::DeliveryRecord.from_h(data), @deliveries)
        if archive
          target = File.join(@deliveries, "archive")
          FileUtils.mkdir_p(target)
          FileUtils.mv(path, File.join(target, File.basename(path)))
        end
        snapshot = coordinator.recovery_snapshot(@assignment.id)
        assert_equal "unknown", snapshot["inbox_events"].find { |record| record["event_id"] == @event }["state"]
        assert_equal "adopt", snapshot["decision"]
        FileUtils.rm_rf(File.join(@deliveries, "archive"))
      end
    end
  end

  def test_compaction_with_same_binding_does_not_reregister_or_replay_payload
    @coordinator.bind_inbox(attempt_id: @attempt.attempt_id, event_id: @event, inbox: @inbox, identity: @identity)
    coordinator.resume(assignment_id: @assignment.id, dry_run: true)
    @coordinator.send(:journal_for).read_events(@assignment.id).then do |history|
      assert_equal 1, history.count { |event| event["type"] == "inbox_binding" }
    end
    assert_equal 1, @executor.calls.length
    assert_equal @record["binding"], @inbox.status(event: @event)["binding"]
    assert_equal "uncertain", @inbox.status(event: @event)["state"]
  end

  def test_missing_record_and_stale_target_stay_uncertain_and_never_resend
    File.unlink(H::Molecules::DeliveryRecordStore.path_for(@deliveries, @event))
    snapshot = coordinator.recovery_snapshot(@assignment.id)
    assert_equal "unknown", snapshot["inbox_events"].first["state"]
    assert_equal "adopt", snapshot["attempts"].first["decision"]
    assert_equal 1, @executor.calls.length
  end

end
