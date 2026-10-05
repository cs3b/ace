# frozen_string_literal: true
require "test_helper"
require "support/lifecycle_fixtures"
require "ace/assign"
require "ace/assign/molecules/evidence_journal"
require "open3"
require "ace/hitl/hermes/runtime"
require "ace/hitl/proposals/evaluator"
require "timeout"
require "etc"

class ProposalLifecycleTest < AceHitlTestCase
  include LifecycleFixtures
  class Binding < TestBinding
    attr_accessor :proposal_journal
  end
  class DecisionPolicy < AllowTransportPolicy
    def proposal?(_peer, project:)
      project == "ace"
    end
  end

  def setup
    super
    @dir = Dir.mktmpdir("proposal-test")
    @repo = File.join(@dir, "repo")
    FileUtils.mkdir_p(@repo)
    git("init", "-b", "main")
    git("-c", "user.name=test", "-c", "user.email=test@test", "commit", "--allow-empty", "-m", "base")
    @journal = Ace::Assign::Molecules::EvidenceJournal.new(repo_root: @repo, checkout_root: File.join(@dir, "journal"))
    intent = Ace::Assign::Models::EvidenceEvent.build(type: "intent", attempt_id: "attempt500",
      payload: {"scope" => "010", "project_id" => "ace", "task_id" => "8wr.t.qjz",
        "base_head" => git("rev-parse", "HEAD"), "actor" => "lab-admin", "role" => "worker", "runtime" => "fixture"})
    start = Ace::Assign::Models::EvidenceEvent.build(type: "process_start", attempt_id: "attempt500",
      payload: {"actor" => "lab-admin", "role" => "worker", "runtime" => "fixture"}, previous_digest: intent["digest"])
    @journal.append(assignment_id: "assign500", attempt_id: "attempt500", events: [intent, start])
    @binding = Binding.new
    @binding.proposal_journal = @journal
    @now = Time.iso8601("2026-10-05T01:00:00Z")
    @store = Ace::Hitl::Lifecycle::Store.new(root: File.join(@dir, "hitl"), binding: @binding,
      identity: TestIdentity.new, policy: DecisionPolicy.new, ownership: RecordingOwnership.new,
      proposal_clock: -> { @now })
  end

  def teardown
    FileUtils.rm_rf(@dir)
    super
  end

  def git(*args)
    out, err, status = Open3.capture3("git", *args, chdir: @repo)
    raise err unless status.success?
    out.strip
  end

  def content(operation = "deploy")
    {"operation" => operation, "target" => {"resource" => "production"},
     "candidate_head" => git("rev-parse", "HEAD"), "input_digest" => "b" * 64,
     "context" => "Exact release", "options" => ["yes", "no"], "recommendation" => "yes",
     "prerequisites" => ["current tests and review", "publisher OTP when required"]}
  end

  def create
    @store.proposal_create(id: "proposal-#{SecureRandom.hex(12)}", assignment: "assign500", attempt: "attempt500", project: "ace", document: content)
  end

  def acknowledge(record)
    @store.proposal_acknowledge(record["request_id"], submitted_at: @now.iso8601)
  end

  def checkpoint(record)
    {"schema" => "ace.hitl.hermes.ingress-checkpoint/v1", "request" => record["request_id"],
     "revision" => record["revision_id"], "healthy" => true, "drained" => true,
     "checkpoint" => {"through" => record["deadline"], "sequence" => 0}}
  end

  def binding(record, id = "effect001")
    record.slice(*Ace::Assign::Molecules::ProposalJournal::PROPOSAL_BINDING).merge(
      "request_id" => id, "authorization" => record["revision_id"])
  end

  def test_lower_journal_cannot_rewrite_revision_scope_or_create_approved_revision
    record = create
    %w[operation target candidate_head input_digest context recommendation caller_uid].each do |field|
      assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
        @journal.change_proposal(record["proposal_id"], assignment_id: "assign500", attempt_id: "attempt500") do |current|
          current.merge(field => "forged")
        end
      end
      assert_equal record, @journal.proposal_record(record["proposal_id"])
    end
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @journal.change_proposal("proposal-#{'c' * 24}", assignment_id: "assign500", attempt_id: "attempt500") do
        record.merge("proposal_id" => "proposal-#{'c' * 24}", "state" => "approved-explicitly")
      end
    end
  end

  def test_unseen_lower_reply_veto_applies_and_changed_duplicate_is_refused
    record = acknowledge(create)
    @store.proposal_reply(record["request_id"], answer: "approve", received_at: @now.iso8601, sequence: 2)
    @store.proposal_reply(record["request_id"], answer: "veto", received_at: @now.iso8601, sequence: 1)
    assert_equal "denied", @journal.proposal_record(record["proposal_id"])["state"]
    before = @journal.ref_value
    @store.proposal_reply(record["request_id"], answer: "veto", received_at: @now.iso8601, sequence: 1)
    assert_equal before, @journal.ref_value
    assert_raises(Ace::Hitl::Lifecycle::StateError) do
      @store.proposal_reply(record["request_id"], answer: "approve", received_at: @now.iso8601, sequence: 1)
    end
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) { @journal.claim_service_request(binding(record)) }
  end

  def test_initial_creation_failure_and_uncertain_commit_recover_exact_identity
    id = "proposal-#{SecureRandom.hex(12)}"
    args = {id: id, assignment: "assign500", attempt: "attempt500", project: "ace", document: content}
    original = @journal.method(:change_proposal)
    @journal.define_singleton_method(:change_proposal) { |*a, **k, &b| raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "before commit" }
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { @store.proposal_create(**args) }
    assert_empty Dir.glob(File.join(@dir, "hitl/requests/*.json"))
    @journal.define_singleton_method(:change_proposal) do |*a, **k, &b|
      original.call(*a, **k, &b)
      raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "lost canonical reply"
    end
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { @store.proposal_create(**args) }
    assert @journal.proposal_record(id)
    assert_empty Dir.glob(File.join(@dir, "hitl/requests/*.json"))
    @journal.define_singleton_method(:change_proposal, original)
    # The transport's existing pending producer restores the durable prepared
    # projection after restart, without impersonating the original proposer.
    assert_equal ["#{id}-r1"], @store.pending.map { |entry| entry["id"] }
    record = @store.proposal_create(**args)
    incarnation = record.dig("lifecycle_request", "incarnation")
    armed = acknowledge(record)
    before = @journal.ref_value
    retried = @store.proposal_create(**args)
    assert_equal before, @journal.ref_value
    assert_equal armed["deadline"], retried["deadline"]
    assert_equal incarnation, @store.read(record["request_id"]).dig("envelope", "request_incarnation")
    assert_raises(Ace::Hitl::Lifecycle::StateError) { @store.proposal_create(**args.merge(document: content("access"))) }
    assert_raises(Ace::Hitl::Lifecycle::StateError) { @store.proposal_create(**args.merge(assignment: "different")) }
    assert_raises(Ace::Hitl::Lifecycle::StateError) { @store.proposal_create(**args.merge(attempt: "different")) }
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
      @journal.change_proposal(id, assignment_id: "different", attempt_id: "different") { |entry| record }
    end
    assert_equal 1, Dir.glob(File.join(@dir, "hitl/requests/*.json")).size
  end

  def test_concurrent_materializers_preserve_existing_public_lifecycle_state
    record = create
    path = @store.send(:public_path, record["request_id"])
    current = JSON.parse(File.read(path)).merge("state" => "answer-delivered")
    Ace::Hitl::Lifecycle::AtomicJson.call(path, current, mode: 0o440, ownership_strategy: RecordingOwnership.new)
    threads = 2.times.map { Thread.new { @store.send(:project_proposal_request, record) } }
    Timeout.timeout(10) { threads.each(&:value) }
    assert_equal current, JSON.parse(File.read(path))
    File.unlink(@store.send(:request_path, record["request_id"]))
    threads = 2.times.map { Thread.new { @store.send(:project_proposal_request, record) } }
    Timeout.timeout(10) { threads.each(&:value) }
    assert_equal current, JSON.parse(File.read(path))
    assert_equal record["lifecycle_request"], JSON.parse(File.read(@store.send(:request_path, record["request_id"])))
  end

  def test_retrying_veto_blocks_later_approval_without_storing_message_bodies
    with_transport do |boundary, actor|
      record = boundary.proposal_create(id: "proposal-#{SecureRandom.hex(12)}", assignment: "assign500", attempt: "attempt500", project: "ace", document: content)
      actor.serve(once: true)
      transport = actor.relay.instance_variable_get(:@lifecycle)
      original = transport.method(:proposal_reply)
      first = true
      transport.define_singleton_method(:proposal_reply) do |request, **params|
        if first && params[:answer] == "veto"
          first = false
          raise Ace::Hitl::Lifecycle::TransportError, "injected transient reply"
        end
        original.call(request, **params)
      end
      assert_equal "unresolved", actor.relay.receive(event("veto"))["status"]
      assert_equal "unresolved", actor.relay.receive(event("approve").merge("message_id" => "102"))["status"]
      assert_equal "awaiting-decision", @journal.proposal_record(record["proposal_id"])["state"]
      assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) { @journal.claim_service_request(binding(record)) }
      assert_equal "delivered", actor.relay.receive(event("veto"))["status"]
      actor.relay.receive(event("approve").merge("message_id" => "102"))
      assert_equal "denied", @journal.proposal_record(record["proposal_id"])["state"]
      assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) { @journal.claim_service_request(binding(record)) }
      actor.journal.synchronize do |state, _|
        state["ingress"].each { |item| refute item.keys.any? { |key| %w[text answer body digest].include?(key) } }
      end
    end
  end

  def test_restart_preserves_deadline_and_one_effect_claim
    record = acknowledge(create)
    @now += 16 * 3600
    resolved = @store.proposal_reconcile(record["request_id"], checkpoint: checkpoint(record))
    assert_equal "approved-by-silence", resolved["state"]
    restarted = Ace::Assign::Molecules::EvidenceJournal.new(repo_root: @repo, checkout_root: File.join(@dir, "journal"))
    assert_equal record["deadline"], restarted.proposal_record(record["proposal_id"])["deadline"]
    claim = @journal.claim_service_request(binding(resolved), state: "uncertain")
    assert_equal "uncertain", claim["state"]
    assert_raises(Ace::Assign::AttemptErrors::Conflict) do
      @journal.claim_service_request(binding(resolved, "effect002"), state: "uncertain")
    end
    reply = @store.proposal_reply(record["request_id"], answer: "veto", received_at: @now.iso8601, sequence: 1)
    assert reply["stop_requested"]
    assert_equal "approved-by-silence", reply["state"]
    assert_equal "uncertain", @store.proposal_show(record["proposal_id"])["state"]
  end

  def test_lower_level_claim_cannot_bypass_denied_or_changed_authorization
    record = acknowledge(create)
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) { @journal.claim_service_request(binding(record)) }
    @store.proposal_reply(record["request_id"], answer: "approve", received_at: @now.iso8601, sequence: 1)
    %w[operation input_digest candidate_head caller_uid target].each do |field|
      assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
        @journal.claim_service_request(binding(record).merge(field => "changed"))
      end
    end
    @store.proposal_reply(record["request_id"], answer: "veto", received_at: @now.iso8601, sequence: 2)
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) { @journal.claim_service_request(binding(record)) }
    assert_empty @journal.service_requests("assign500")
  end

  def test_worker_cannot_fabricate_ack_reply_or_checkpoint_at_boundary_role_gate
    record = create
    policy = Ace::Hitl::Lifecycle::GrantsPolicy.new(document: {
      "hitl" => {"transport_uids" => [Process.uid + 1000]},
      "authorization" => {"principals" => {(Process.uid + 1000).to_s => {"projects" => ["ace"]}}}})
    worker = Ace::Hitl::Lifecycle::Store.new(root: File.join(@dir, "hitl"), binding: @binding,
      identity: TestIdentity.new, policy: policy, proposal_clock: -> { @now })
    assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
      worker.proposal_create(id: "proposal-#{SecureRandom.hex(12)}", assignment: "assign500", attempt: "attempt500", project: "ace", document: content)
    end
    assert_raises(Ace::Hitl::Lifecycle::PermissionError) { worker.proposal_revise(record["proposal_id"], document: content) }
    library = Ace::Hitl::Lifecycle::Store.new(root: File.join(@dir, "hitl"), binding: @binding, identity: TestIdentity.new)
    assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
      library.proposal_create(id: "proposal-#{SecureRandom.hex(12)}", assignment: "assign500", attempt: "attempt500", project: "ace", document: content)
    end
    assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
      worker.proposal_acknowledge(record["request_id"], submitted_at: @now.iso8601)
    end
    assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
      worker.proposal_reply(record["request_id"], answer: "approve", received_at: @now.iso8601, sequence: 1)
    end
    assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
      worker.proposal_reconcile(record["request_id"], checkpoint: checkpoint(record))
    end
    assert_equal "awaiting-delivery", @journal.proposal_record(record["proposal_id"])["state"]
  end

  def test_revision_requires_fresh_delivery_and_old_reply_cannot_authorize_new_scope
    old = acknowledge(create)
    revised = @store.proposal_revise(old["proposal_id"], document: content("access"))
    assert_equal 2, revised["revision"]
    assert_equal "awaiting-delivery", revised["state"]
    refute revised.key?("deadline")
    @store.proposal_reply(old["request_id"], answer: "approve", received_at: @now.iso8601, sequence: 1)
    assert_equal "awaiting-delivery", @journal.proposal_record(old["proposal_id"])["state"]
    assert_raises(Ace::Hitl::Lifecycle::StateError) { @store.deliver(revised["request_id"], stdin_reader("approve")) }
    @now += 7200
    armed = acknowledge(revised)
    assert_equal "2026-10-05T19:00:00Z", armed["deadline"]
    assert_equal [old["proposal_id"]], @store.proposal_history(project: "ace", query: "production")["items"].map { |entry| entry["proposal_id"] }
    assert_empty @store.proposal_history(project: "other")["items"]
    assert_operator @store.proposal_show(old["proposal_id"])["history"].size, :<=, 3
  end

  def test_interrupted_revision_is_exactly_recoverable_without_another_request
    old = acknowledge(create)
    original = @journal.method(:change_proposal)
    failure = true
    @journal.define_singleton_method(:change_proposal) do |id, **args, &policy|
      original.call(id, **args) do |record|
        updated = policy.call(record)
        if failure && updated["revision"] == 2
          failure = false
          raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "injected before revision commit"
        end
        updated
      end
    end
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
      @store.proposal_revise(old["proposal_id"], document: content("access"))
    end
    revised = @store.proposal_revise(old["proposal_id"], document: content("access"))
    assert_equal 2, revised["revision"]
    assert_equal "awaiting-delivery", revised["state"]
    assert_equal 2, Dir.children(File.join(@dir, "hitl", "requests")).size
  end

  def test_late_veto_and_direct_claim_share_atomic_authority
    record = acknowledge(create)
    @store.proposal_reply(record["request_id"], answer: "approve", received_at: @now.iso8601, sequence: 1)
    ready = Queue.new
    start = Queue.new
    claim = Thread.new do
      ready << true; start.pop
      begin
        @journal.claim_service_request(binding(record), state: "uncertain")
      rescue Ace::Assign::AttemptErrors::ReceiptRejected
        nil
      end
    end
    veto = Thread.new do
      ready << true; start.pop
      @store.proposal_reply(record["request_id"], answer: "veto", received_at: @now.iso8601, sequence: 2)
    end
    2.times { ready.pop }
    2.times { start << true }
    result, decision = Timeout.timeout(10) { [claim.value, veto.value] }
    if result
      assert_equal "uncertain", result["state"]
      assert decision["stop_requested"]
      assert_equal "approved-explicitly", decision["state"]
    else
      assert_equal "denied", decision["state"]
      assert_empty @journal.service_requests("assign500")
    end
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) { @journal.proposal_authorize!(record["revision_id"], binding(record)) }
  end

  def with_transport(policy: DecisionPolicy.new)
    folder = File.join(@dir, "inbox")
    FileUtils.mkdir_p(folder, mode: 0o750)
    socket = File.join(@dir, "hitl.sock")
    service = Ace::Hitl::Lifecycle::Service.new(root: File.join(@dir, "boundary"), binding: @binding,
      policy: policy, socket_path: socket, group: Etc.getgrgid(Process.gid).name,
      proposal_clock: -> { @now })
    thread = Thread.new { service.run }
    Timeout.timeout(5) { sleep 0.01 until File.socket?(socket) || !thread.alive? }
    thread.value unless thread.alive?
    registry = File.join(@dir, "registry.json")
    File.write(registry, JSON.generate({"schema" => "ace.hitl.hermes.channels/v1", "channels" => [
      {"name" => "inbox", "machine" => "local", "folder" => folder, "target" => "overseer",
       "projects" => ["ace"], "chat_id" => "-424242", "captain_user_ids" => ["42"]}]}))
    gateway = File.join(@dir, "gateway.yml")
    File.write(gateway, "platforms:\n  telegram:\n    enabled: false\n")
    config = File.join(@dir, "runtime.json")
    File.write(config, JSON.generate({"schema" => "ace.hitl.hermes.runtime/v1", "registry" => registry,
      "state" => File.join(@dir, "hermes"), "hitl_socket" => socket, "hitl_service_uid" => Process.uid,
      "hermes_gateway_config" => gateway, "polling_owner" => "ace-hitl-hermes"}))
    boundary = Ace::Hitl::Lifecycle::Client.new(socket_path: socket, service_uid: Process.uid)
    transport = Object.new
    transport.define_singleton_method(:updates) { |**| [] }
    transport.define_singleton_method(:call) { |channel, _| {"success" => true, "chat_id" => channel["chat_id"], "message_id" => "100"} }
    actor = Ace::Hitl::Hermes::Runtime.new(config, clock: -> { @now })
    actor.instance_variable_set(:@config_path_for_test, config)
    actor.instance_variable_set(:@service_for_test, service)
    actor.define_singleton_method(:telegram) { transport }
    yield boundary, actor
  ensure
    service&.stop
    thread&.join(5)
    thread&.kill if thread&.alive?
  end

  def event(answer)
    {"platform" => "telegram", "chat_id" => "-424242", "chat_type" => "group", "user_id" => "42",
     "message_id" => "101", "reply_to_message_id" => "100", "text" => answer}
  end

  def test_separate_proposer_boundary_only_wakes_existing_transport_actor
    transport_uid = Process.uid + 1000
    policy = Ace::Hitl::Lifecycle::GrantsPolicy.new(document: {
      "hitl" => {"proposal_uids" => [Process.uid], "transport_uids" => [transport_uid]},
      "authorization" => {"principals" => {Process.uid.to_s => {"projects" => ["ace"]},
        transport_uid.to_s => {"projects" => ["ace"]}}}})
    with_transport(policy: policy) do |boundary, actor|
      # Real socket authenticates the proposer. Distinct transport Peer models
      # service role dispatch; actual cross-UID installation remains acceptance.
      peer = Ace::Hitl::Lifecycle::Peer.new(uid: transport_uid, gid: Process.gid, username: "fixture-transport")
      transport_store = actor.instance_variable_get(:@service_for_test).send(:store_for, peer)
      actor.instance_variable_set(:@lifecycle, transport_store)
      actor.relay.instance_variable_set(:@lifecycle, transport_store)
      record = boundary.proposal_create(id: "proposal-#{SecureRandom.hex(12)}", assignment: "assign500", attempt: "attempt500", project: "ace", document: content)
      actor.serve(once: true)
      armed = boundary.proposal_show(record["proposal_id"])
      @now += 16 * 3600
      assert_raises(Ace::Hitl::Lifecycle::PermissionError) { boundary.proposal_due }
      assert_raises(Ace::Hitl::Lifecycle::PermissionError) { boundary.proposal_reconcile(record["request_id"], checkpoint: checkpoint(armed)) }
      assert_equal "queued-for-transport", Ace::Hitl::Proposals::Evaluator.new(boundary: boundary, project: "ace").call.first["status"]
      before = @journal.ref_value
      Ace::Hitl::Proposals::Evaluator.new(boundary: boundary, project: "ace").call
      assert_equal before, @journal.ref_value, "duplicate wake is idempotent"
      assert_equal "awaiting-decision", @journal.proposal_record(record["proposal_id"])["state"]
      actor.serve(once: true)
      assert_equal "approved-by-silence", boundary.proposal_show(record["proposal_id"])["decision_state"]
      assert_raises(Ace::Hitl::Lifecycle::PermissionError) { boundary.proposal_wake(project: "other") }
      assert_raises(Ace::Hitl::Lifecycle::PermissionError) { transport_store.proposal_wake(project: "ace") }
    end
  end

  def test_kernel_peer_cannot_create_across_installed_decision_project_scope
    policy = Ace::Hitl::Lifecycle::GrantsPolicy.new(document: {
      "hitl" => {"proposal_uids" => [Process.uid], "transport_uids" => []},
      "authorization" => {"principals" => {Process.uid.to_s => {"projects" => ["other"]}}}})
    with_transport(policy: policy) do |boundary, _actor|
      assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
        boundary.proposal_create(id: "proposal-#{SecureRandom.hex(12)}", assignment: "assign500", attempt: "attempt500", project: "ace", document: content)
      end
      assert_empty @journal.proposals
    end
  end

  def test_real_socket_producer_ack_restart_and_deadline_reconciliation
    with_transport do |boundary, actor|
      record = boundary.proposal_create(id: "proposal-#{SecureRandom.hex(12)}", assignment: "assign500", attempt: "attempt500", project: "ace", document: content)
      assert_equal "awaiting-delivery", record["state"]
      actor.serve(once: true) # producer creates folder question itself; no manual injection
      armed = boundary.proposal_show(record["proposal_id"])
      assert_equal "awaiting-decision", armed["state"]
      assert_equal "2026-10-05T17:00:00Z", armed["deadline"]
      @now += 16 * 3600
      actor.serve(once: true) # resume, drain actual polling seam before issuing checkpoint
      results = Ace::Hitl::Proposals::Evaluator.new(boundary: boundary, project: "ace").call
      assert_equal "queued-for-transport", results.first["status"]
      actor.serve(once: true)
      assert_equal "approved-by-silence", boundary.proposal_show(record["proposal_id"])["decision_state"]
      before = @journal.ref_value
      actor.relay.reconcile(request: record["request_id"], through: armed["deadline"])
      assert_equal before, @journal.ref_value, "duplicate wake must not replay ticks"
    end
  end

  def test_ingress_vs_deadline_and_claim_races_complete_without_deadlock
    with_transport do |boundary, actor|
      record = boundary.proposal_create(id: "proposal-#{SecureRandom.hex(12)}", assignment: "assign500", attempt: "attempt500", project: "ace", document: content)
      actor.serve(once: true)
      armed = boundary.proposal_show(record["proposal_id"])
      @now += 16 * 3600
      actor.serve(once: true)
      result = nil
      threads = [Thread.new { actor.relay.receive(event("veto")) },
        Thread.new { result = actor.relay.reconcile(request: record["request_id"], through: armed["deadline"]) }]
      Timeout.timeout(10) { threads.each(&:value) }
      assert_equal "denied", @journal.proposal_record(record["proposal_id"])["state"]
      assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) { @journal.claim_service_request(binding(armed)) }
      assert_equal "healthy", result["status"]
    end
  end

  def test_failed_and_uncertain_transport_submission_never_arms_deadline
    with_transport do |boundary, actor|
      record = boundary.proposal_create(id: "proposal-#{SecureRandom.hex(12)}", assignment: "assign500", attempt: "attempt500", project: "ace", document: content)
      transport = actor.send(:telegram)
      transport.define_singleton_method(:call) { |*| raise Ace::Hitl::Hermes::Transport::SubmitFailed }
      actor.serve(once: true)
      assert_equal "failed", actor.relay.delivery(record["request_id"])["status"]
      refute boundary.proposal_show(record["proposal_id"]).key?("deadline")
      transport.define_singleton_method(:call) { |*| raise IOError, "lost acknowledgement" }
      actor.serve(once: true)
      assert_equal "uncertain", actor.relay.delivery(record["request_id"])["status"]
      @now += 20 * 3600
      actor.serve(once: true)
      assert_empty boundary.proposal_due["items"]
      assert_equal "awaiting-delivery", boundary.proposal_show(record["proposal_id"])["state"]
    end
  end
end
