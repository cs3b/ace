# frozen_string_literal: true

require "test_helper"
require "ace/assign"
require "support/lifecycle_fixtures"
require "digest"
require "open3"
require "fileutils"

# The managed binding authority (spec 8wq.t.34i): requests bind to the
# exact active MANAGED attempt of the requesting actor through the REAL
# ace-assign coordinator — wrong project, foreign requester, and ended
# attempts never acquire authority, and liveness is HELD across the
# consume/deliver critical sections.
class LabAssignmentBindingTest < AceHitlTestCase
  include LifecycleFixtures

  ACTOR = "mc"

  def setup
    super
    @cache_dir = File.join(Dir.mktmpdir("ace-hitl-managed"), "cache")
    FileUtils.mkdir_p(@cache_dir)
    @repo = File.join(@cache_dir, "candidate")
    FileUtils.mkdir_p(@repo)
    git(@repo, "init", "-b", "main")
    git(@repo, "config", "user.name", "test")
    git(@repo, "config", "user.email", "test@example.com")
    File.write(File.join(@repo, "work.txt"), "candidate work\n")
    git(@repo, "add", "work.txt")
    git(@repo, "commit", "-m", "candidate base")

    @identity = Ace::Assign::Molecules::ExecutionIdentityResolver::Identity.new(
      actor: ACTOR, role: "coordinator", runtime: "local:test", adapter: "local"
    )
    @coordinator = Ace::Assign::Organisms::AttemptCoordinator.new(
      cache_base: @cache_dir,
      repo_root: @repo,
      journal: Ace::Assign::Molecules::EvidenceJournal.new(
        repo_root: @repo,
        ref: "refs/ace/execution",
        checkout_root: File.join(@cache_dir, "evidence-co")
      ),
      identity_resolver: stub_resolver,
      lifecycle_exclusion: Ace::Assign::Molecules::LifecycleExclusion.new(
        root: File.join(@cache_dir, ".exclusion")
      )
    )
    @binding = Ace::Hitl::Providers::Lab::AssignmentBinding.new(coordinator: @coordinator)
    # Native observation is a separate public coordinator boundary. This
    # fixture tests the real assignment authority and locked transitions;
    # native owner drift/refusal belongs to the runtime-binding tests.
    @coordinator.define_singleton_method(:runtime_binding) do |attempt_id:, caller_pid:|
      raise "missing kernel caller" unless caller_pid == Process.pid
      {"session" => "workspace1", "pane" => "pane1"}
    end
  end

  def stub_resolver
    resolver = Ace::Assign::Molecules::ExecutionIdentityResolver.new(adapter: "local")
    resolver.define_singleton_method(:resolve) { @fixed_identity }
    resolver.define_singleton_method(:fixed_identity=) { |value| @fixed_identity = value }
    resolver.fixed_identity = @identity
    resolver
  end

  def create_managed_assignment
    manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: @cache_dir)
    manager.create(
      name: "hitl-managed-test",
      source_config: "job.yaml",
      task_id: "8wq.t.34i",
      project_id: "ace"
    )
  end

  def start_attempt(assignment)
    @coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
  end

  def managed_request_args(id: "hitl001", attempt: nil, assignment: nil, kind: "decision")
    request_args(
      id: id, assignment: assignment || @assignment.id,
      attempt: attempt || @attempt.attempt_id, kind: kind
    )
  end

  def git(dir, *argv)
    out, stderr, status = Open3.capture3("git", *argv, chdir: dir, stdin_data: "")
    flunk "git #{argv.join(' ')} failed: #{stderr}" unless status.success?
    out
  end

  def test_managed_request_binds_to_the_exact_active_attempt
    @assignment = create_managed_assignment
    @attempt = start_attempt(@assignment)
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity(ACTOR), binding: @binding)
      created = store.create(**managed_request_args)
      assert_equal @attempt.attempt_id, created["attempt"]
      persisted = JSON.parse(File.read(File.join(root, "requests", "hitl001.json")))
      refute persisted.key?("binding_kind")
      refute persisted.key?("work")
      assert_equal @assignment.id, persisted["assignment"]
      assert_equal ACTOR, persisted["requester"]
    end
  end

  def test_foreign_requester_and_wrong_project_never_bind
    @assignment = create_managed_assignment
    @attempt = start_attempt(@assignment)
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity("someone-else"), binding: @binding)
      error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
        store.create(**managed_request_args)
      end
      assert_match(/does not own/, error.message)
      assert_empty Dir.children(File.join(root, "requests"))

      foreign = make_store(root: root, identity: unprivileged_identity(ACTOR), binding: @binding)
      error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
        foreign.create(**request_args(
          assignment: @assignment.id, attempt: @attempt.attempt_id, project: "other-project"
        ))
      end
      assert_match(/active managed attempt/, error.message)
      assert_empty Dir.children(File.join(root, "requests"))
    end
  end

  def test_ended_attempt_cancels_the_managed_request_fail_closed
    @assignment = create_managed_assignment
    @attempt = start_attempt(@assignment)
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity(ACTOR), binding: @binding)
      store.create(**managed_request_args)

      # The attempt ends (managed receipt) AFTER the request exists.
      artifact = File.join(@repo, "evidence.txt")
      File.write(artifact, "evidence")
      receipt = {
        "attempt_id" => @attempt.attempt_id,
        "assignment_id" => @assignment.id,
        "project_id" => "ace",
        "scope" => "010",
        "operation" => "implement",
        "producer" => {"actor" => ACTOR, "role" => "coordinator", "runtime" => "local:test"},
        "head" => git(@repo, "rev-parse", "HEAD").strip,
        "verdict" => "succeeded",
        "artifacts" => [{"path" => "evidence.txt",
                         "sha256" => Digest::SHA256.hexdigest("evidence")}],
        "checks" => [{"name" => "ace-test", "verdict" => "passed"}]
      }
      receipt_path = File.join(@cache_dir, "receipt.json")
      File.write(receipt_path, JSON.generate(receipt))
      @coordinator.finish(attempt_id: @attempt.attempt_id, receipt_path: receipt_path)

      # Deliver and consume both fail closed; the request is cancelled.
      error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
        make_store(root: root, identity: root_identity, binding: @binding)
          .deliver("hitl001", stdin_reader("approved"))
      end
      assert_match(/active managed attempt|no longer active/, error.message)
      assert_equal "cancelled", JSON.parse(File.read(File.join(root, "public", "hitl001.json")))["state"]
      assert_empty Dir.children(File.join(root, "requests"))
    end
  end

  def test_transition_failures_keep_their_own_error_classes
    @assignment = create_managed_assignment
    @attempt = start_attempt(@assignment)

    # A failure INSIDE the caller's transition is NOT authority: it must
    # propagate unchanged instead of becoming a cancelling BindingError
    # (review 8x327bud).
    error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
      @binding.with_active(assignment: @assignment.id, attempt: @attempt.attempt_id,
        project: "ace", requester: ACTOR) do
        raise Ace::Hitl::Lifecycle::StateError, "vault exploded"
      end
    end
    assert_match(/vault exploded/, error.message)
  end

  def test_consume_replays_the_committed_managed_receipt
    @assignment = create_managed_assignment
    @attempt = start_attempt(@assignment)
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity(ACTOR), binding: @binding)
      store.create(**managed_request_args)
      make_store(root: root, identity: root_identity, binding: @binding)
        .deliver("hitl001", stdin_reader("approved"))

      consumed = store.consume("hitl001", timeout: 2)
      assert_equal "approved", consumed["answer"]
      replay = store.consume("hitl001", timeout: 2)
      assert_equal true, replay["replay"]
      assert_equal "approved", replay["answer"]
    end
  end
end
