# frozen_string_literal: true

require "test_helper"
require_relative "../../support/inbox_context_owner_fixture"

class InboxContextOwnerTest < Minitest::Test
  include InboxContextOwnerFixture

  class CountedInbox < Ace::Herdr::Organisms::Inbox
    class << self
      attr_accessor :effects
    end
    def reconcile(**arguments)
      self.class.effects += 1
      super
    end
  end

  def test_real_signed_context_effect_replay_keeps_pending_until_actual_canonical_query
    CountedInbox.effects = 0
    prepare_reconciliation(CountedInbox)
    snapshot = @owner.snapshot_context(operation_id: @effect_binding.fetch("operation_id"), key_generation: 1,
      event_id: "event1", peer: @normal)
    assert_equal "delivered", snapshot.dig("record", "state")
    refute_includes JSON.generate(snapshot), "controlled secret message"
    refute snapshot.fetch("record").key?("receipt")
    arguments = {effect_binding: @effect_binding, signed_bytes: @signed_bytes, signature: @signature, peer: @normal}
    accepted = @owner.reconcile_context(**arguments)
    assert_equal "completed", accepted.fetch("state")
    assert_equal 1, CountedInbox.effects
    assert accepted.frozen?
    assert_raises(ERROR) { @owner.end_context_operation(operation_id: @effect_binding.fetch("operation_id"), peer: @normal) }
    assert_raises(ERROR) { begin_rotation }
    restart
    assert_equal "unknown", begin_operation("reconcile").fetch("state")
    assert_equal accepted, @owner.reconcile_context(**arguments)
    assert_equal 1, CountedInbox.effects
    assert_raises(ERROR) do
      @owner.confirm_context_completion(effect_binding: @effect_binding, reconciliation_digest: "a" * 64, peer: @normal)
    end
    assert_raises(ERROR) { @owner.end_context_operation(operation_id: @effect_binding.fetch("operation_id"), peer: @normal) }
    assert_raises(ERROR) { @owner.reconcile_context(**arguments.merge(effect_binding: @effect_binding.merge("mutation_id" => "other"))) }
    assert_raises(ERROR) { @owner.reconcile_context(**arguments.merge(signed_bytes: @signed_bytes + " ")) }
    assert_equal 1, CountedInbox.effects
  end

  def test_retained_effect_cannot_be_marked_idle_without_canonical_completion
    prepare_reconciliation
    @owner.reconcile_context(effect_binding: @effect_binding, signed_bytes: @signed_bytes, signature: @signature, peer: @normal)
    @store.transaction { |state| state.fetch("operations").fetch(@effect_binding.fetch("operation_id"))["in_flight"] = 0 }
    restart
    assert_raises(ERROR) { @owner.status(peer: @normal) }
    assert_raises(ERROR) { @owner.end_context_operation(operation_id: @effect_binding.fetch("operation_id"), peer: @normal) }
    assert_raises(ERROR) { begin_rotation }
  end

  def test_lost_begin_ack_returns_same_exact_admission_before_and_after_restart
    first = begin_operation
    assert_equal first, begin_operation
    assert_equal 1, @owner.status(peer: @normal).fetch("active_operations")
    assert_raises(ERROR) { begin_operation("deliver") }
    assert_raises(ERROR) { begin_rotation }
    restart
    assert_equal first, begin_operation
    @owner.end_context_operation(operation_id: first.fetch("operation_id"), peer: @normal)
    rotation = begin_rotation
    assert_equal 1, rotation.fetch("key_generation")
    assert_raises(ERROR) { begin_operation }
  end

  def test_same_uid_replacement_birth_cannot_end_original_operation
    operation = begin_operation
    replacement = @normal.merge("started_at" => @normal.fetch("started_at").sub(":42", ":43"))
    assert_raises(ERROR) { @owner.end_context_operation(operation_id: operation.fetch("operation_id"), peer: replacement) }
    assert_raises(ERROR) { @owner.begin_context_operation(context_id: "ctx", purpose: "enqueue", event_id: "event1",
      process_binding: @normal, peer: replacement) }
    assert_raises(ERROR) { begin_rotation }
  end

  def test_lost_downstream_ack_retains_unknown_in_flight_after_restart_without_replay
    operation = begin_operation
    arguments = {operation_id: operation.fetch("operation_id"), key_generation: 1,
      purpose: "enqueue", event_id: "event1", peer: @normal}
    assert_raises(IOError) { @owner.with_operation(**arguments) { raise IOError, "lost downstream ACK" } }
    restart
    retried = begin_operation
    assert_equal operation.fetch("operation_id"), retried.fetch("operation_id")
    assert_equal "unknown", retried.fetch("state")
    effect = false
    assert_raises(ERROR) { @owner.with_operation(**arguments) { effect = true } }
    refute effect
    assert_raises(ERROR) { @owner.end_context_operation(operation_id: operation.fetch("operation_id"), peer: @normal) }
    @kernel.dead = @normal.fetch("pid")
    assert_raises(ERROR) { @owner.end_context_operation(operation_id: operation.fetch("operation_id"), peer: @normal) }
    assert_raises(ERROR) { begin_rotation }
    assert_equal 1, @owner.status(peer: @maintenance).fetch("active_operations")
  end

  def test_generic_success_or_boolean_never_authenticates_downstream_completion
    operation = begin_operation
    assert_equal true, @owner.with_operation(operation_id: operation.fetch("operation_id"), key_generation: 1,
      purpose: "enqueue", event_id: "event1", peer: @normal) { true }
    assert_raises(ERROR) { @owner.end_context_operation(operation_id: operation.fetch("operation_id"), peer: @normal) }
    assert_raises(ERROR) { begin_rotation }
  end

  def test_real_public_pair_rotation_requires_signer_then_installed_config_and_retries_once
    rotation = begin_rotation
    install(NEXT_KEY, 2)
    accepted = attestation(rotation, NEXT_KEY)
    assert_equal accepted, attestation(rotation, NEXT_KEY)
    assert_raises(ERROR) { attestation(rotation, NEXT_KEY, identity: @maintenance) }
    result = commit(rotation, accepted)
    assert_equal "committed", result.fetch("state")
    assert_equal 2, result.fetch("key_generation")
    assert_equal result, commit(rotation, accepted)
    assert_equal 2, begin_operation.fetch("key_generation")
    assert_raises(ERROR) { begin_rotation }
    restart
    assert_equal result, commit(rotation, accepted)
  end

  def test_restored_public_only_cannot_abort_without_original_private_pair_attestation
    rotation = begin_rotation
    install(NEXT_KEY, 2)
    attestation(rotation, NEXT_KEY)
    install(KEY, 1)
    fake = {"attestation_id" => "a" * 32}
    assert_raises(ERROR) { @owner.abort_rotation(rotation_id: rotation.fetch("rotation_id"), signer_keypair_attestation: fake, peer: @maintenance) }
    params = {rotation_id: rotation.fetch("rotation_id"), new_public_key_bytes: KEY.public_key.to_pem,
      installed_config_digest: @config_digest, disposition: "rollback"}
    body = @owner.rotation_challenge(**params, peer: @signer)
    wrong = [NEXT_KEY.sign(OpenSSL::Digest::SHA256.new, JSON.generate(body))].pack("m0")
    assert_raises(ERROR) { @owner.attest_rotation(**params, expected_key_generation: 1, signature: wrong, peer: @signer) }
    assert_equal "rotation_blocked", @owner.status(peer: @maintenance).fetch("state")
    accepted = attestation(rotation, KEY, disposition: "rollback")
    result = @owner.abort_rotation(rotation_id: rotation.fetch("rotation_id"), signer_keypair_attestation: accepted, peer: @maintenance)
    assert_equal "aborted", result.fetch("state")
    assert_equal result, @owner.abort_rotation(rotation_id: rotation.fetch("rotation_id"), signer_keypair_attestation: accepted, peer: @maintenance)
    assert_equal 1, begin_operation.fetch("key_generation")
  end

  def test_partial_install_wrong_config_and_restart_remain_blocked
    rotation = begin_rotation
    install(NEXT_KEY, 2)
    accepted = attestation(rotation, NEXT_KEY)
    File.write(@key_path, KEY.public_key.to_pem)
    assert_raises(ERROR) { commit(rotation, accepted) }
    restart
    assert_equal rotation, begin_rotation
    assert_raises(ERROR) { begin_operation }
    assert_equal "rotation_blocked", @owner.status(peer: @maintenance).fetch("state")
  end

  def test_all_unresolved_live_or_archived_events_and_corrupt_state_refuse_rotation
    states = Ace::Herdr::Models::DeliveryRecord::STATES - ["completed"]
    states.each do |state|
      record = Ace::Herdr::Models::DeliveryRecord.new(event_id: "event1", session: "ws1", pane: "p1",
        answer: "controlled", answer_digest: Digest::SHA256.hexdigest("controlled"), state: state,
        inbox: {"attempt_id" => "attempt1", "claim_generation" => 1})
      Ace::Herdr::Molecules::DeliveryRecordStore.save(record, @events)
      assert_raises(ERROR, state) { begin_rotation }
    end
    live = File.join(@events, "event1.json")
    archive = Ace::Herdr::Molecules::DeliveryRecordStore.archive_dir(@events)
    FileUtils.mkdir_p(archive)
    File.rename(live, File.join(archive, "event1.json"))
    assert_raises(ERROR) { begin_rotation }
    File.write(File.join(archive, "event1.json"), "{malformed")
    assert_raises(ERROR) { begin_rotation }
  end

  def test_genuinely_reconciled_completed_live_archive_bytes_remain_unchanged_across_rotation
    inbox = Ace::Herdr::Organisms::Inbox.new(executor: PaneFixture.new, native: NativeFixture.new,
      deliveries_dir: @events, receipt_public_key: KEY.public_key)
    inbox.enqueue(event: "event1", attempt: "attempt1", ref: {"session" => "ws1", "pane" => "p1"}, payload: "controlled")
    delivered = inbox.deliver(event: "event1")
    assert_equal "delivered", delivered.fetch("state")
    receipt = {"event_id" => "event1", "attempt_id" => "attempt1", "claim_generation" => delivered.fetch("claim_generation"),
      "payload_sha256" => delivered.fetch("payload_sha256"), "binding" => delivered.fetch("binding"),
      "outcome" => "consumed", "observer" => {"role" => "supervisor", "id" => "controlled"},
      "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => "controlled-item1", "observation" => "controlled completed item"}}
    bytes = JSON.generate(receipt)
    assert_equal "completed", inbox.reconcile(event: "event1", receipt: receipt, signed_bytes: bytes,
      signature: KEY.sign(OpenSSL::Digest::SHA256.new, bytes)).fetch("state")
    path = File.join(@events, "event1.json")
    original = File.binread(path)
    archive = Ace::Herdr::Molecules::DeliveryRecordStore.archive_dir(@events)
    FileUtils.mkdir_p(archive)
    archived = File.join(archive, "event1.json")
    File.binwrite(archived, original)
    rotation = begin_rotation
    install(NEXT_KEY, 2)
    commit(rotation, attestation(rotation, NEXT_KEY))
    assert_equal original, File.binread(path)
    assert_equal original, File.binread(archived)
    assert_equal Digest::SHA256.hexdigest(KEY.public_to_der), JSON.parse(File.read(path)).dig("inbox", "receipt_key_sha256")
    assert_equal Digest::SHA256.hexdigest(NEXT_KEY.public_to_der), begin_operation.fetch("fingerprint")
  end

  def test_admission_vs_rotation_real_metadata_contention_has_one_winner
    start = Queue.new
    results = Queue.new
    threads = [Thread.new { start.pop; results << [:operation, begin_operation] rescue results << [:operation, :blocked] },
      Thread.new { start.pop; results << [:rotation, begin_rotation] rescue results << [:rotation, :blocked] }]
    2.times { start << true }
    threads.each(&:join)
    outcomes = 2.times.map { results.pop }
    assert_equal 1, outcomes.count { |_kind, value| value == :blocked }
    assert_equal 1, outcomes.count { |_kind, value| value.is_a?(Hash) }
  end

  def test_owner_lifetime_excludes_duplicate_and_missing_or_corrupt_metadata_never_initializes
    assert_raises(ERROR) { Store.new(root: @state, uid: Process.uid, protection: FixturePaths.new) }
    path = File.join(@state, ".context-control.json")
    valid = File.read(path)
    File.write(path, valid.sub('"context_id":"ctx"', '"context_id":"wrong","context_id":"ctx"'))
    assert_raises(ERROR) { @owner.status(peer: @normal) }
    File.unlink(path)
    restart
    assert_raises(ERROR) { @owner.status(peer: @normal) }
    refute File.exist?(path)
  end

  def test_unknown_role_bad_credentials_and_state_bounds_refuse
    assert_raises(ERROR) { begin_operation("force") }
    assert_raises(ERROR) { begin_operation("enqueue", peer(404)) }
    assert_raises(ERROR) { begin_operation("enqueue", @normal.merge("groups" => [])) }
    assert_raises(ERROR) { @owner.begin_rotation(context_id: "ctx", expected_key_generation: 1.0, peer: @maintenance) }
    assert_raises(ERROR) { @owner.begin_rotation(context_id: "other", expected_key_generation: 1, peer: @maintenance) }
    path = File.join(@state, ".context-control.json")
    File.write(path, " " * (Store::LIMIT + 1))
    assert_raises(ERROR) { @owner.status(peer: @normal) }
  end

  def test_installed_key_changed_outside_admission_and_operation_count_bound_refuse
    install(NEXT_KEY, 2)
    assert_raises(ERROR) { begin_operation }
    assert_raises(ERROR) { begin_rotation }
    install(KEY, 1)
    @store.transaction do |state|
      Owner::OPERATION_LIMIT.times do |i|
        state.fetch("operations")[i.to_s(16).rjust(32, "0")] = {"peer" => @normal, "purpose" => "enqueue",
          "event_id" => "event-#{i}", "key_generation" => 1, "in_flight" => 0, "effect_binding" => nil, "completion" => nil,
          "issuer_state" => nil, "admitted_claim" => nil}
      end
    end
    assert_raises(ERROR) { begin_operation }
    assert_equal Owner::OPERATION_LIMIT, @owner.status(peer: @normal).fetch("active_operations")
  end
end
