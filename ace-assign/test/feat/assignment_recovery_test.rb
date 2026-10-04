# frozen_string_literal: true

require_relative "../test_helper"
require "ace/herdr"
require "openssl"

class AssignmentRecoveryTest < AceAssignTestCase
  A = Ace::Assign
  H = Ace::Herdr
  KEY = OpenSSL::PKey::RSA.generate(2048)
  THREAD = "0123abcd-0000-4000-8000-000000000001"

  class Native
    attr_reader :calls
    def initialize
      @calls = []
    end
    def submit(**options)
      @calls << options
      {"accepted" => false, "error" => "submission outcome lost"}
    end
  end

  class Executor
    attr_accessor :thread
    def initialize
      @thread = THREAD
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
    @native = Native.new
    @inbox = inbox
    @coordinator = coordinator
    @attempt = @coordinator.start(assignment_id: @assignment.id, step: "010", project_id: "ace",
      identity: @identity)
    @event = "inb-recovery"
    @inbox.enqueue(event: @event, attempt: @attempt.attempt_id,
      ref: {"session" => "ws1", "pane" => "p1"}, payload: "work instruction")
    @coordinator.bind_inbox(attempt_id: @attempt.attempt_id, event_id: @event, inbox: @inbox, identity: @identity)
    @record = @inbox.deliver(event: @event)
    @proof = {"event_id" => @event, "attempt_id" => @attempt.attempt_id,
      "claim_generation" => @record["claim_generation"], "payload_sha256" => @record["payload_sha256"],
      "binding" => @record["binding"], "outcome" => "consumed",
      "observer" => {"role" => "supervisor", "id" => "observer-1"},
      "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => "native-observation:42",
        "observation" => "native consumption acknowledged"}}
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

  def inbox(key: KEY)
    H::Organisms::Inbox.new(executor: @executor, native: @native, deliveries_dir: @deliveries,
      receipt_public_key: key.public_key)
  end

  def reconcile(proof = @proof, key: KEY, consumer: @coordinator, transport: @inbox)
    path = File.join(@dir, "proof.json")
    bytes = JSON.generate(proof)
    File.binwrite(path, bytes)
    File.binwrite("#{path}.sig", key.sign(OpenSSL::Digest::SHA256.new, bytes))
    consumer.reconcile_inbox(attempt_id: @attempt.attempt_id, event_id: @event, receipt_path: path,
      inbox: transport, identity: @identity)
  end

  def events
    @coordinator.send(:journal_for).read_events(@assignment.id)
      .select { |event| event["type"] == "inbox_reconciliation" }
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

  def test_consumed_after_supervisor_restart_settles_once_without_business_effect_success
    before = git("rev-parse", "HEAD")
    assert_equal "reconcile-required", coordinator.recovery_snapshot(@assignment.id)["attempts"].first["decision"]
    assert_equal "completed", reconcile(consumer: coordinator, transport: inbox)["state"]
    assert_equal "completed", reconcile(consumer: coordinator, transport: inbox)["state"]
    assert_equal 1, events.length
    assert_equal "running", coordinator.recovery_snapshot(@assignment.id)["attempts"].first["state"]
    assert_equal 1, @native.calls.length
    assert_equal before, git("rev-parse", "HEAD")
    refute JSON.generate(events).include?("work instruction")
    refute JSON.generate(events).include?("native consumption acknowledged")
  end

  def test_registered_live_and_archived_records_fail_closed_when_replaced
    reconcile(consumer: coordinator, transport: inbox)
    original = H::Molecules::DeliveryRecordStore.load(@deliveries, @event).to_h
    changes = [
      ->(data) { data["inbox"]["attempt_id"] = "different-attempt" },
      ->(data) { data["inbox"]["receipt_key_sha256"] = "different-key" },
      ->(data) { data["answer"] = "replaced"; data["answer_digest"] = Digest::SHA256.hexdigest("replaced") },
      ->(data) { data["inbox"]["claim_generation"] += 1 }
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
        assert_equal "reconcile-required", snapshot["decision"]
        FileUtils.rm_rf(File.join(@deliveries, "archive"))
      end
    end
  end

  def test_public_inbox_consumer_uses_existing_signed_proof_and_redacts_output
    path = File.join(@dir, "proof.json")
    bytes = JSON.generate(@proof)
    File.binwrite(path, bytes)
    File.binwrite("#{path}.sig", KEY.sign(OpenSSL::Digest::SHA256.new, bytes))
    command = A::CLI::Commands::InboxReconcile.new(coordinator: @coordinator, inbox: @inbox)
    output = capture_io do
      command.call(attempt: @attempt.attempt_id, event: @event, receipt: path)
    end.first
    projection = JSON.parse(output)
    assert_equal "completed", projection["state"]
    assert_equal @attempt.attempt_id, projection["attempt_id"]
    refute output.include?("observation")
    refute output.include?("work instruction")
    assert_equal 1, events.length
  end

  def test_compaction_with_same_binding_does_not_reregister_or_replay_payload
    @coordinator.bind_inbox(attempt_id: @attempt.attempt_id, event_id: @event, inbox: @inbox, identity: @identity)
    coordinator.resume(assignment_id: @assignment.id, dry_run: true)
    @coordinator.send(:journal_for).read_events(@assignment.id).then do |history|
      assert_equal 1, history.count { |event| event["type"] == "inbox_binding" }
    end
    assert_equal 1, @native.calls.length
    assert_equal @record["binding"], @inbox.status(event: @event)["binding"]
    assert_equal "uncertain", @inbox.status(event: @event)["state"]
  end

  def test_crash_after_transport_receipt_before_consumer_journal_is_recoverable
    bytes = JSON.generate(@proof)
    @inbox.reconcile(event: @event, receipt: @proof, signed_bytes: bytes,
      signature: KEY.sign(OpenSSL::Digest::SHA256.new, bytes))
    assert_empty events
    assert_equal "completed", reconcile(consumer: coordinator, transport: inbox)["state"]
    assert_equal 1, events.length
  end

  def test_invalid_or_absent_proofs_preserve_uncertainty
    invalid = [@proof.merge("claim_generation" => 88), @proof.merge("attempt_id" => "other"),
      @proof.merge("payload_sha256" => "b" * 64), @proof.merge("binding" => @proof["binding"].merge("thread" => "other")),
      @proof.merge("observer" => {"role" => "requester", "id" => "self"}), @proof.reject { |key, _| key == "evidence" }]
    invalid.each do |proof|
      result = reconcile(proof)
      assert_equal "uncertain", result["state"]
      assert result["reconciliation_refusal"]
    end
    assert_equal "uncertain", reconcile(key: OpenSSL::PKey::RSA.generate(2048))["state"]
    assert_empty events
    assert_equal 1, @native.calls.length
  end

  def test_rotation_with_unresolved_event_refuses_new_key_and_accepts_retained_pair
    replacement = OpenSSL::PKey::RSA.generate(2048)
    result = reconcile(key: replacement, transport: inbox(key: replacement))
    assert_equal "uncertain", result["state"]
    assert_match(/public key differs/, result["reconciliation_refusal"])
    assert_equal "completed", reconcile(transport: inbox)["state"]
  end

  def test_superseded_requeues_same_event_but_does_not_restart_or_succeed_attempt
    proof = @proof.merge("outcome" => "superseded", "evidence" => {
      "kind" => "queue_evicted", "native_reference" => "eviction:42", "observation" => "cannot consume old entry"})
    assert_equal "queued", reconcile(proof)["state"]
    assert_equal "queued", reconcile(proof, consumer: coordinator)["state"]
    assert_equal "running", coordinator.recovery_snapshot(@assignment.id)["attempts"].first["state"]
    assert_equal "superseded", events.first.dig("payload", "outcome")
    @inbox.deliver(event: @event)
    result = reconcile(proof)
    assert_equal "uncertain", result["state"]
    assert result["reconciliation_refusal"]
    assert_equal 2, @native.calls.length
    assert_equal 1, events.length
  end

  def test_missing_record_and_stale_target_stay_uncertain_and_never_resend
    File.unlink(H::Molecules::DeliveryRecordStore.path_for(@deliveries, @event))
    snapshot = coordinator.recovery_snapshot(@assignment.id)
    assert_equal "unknown", snapshot["inbox_events"].first["state"]
    assert_equal "reconcile-required", snapshot["attempts"].first["decision"]
    assert_equal 1, @native.calls.length
  end
end
