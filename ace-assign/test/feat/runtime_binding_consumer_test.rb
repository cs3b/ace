# frozen_string_literal: true

require_relative "../test_helper"
require "etc"

class RuntimeBindingConsumerTest < AceAssignTestCase
  A = Ace::Assign

  class NativeObservation
    attr_accessor :binding
    def initialize(binding)
      @binding = binding
    end
    def process_binding(pane:, caller_pid:)
      binding if binding && pane == binding["pane"] && caller_pid == binding.dig("process_identity", "pid")
    end
  end

  def setup
    super
    @dir = Dir.mktmpdir("runtime-binding")
    @repo = File.join(@dir, "repo")
    FileUtils.mkdir_p(@repo)
    git("init", "-b", "main")
    git("config", "user.name", "test")
    git("config", "user.email", "test@example.com")
    File.write(File.join(@repo, "work.txt"), "work")
    git("add", "work.txt")
    git("commit", "-m", "base")
    @cache = File.join(@dir, "cache")
    @assignment = A::Molecules::AssignmentManager.new(cache_base: @cache).create(
      name: "native-owner", source_config: "job.yml", task_id: "8wm.t.vs2", project_id: "ace")
    @journal = A::Molecules::EvidenceJournal.new(repo_root: @repo, checkout_root: File.join(@dir, "journal"))
    @coordinator = A::Organisms::AttemptCoordinator.new(cache_base: @cache, repo_root: @repo, journal: @journal,
      lifecycle_exclusion: A::Molecules::LifecycleExclusion.new(root: File.join(@dir, "exclusion")))
    @child = Process.spawn("sleep", "30")
    process = Ace::Runtime::Molecules::ProcessIdentity.new.capture(@child)
    @binding = {"runtime" => "herdr", "session" => "workspace1", "pane" => "pane1", "terminal_id" => "terminal1",
      "agent_session" => {"agent" => "codex", "kind" => "id", "value" => "0123abcd-0000-4000-8000-000000000001"},
      "agent" => "codex", "process_identity" => process}
    @native = NativeObservation.new(@binding)
    start(@binding)
  end

  def teardown
    Process.kill("TERM", @child) if @child
    Process.wait(@child) if @child
  rescue Errno::ESRCH, Errno::ECHILD
    nil
  ensure
    FileUtils.rm_rf(@dir)
    super
  end

  def start(binding)
    identity = A::Molecules::ExecutionIdentityResolver::Identity.new(actor: Etc.getpwuid(Process.uid).name,
      role: "worker", runtime: "native:owner", adapter: "service", process_pid: @child, runtime_binding: binding)
    @attempt = @coordinator.start(assignment_id: @assignment.id, step: "010", project_id: "ace", identity: identity)
  end

  def git(*args)
    output, error, status = Open3.capture3("git", *args, chdir: @repo, stdin_data: "")
    assert status.success?, error
    output.strip
  end

  def read(caller_pid: @child)
    Ace::Runtime.stub(:resolve, @native) { @coordinator.runtime_binding(attempt_id: @attempt.attempt_id, caller_pid: caller_pid) }
  end

  def test_public_read_uses_accepted_history_and_preserves_ref_and_cache
    head = git("rev-parse", "refs/ace/execution")
    events = @journal.read_events(@assignment.id)
    files = Dir.glob(File.join(@dir, "**", "*"), File::FNM_DOTMATCH).sort
    assert_equal @binding, read
    assert_equal head, git("rev-parse", "refs/ace/execution")
    assert_equal events, @journal.read_events(@assignment.id)
    assert_equal files, Dir.glob(File.join(@dir, "**", "*"), File::FNM_DOTMATCH).sort
    # Mutating a returned value must never alter the recorded reverse.
    read["pane"] = "replacement"
    assert_equal "pane1", read["pane"]
  end

  def test_same_uid_unrelated_process_cannot_claim_another_native_attempt
    assert_raises(A::AttemptErrors::UnauthorizedIdentity) { read(caller_pid: Process.pid) }
    assert_raises(A::AttemptErrors::UnauthorizedIdentity) { read(caller_pid: 0) }
  end

  def test_native_thread_change_and_dead_owner_remain_refusal
    @native.binding = @binding.merge("terminal_id" => "replacement")
    assert_raises(A::AttemptErrors::ReceiptRejected) { read }
    @native.binding = @binding
    Process.kill("TERM", @child)
    Process.wait(@child)
    assert_raises(A::AttemptErrors::ReceiptRejected) { read }
    @child = nil
  end

  def test_missing_accepted_native_binding_is_never_an_environment_fallback
    @journal.stub(:derived_attempts, []) do
      assert_raises(A::AttemptErrors::NotFound) { read }
    end
  end

  def installed_consumer(observer)
    A::Organisms::AttemptCoordinator.new(cache_base: @cache, repo_root: @repo, journal: @journal,
      lifecycle_exclusion: A::Molecules::LifecycleExclusion.new(root: File.join(@dir, "exclusion")),
      recorded_binding_observer: observer)
  end

  def without_ambient_runtime
    Ace::Runtime.stub(:resolve, ->(*) { flunk "installed reader must not discover an ambient runtime" }) { yield }
  end

  def test_installed_consumer_observes_canonical_binding_after_cache_loss
    calls = []
    consumer = installed_consumer(lambda { |binding:, caller_pid:|
      calls << [binding, caller_pid]
      @native.process_binding(pane: binding.fetch("pane"), caller_pid: caller_pid || binding.dig("process_identity", "pid"))
    })
    FileUtils.rm_rf(@cache)
    prefix = @journal.ref_value
    without_ambient_runtime do
      assert_equal @binding, consumer.runtime_binding(attempt_id: @attempt.attempt_id, caller_pid: @child)
      assert_equal @binding, consumer.runtime_binding(attempt_id: @attempt.attempt_id)
      assert_raises(A::AttemptErrors::UnauthorizedIdentity) do
        consumer.runtime_binding(attempt_id: @attempt.attempt_id, caller_pid: Process.pid)
      end
    end
    assert_equal [[@binding, @child], [@binding, nil], [@binding, Process.pid]], calls
    assert_equal prefix, @journal.ref_value
    refute Dir.exist?(@cache)
  end

  def test_installed_reader_refusal_never_uses_ambient_runtime
    consumer = installed_consumer(->(**) { raise A::AttemptErrors::EvidenceUnavailable, "selection revoked" })
    without_ambient_runtime do
      error = assert_raises(A::AttemptErrors::EvidenceUnavailable) do
        consumer.runtime_binding(attempt_id: @attempt.attempt_id, caller_pid: @child)
      end
      assert_equal "selection revoked", error.message
    end
  end

  def test_installed_observation_does_not_authorize_an_attempt_ended_during_read
    consumer = installed_consumer(lambda { |binding:, **|
      events = @journal.read_events(@assignment.id).select { |event| event["attempt_id"] == @attempt.attempt_id }
      event = A::Models::EvidenceEvent.build(type: "transition", attempt_id: @attempt.attempt_id,
        payload: {"from" => "running", "to" => "failed", "reason" => "test_terminal_race"}, previous_digest: events.last.fetch("digest"))
      @journal.append(assignment_id: @assignment.id, attempt_id: @attempt.attempt_id, events: [event])
      binding
    })
    without_ambient_runtime do
      assert_raises(A::AttemptErrors::ReceiptRejected) { consumer.runtime_binding(attempt_id: @attempt.attempt_id) }
    end
  end
end
