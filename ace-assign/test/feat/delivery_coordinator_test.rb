# frozen_string_literal: true
require_relative "../test_helper"
require "open3"

class DeliveryCoordinatorTest < AceAssignTestCase
  SERVER_URL = "https://forge.example/team/repo"
  FORK_URL = "https://forge.example/team/fork"

  class ControlledProvider < Ace::Git::Providers::Base
    def initialize(server:, io:)
      super(server: server)
      @io = io
    end
    def pull_request(number:)
      @io.fetch(:prs).find { |pr| pr.number == number } || raise(Ace::Git::ProviderObjectNotFoundError)
    end
    def find_open_pull_requests(**selector)
      @io[:reads] += 1
      @io[:prs].select do |pr|
        pr.state == :open && pr.head_ref == selector[:head_ref] && pr.base_ref == selector[:base_ref] &&
          Ace::Git::Atoms::ServerUrl.match?(pr.head_repository_url, selector[:head_repository_url]) &&
          Ace::Git::Atoms::ServerUrl.match?(pr.base_repository_url, selector[:base_repository_url])
      end
    end
    def create_pull_request(head_ref:, head_repository_url:, base_ref:, expected_head:, title:, body:, draft:)
      @io[:writes] << :create
      pr = Ace::Git::ProviderPullRequest.new(server_name: server.name, number: 1, title: title, body: body,
        state: :open, head_ref: head_ref, base_ref: base_ref, head_sha: expected_head, author: "worker",
        url: "#{server.url}/pull/1", draft: draft, merged_at: nil, head_repository_url: head_repository_url,
        base_repository_url: server.url, merge_commit_sha: nil)
      @io[:prs] << pr
      raise Ace::Git::ProviderUnknownOutcomeError, "Response lost" if @io[:lose_create]
      receipt(:create, pr)
    end
    def ready_pull_request(number:, expected_head:)
      pr = pull_request(number: number)
      raise Ace::Git::ProviderExpectedHeadConflictError unless pr.head_sha == expected_head
      @io[:writes] << :ready
      pr = pr.with(draft: false)
      @io[:prs] = [pr]
      raise Ace::Git::ProviderUnknownOutcomeError if @io[:lose_ready]
      receipt(:ready, pr)
    end
    def update_pull_request(number:, expected_head:, title:, body:)
      pr = pull_request(number: number)
      raise Ace::Git::ProviderExpectedHeadConflictError unless pr.head_sha == expected_head
      @io[:writes] << :update
      pr = pr.with(title: title || pr.title, body: body || pr.body)
      @io[:prs] = [pr]
      raise Ace::Git::ProviderUnknownOutcomeError if @io[:lose_update]
      receipt(:update, pr)
    end
    def pull_request_body(number:) = pull_request(number: number).body
    def pull_request_review_details(number:)
      Ace::Git::ProviderReviewDetails.new(server_name: server.name, repository_url: server.url,
        pr_number: number, base_sha: "b" * 40, files: [])
    end
    def pull_request_diff(number:) = "diff --git a/work.txt b/work.txt"
    def pull_request_review_evidence(number:, expected_head:)
      Ace::Git::ProviderReviewEvidence.new(server_name: server.name, repository_url: server.url,
        pr_number: number, head_sha: expected_head, comments: [], reviews: [])
    end
    def pull_request_checks(number:, head_sha:)
      [Ace::Git::ProviderCheck.new(server_name: server.name, name: "CI", state: :completed,
        conclusion: :failure, url: "#{server.url}/checks/1")]
    end
    def receipt(operation, pr)
      Ace::Git::ProviderMutationReceipt.new(server_name: server.name, operation: operation,
        pull_request: pr, idempotency: operation == :create ? :created : nil)
    end
  end

  def setup
    super
    with_temp_cache { |dir| @cache = dir }
    @repo = File.join(@cache, "candidate")
    @remote = File.join(@cache, "remote.git")
    FileUtils.mkdir_p(@repo)
    git(@repo, "init", "-b", "main")
    git(@repo, "config", "user.name", "test")
    git(@repo, "config", "user.email", "test@example.com")
    File.write(File.join(@repo, "work.txt"), "work")
    git(@repo, "add", ".")
    git(@repo, "commit", "-m", "base")
    git(@repo, "init", "--bare", @remote)
    git(@repo, "push", @remote, "HEAD:refs/heads/feature")
    git(@repo, "remote", "add", "origin", SERVER_URL)
    @journal = Ace::Assign::Molecules::EvidenceJournal.new(repo_root: @repo,
      checkout_root: File.join(@cache, "journal"))
    @exclusion = Ace::Assign::Molecules::LifecycleExclusion.new(root: File.join(@cache, "locks"))
    @coordinator = Ace::Assign::Organisms::AttemptCoordinator.new(cache_base: @cache, repo_root: @repo,
      journal: @journal, lifecycle_exclusion: @exclusion)
    manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: @cache)
    @assignment = manager.create(name: "delivery", source_config: "job.yml", task_id: "8wr.t.qkb.0", project_id: "ace")
    @identity = Ace::Assign::Molecules::ExecutionIdentityResolver::Identity.new(actor: "coordinator",
      role: "coordinator", runtime: "local:test", adapter: "local")
    @io = {prs: [], writes: [], reads: 0}
    configure("forgejo", "named")
  end

  def teardown
    Ace::Git.reset_config!
    super
  end

  def configure(provider, selection)
    servers = [{"name" => "named", "provider" => provider, "url" => SERVER_URL, "default" => true}]
    Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge("servers" => servers))
    @parameters = {"pr_provenance" => {"mode" => "canonical", "head_repository_url" => SERVER_URL,
      "head_ref" => "feature", "base_repository_url" => SERVER_URL, "base_ref" => "main"}}
    @parameters["forge_server"] = "named" if selection == "named"
    @parameters["forge_default"] = true if selection == "default"
  end

  def delivery
    io = @io
    factory = ->(selection) do
      lifecycle = Ace::Git::Organisms::PullRequestLifecycle.new(**selection)
      lifecycle.define_singleton_method(:provider_for) { |server| ControlledProvider.new(server: server, io: io) }
      lifecycle
    end
    coordinator = Ace::Assign::Organisms::DeliveryCoordinator.new(repo_root: @repo, coordinator: @coordinator,
      journal: @journal, lifecycle_factory: factory, exclusion: @exclusion)
    # Controlled transport maps the selected remote to a real bare Git
    # fixture; server resolution still reads the unmodified repository URL.
    remote = @remote
    native_git = coordinator.method(:git!)
    coordinator.define_singleton_method(:git!) do |*argv|
      argv[2] = remote if argv[0] == "ls-remote"
      native_git.call(*argv)
    end
    coordinator
  end

  def start(scope)
    @coordinator.start(assignment_id: @assignment.id, step: scope, project_id: "ace", identity: @identity)
  end

  def accept(operation, scope)
    attempt = start(scope)
    File.write(File.join(@repo, "#{scope}.txt"), "executed #{operation}")
    receipt = {"attempt_id" => attempt.attempt_id, "assignment_id" => @assignment.id,
      "project_id" => "ace", "scope" => scope, "operation" => operation,
      "producer" => {"actor" => "worker", "role" => "worker", "runtime" => "fork:worker"},
      "head" => git(@repo, "rev-parse", "HEAD").strip, "verdict" => "succeeded",
      "artifacts" => [{"path" => "#{scope}.txt", "sha256" => Digest::SHA256.hexdigest("executed #{operation}")}],
      "checks" => [{"name" => "tests", "verdict" => "passed"}]}
    receipt["review"] = {"reviewer" => {"actor" => "independent"}, "verdict" => "approved",
      "head" => receipt["head"]} if operation == "review"
    path = File.join(@cache, "#{scope}.json")
    File.write(path, JSON.generate(receipt))
    finished = @coordinator.finish(attempt_id: attempt.attempt_id, receipt_path: path, identity: @identity)
    {"attempt_id" => attempt.attempt_id, "receipt_digest" => finished.accepted_receipts.last.fetch("digest")}
  end

  def perform(operation, **options)
    @delivery_attempt ||= start("030")
    delivery.perform(assignment_id: @assignment.id, attempt_id: @delivery_attempt.attempt_id,
      operation: operation, parameters: @parameters, **options)
  end

  def git(dir, *argv)
    out, err, status = Open3.capture3("git", *argv, chdir: dir)
    assert status.success?, err
    out
  end

  def test_exact_draft_review_ready_matrix_and_journal_head_separation
    [["github", "remote"], ["forgejo", "default"], ["forgejo", "named"]].product(%w[canonical fork]).map { |selection, mode| selection + [mode] }.each_with_index do |(provider, selection, mode), index|
      # Each iteration is a distinct assignment with independent journal history.
      configure(provider, selection)
      @assignment = Ace::Assign::Molecules::AssignmentManager.new(cache_base: @cache).create(
        name: "matrix-#{index}", source_config: "job.yml", task_id: "8wr.t.qkb.0", project_id: "ace")
      @parameters["pr_provenance"].merge!("mode" => mode, "head_repository_url" => mode == "fork" ? FORK_URL : SERVER_URL)
      @io[:prs] = []; @io[:writes] = []; @delivery_attempt = nil
      tests = accept("test", "010"); review = accept("review", "020")
      before = git(@repo, "rev-parse", "HEAD").strip
      created = perform("create", title: "Reviewed task")
      assert_equal before, created["candidate_head"]
      authoritative = @coordinator.authoritative_attempt({"assignment_id" => @assignment.id,
        "attempt_id" => @delivery_attempt.attempt_id})
      assert_equal before, authoritative.candidate_head
      assert_equal before, git(@repo, "rev-parse", "HEAD").strip
      assert_equal true, @io[:prs].first.draft
      ready = perform("ready", tests: tests, review: review)
      assert_equal false, @io[:prs].first.draft
      assert_equal %i[create ready], @io[:writes]
      assert_equal provider, ready["delivery"].first.dig("server", "provider")
      assert_equal mode, ready["delivery"].first.dig("provenance", "mode")
      assert Ace::Assign::Models::EvidenceEvent.chain_valid?(@journal.read_events(@assignment.id).select { |event| event["attempt_id"] == @delivery_attempt.attempt_id })
    end
  end

  def test_lost_create_and_crash_before_result_reconcile_without_second_write
    @io[:lose_create] = true
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { perform("create", title: "Task") }
    @io[:lose_create] = false
    result = perform("create", title: "Task")
    assert_equal [:create], @io[:writes]
    assert_equal "succeeded", result["delivery"].last["outcome"]
  end

  def test_fresh_status_is_read_only_and_does_not_freeze_selection
    @delivery_attempt = start("030")
    before = @journal.ref_value
    2.times { assert_empty perform("status")["delivery"] }
    assert_equal before, @journal.ref_value
    assert_empty @io[:writes]
    configure("forgejo", "named")
    perform("create", title: "Task")
    assert_equal "forgejo", perform("status")["delivery"].first.dig("server", "provider")
  end

  def test_lost_ready_and_update_reconcile_exact_outcome_without_second_write
    tests = accept("test", "010"); review = accept("review", "020")
    perform("create", title: "Task")
    @io[:lose_update] = true
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { perform("update", title: "Final", body: "Description") }
    @io[:lose_update] = false
    perform("update", title: "Final", body: "Description")
    @io[:lose_ready] = true
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { perform("ready", tests: tests, review: review) }
    @io[:lose_ready] = false
    perform("ready")
    assert_equal %i[create update ready], @io[:writes]
  end

  def test_crash_after_provider_apply_before_result_journal_recovers
    original = @journal.method(:record)
    crash = true
    @journal.define_singleton_method(:record) do |**args|
      raise IOError, "simulated receipt persistence crash" if crash && args.dig(:payload, "stage") == "result"
      original.call(**args)
    end
    assert_raises(IOError) { perform("create", title: "Task") }
    crash = false
    perform("create", title: "Task")
    assert_equal [:create], @io[:writes]
  end

  def test_remote_review_retains_red_ci_without_vetoing_ready
    tests = accept("test", "010"); review = accept("review", "020")
    perform("create", title: "Task")
    snapshot = perform("review")
    assert_equal :failure, snapshot.checks.first.conclusion
    perform("ready", tests: tests, review: review)
    assert_equal false, @io[:prs].first.draft
  end

  def test_merge_consumes_exact_existing_service_receipt_and_never_dispatches_worker_merge
    tests = accept("test", "010"); review = accept("review", "020")
    perform("create", title: "Task")
    perform("ready", tests: tests, review: review)
    head = git(@repo, "rev-parse", "HEAD").strip
    binding = {"request_id" => "merge-1", "assignment_id" => @assignment.id,
      "attempt_id" => @delivery_attempt.attempt_id, "project_id" => "ace", "operation" => "merge",
      "input_digest" => "c" * 64, "target" => {"resource" => @io[:prs].first.url, "artifact_digest" => nil},
      "candidate_head" => head, "caller_uid" => Process.uid, "executor_uid" => Process.uid,
      "authorization" => "approved-merge", "transport" => "local", "service_id" => "integrator"}
    # The qjx executor owns dispatch and its exact scoped policy; the
    # delivery worker consumes only its verified terminal evidence.
    @coordinator.claim_service_request(binding)
    @io[:prs] = [@io[:prs].first.with(state: :merged, merge_commit_sha: "d" * 40)]
    content = "ace-service-attestation request:merge-1 input:#{binding['input_digest']} outcome:succeeded\n"
    File.write(File.join(@repo, "merge-proof.txt"), content)
    File.chmod(0o600, File.join(@repo, "merge-proof.txt"))
    receipt = binding.slice(*Ace::Assign::Organisms::AttemptCoordinator::SERVICE_BINDING_FIELDS).merge(
      "outcome" => "succeeded", "evidence" => [{"ref" => "merge-proof.txt", "sha256" => Digest::SHA256.hexdigest(content)}])
    @coordinator.transition_service_request("merge-1", state: "succeeded", receipt: receipt)
    merged = perform("merge", tests: tests, review: review, service_request_id: "merge-1")
    assert_equal "merge", merged["delivery"].last["operation"]
    assert_equal %i[create ready], @io[:writes]
    File.write(File.join(@repo, "merge-proof.txt"), "forged")
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      perform("merge", tests: tests, review: review, service_request_id: "merge-1")
    end
  end

  def test_zero_and_multiple_reconciliation_remain_unresolved
    @io[:lose_create] = true
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { perform("create", title: "Task") }
    original = @io[:prs].first
    @io[:prs] = []
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { perform("create", title: "Task") }
    @io[:prs] = [original, original.with(number: 2)]
    assert_raises(Ace::Git::ProviderConflictingMatchesError) { perform("create", title: "Task") }
    assert_equal [:create], @io[:writes]
  end

  def test_missing_or_forged_evidence_cannot_make_ready
    perform("create", title: "Task")
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) { perform("ready") }
    forged = {"attempt_id" => @delivery_attempt.attempt_id, "receipt_digest" => "a" * 64}
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) { perform("ready", tests: forged, review: forged) }
    assert_equal [:create], @io[:writes]
  end

  def test_changed_candidate_and_missing_merge_authority_block_before_write
    tests = accept("test", "010"); review = accept("review", "020")
    perform("create", title: "Task")
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) { perform("merge", tests: tests, review: review) }
    File.write(File.join(@repo, "new.txt"), "changed")
    git(@repo, "add", "new.txt"); git(@repo, "commit", "-m", "candidate changed")
    git(@repo, "push", @remote, "HEAD:refs/heads/feature")
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) { perform("ready", tests: tests, review: review) }
    assert_equal [:create], @io[:writes]
  end

  def test_worker_boundary_cannot_write_authoritative_delivery_events
    @delivery_attempt = start("030")
    resolver = Ace::Assign::Molecules::ExecutionIdentityResolver.new
    worker = Ace::Assign::Molecules::ExecutionIdentityResolver::Identity.new(actor: "worker", role: "worker",
      runtime: "fork:worker", adapter: "service")
    resolver.define_singleton_method(:resolve) { worker }
    blocked = Ace::Assign::Organisms::DeliveryCoordinator.new(repo_root: @repo, coordinator: @coordinator,
      journal: @journal, identity_resolver: resolver, exclusion: @exclusion)
    assert_raises(Ace::Assign::AttemptErrors::UnauthorizedIdentity) do
      blocked.perform(assignment_id: @assignment.id, attempt_id: @delivery_attempt.attempt_id,
        operation: "create", parameters: @parameters, title: "Task")
    end
    assert_empty @io[:writes]
    refute @journal.read_events(@assignment.id).any? { |event| event["type"] == "delivery" }
  end

  def test_changed_server_identity_never_retargets
    perform("create", title: "Task")
    Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge("servers" => [
      {"name" => "named", "provider" => "forgejo", "url" => FORK_URL, "default" => true}]))
    assert_raises(Ace::Git::ProviderIdentityMismatchError) { perform("status") }
    assert_equal [:create], @io[:writes]
  end

  def test_later_scoped_steps_reuse_assignment_pr_and_keep_operation_attribution
    tests = accept("test", "010"); review = accept("review", "020")
    perform("create", title: "Task")
    created_attempt = @delivery_attempt.attempt_id
    accept("create-pr", "030")
    @delivery_attempt = start("145")
    before = @journal.ref_value
    assert_equal 1, perform("review").pull_request.number
    assert_equal before, @journal.ref_value
    accept("review", "145")
    @delivery_attempt = start("147")
    perform("update", title: "Final", body: "Executed validation")
    updated_attempt = @delivery_attempt.attempt_id
    accept("update-pr", "147")
    @delivery_attempt = start("148")
    status = perform("ready", tests: tests, review: review)
    assert_equal false, @io[:prs].first.draft
    assert_equal %i[create update ready], @io[:writes]
    assert_equal @delivery_attempt.attempt_id, status["delivery"].last["attempt_id"]
    results = @journal.read_events(@assignment.id).select { |event| event.dig("payload", "stage") == "result" }
    assert_equal [created_attempt, updated_attempt, @delivery_attempt.attempt_id], results.map { |event| event["attempt_id"] }
  end

  def test_new_scoped_attempt_cannot_repeat_unknown_create
    @io[:lose_create] = true
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { perform("create", title: "Task") }
    original = @io[:prs].first
    original_attempt = @delivery_attempt.attempt_id
    @io[:prs] = []
    @delivery_attempt = start("031")
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { perform("create", title: "Task") }
    assert_equal [:create], @io[:writes]
    @io[:prs] = [original]
    perform("create", title: "Task")
    assert_equal [:create], @io[:writes]
    result = @journal.read_events(@assignment.id).last
    assert_equal @delivery_attempt.attempt_id, result["attempt_id"]
    assert_equal original_attempt, result.dig("payload", "intent_attempt_id")
    refute_nil result.dig("payload", "intent_digest")
  end

  def test_recovering_create_does_not_claim_later_ready_step_completed
    tests = accept("test", "010"); review = accept("review", "020")
    @io[:lose_create] = true
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { perform("create", title: "Task") }
    original_attempt = @delivery_attempt.attempt_id
    @delivery_attempt = start("148")
    error = assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      perform("ready", tests: tests, review: review)
    end
    assert_includes error.message, "requested ready still needs execution"
    assert_equal true, @io[:prs].first.draft
    assert_equal [:create], @io[:writes]
    accept("create-pr", "030")
    assert @coordinator.authoritative_attempt({"assignment_id" => @assignment.id,
      "attempt_id" => original_attempt}).terminal?
    perform("ready", tests: tests, review: review)
    assert_equal false, @io[:prs].first.draft
    assert_equal %i[create ready], @io[:writes]
  end

  def test_recovered_update_cannot_complete_different_requested_content
    perform("create", title: "Task")
    @io[:lose_update] = true
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { perform("update", title: "Old requested title", body: "Old body") }
    @io[:lose_update] = false
    @delivery_attempt = start("147")
    error = assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      perform("update", title: "New requested title", body: "New body")
    end
    assert_equal "Ace::Assign::AttemptErrors::CurrentEffectRequired", error.class.name
    assert_equal "Old requested title", @io[:prs].first.title
    assert_equal %i[create update], @io[:writes]
    perform("update", title: "New requested title", body: "New body")
    assert_equal "New requested title", @io[:prs].first.title
    assert_equal "New body", @io[:prs].first.body
    assert_equal %i[create update update], @io[:writes]
  end

  def test_recovered_create_cannot_complete_different_requested_body_or_known_draft
    @io[:lose_create] = true
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { perform("create", title: "Task", body: "Old body") }
    @io[:lose_create] = false
    @delivery_attempt = start("031")
    error = assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      perform("create", title: "Task", body: "New body")
    end
    assert_equal "Ace::Assign::AttemptErrors::CurrentEffectRequired", error.class.name
    assert_equal [:create], @io[:writes]
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) { perform("create", title: "Task", body: "New body") }
    assert_equal "Old body", @io[:prs].first.body
    perform("create", title: "Task", body: "Old body")
    assert_equal [:create], @io[:writes]
  end

  def test_recovered_ready_does_not_substitute_different_explicit_evidence
    tests = accept("test", "010"); review = accept("review", "020")
    perform("create", title: "Task")
    @io[:lose_ready] = true
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { perform("ready", tests: tests, review: review) }
    @io[:lose_ready] = false
    different_tests = accept("test", "011")
    @delivery_attempt = start("148")
    error = assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      perform("ready", tests: different_tests, review: review)
    end
    assert_equal "Ace::Assign::AttemptErrors::CurrentEffectRequired", error.class.name
    assert_equal %i[create ready], @io[:writes]
  end
end
