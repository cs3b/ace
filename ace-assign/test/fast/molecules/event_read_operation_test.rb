# frozen_string_literal: true
require_relative "../../test_helper"

class EventReadOperationTest < AceAssignTestCase
  Journal = Ace::Assign::Molecules::EvidenceJournal

  def test_exact_selection_reuses_deep_frozen_events_but_ordinary_reads_do_not
    journal, counts = reader
    Journal.with_event_read_operation do
      first = journal.read_events("assignment", commit: "a" * 40)
      assert_same first, journal.read_events("assignment", commit: "a" * 40)
      assert_equal 1, counts.fetch(:reads)
      assert_raises(FrozenError) { first << {} }
      assert_raises(FrozenError) { first.first.fetch("payload")["value"].replace("forged") }
      assert_raises(FrozenError) { first.first.fetch("payload")["nested"] << "forged" }
    end
    refute_same journal.read_events("assignment", commit: "a" * 40), journal.read_events("assignment", commit: "a" * 40)
    assert_equal 3, counts.fetch(:reads)
  end

  def test_implicit_current_is_selected_freshly_and_explicit_old_prefix_is_not_replaced_by_tip
    journal, counts = reader
    Journal.with_event_read_operation do
      assert_equal "a" * 40, journal.read_events("assignment").first.fetch("commit")
      journal.read_events("assignment")
      assert_equal 2, counts.fetch(:refs)
      assert_equal 1, counts.fetch(:reads)
      journal.instance_variable_set(:@test_ref, "b" * 40)
      assert_equal "b" * 40, journal.read_events("assignment").first.fetch("commit")
      assert_equal "a" * 40, journal.read_events("assignment", commit: "a" * 40).first.fetch("commit")
      assert_equal 3, counts.fetch(:reads)
      journal.read_events("other", commit: "a" * 40)
      assert_equal 4, counts.fetch(:reads)
    end
  end

  def test_nested_and_independent_contexts_are_isolated_and_ensure_cleans_body_or_refusal_errors
    journal, counts = reader
    Journal.with_event_read_operation do
      original = journal.read_events("assignment", commit: "a" * 40)
      [IOError, Ace::Assign::AttemptErrors::UnauthorizedIdentity].each do |error|
        assert_raises(error) do
          Journal.with_event_read_operation do
            refute_same original, journal.read_events("assignment", commit: "a" * 40)
            raise error, "controlled body/refusal"
          end
        end
        assert_same original, journal.read_events("assignment", commit: "a" * 40)
      end
      assert_equal 3, counts.fetch(:reads)
    end
    assert_nil Thread.current[:ace_assign_event_read_operation]
    Journal.with_event_read_operation { journal.read_events("assignment", commit: "a" * 40) }
    assert_equal 4, counts.fetch(:reads)
    assert_nil Thread.current[:ace_assign_event_read_operation]
  end

  def test_miss_or_failed_read_cannot_retain_previous_selection_and_journals_do_not_share
    journal, counts = reader
    other, other_counts = reader
    Journal.with_event_read_operation do
      journal.read_events("assignment", commit: "a" * 40)
      assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { journal.read_events("assignment", commit: "f" * 40) }
      journal.read_events("assignment", commit: "a" * 40)
      assert_equal 3, counts.fetch(:reads)
      other.read_events("assignment", commit: "a" * 40)
      assert_equal 1, other_counts.fetch(:reads)
      journal.read_events("assignment", commit: "a" * 40)
      assert_equal 4, counts.fetch(:reads)
    end
  end

  def test_concurrent_wire_contexts_do_not_share_even_for_the_same_journal_and_commit
    journal, counts = reader
    ready, release = Queue.new, Queue.new
    threads = 2.times.map do
      Thread.new do
        Journal.with_event_read_operation do
          events = journal.read_events("assignment", commit: "a" * 40)
          ready << events
          release.pop
          raise "same operation lost selection" unless events.equal?(journal.read_events("assignment", commit: "a" * 40))
        end
        raise "context leaked" if Thread.current[:ace_assign_event_read_operation]
      end
    end
    refute_same ready.pop, ready.pop
    2.times { release << true }
    threads.each(&:value)
    assert_equal 2, counts.fetch(:reads)
    assert_nil Thread.current[:ace_assign_event_read_operation]
  ensure
    threads&.each { |thread| thread.kill if thread.alive? }
  end

  def test_mutable_ref_names_nil_and_ordinary_mode_do_not_reuse_a_selected_proof
    journal, counts = reader
    Journal.with_event_read_operation do
      2.times { journal.read_events("assignment", commit: "HEAD") }
      assert_equal 2, counts.fetch(:reads)
      journal.read_events("assignment", commit: "a" * 40)
      assert_empty journal.read_events("assignment", commit: nil)
      journal.read_events("assignment", commit: "a" * 40)
      assert_equal 4, counts.fetch(:reads)
      journal.instance_variable_set(:@mode, :local)
      2.times { journal.read_events("assignment", commit: "a" * 40) }
      assert_equal 6, counts.fetch(:reads)
    end
  end

  def test_inventory_reuses_only_exact_immutable_identity_and_events_cannot_evict_it
    journal, counts = inventory_reader
    Journal.with_event_read_operation do
      original = journal.canonical_event_inventory!(commit: "a" * 40)
      journal.read_events("assignment", commit: "b" * 40)
      assert_same original, journal.canonical_event_inventory!(commit: "a" * 40)
      assert_equal 1, counts.fetch(:inventory)
      assert_raises(FrozenError) { original.fetch("events")["forged"] = [] }
      assert_raises(FrozenError) { original.fetch("events").fetch("assignment").first.fetch("payload")["value"].replace("forged") }
      refute_same original, journal.canonical_event_inventory!(commit: "b" * 40)
      assert_same original, journal.canonical_event_inventory!(commit: "a" * 40)
      assert_equal 2, counts.fetch(:inventory)
      %i[repo_root ref checkout_root read_boundary].each do |field|
        before = journal.canonical_event_inventory!(commit: "a" * 40)
        journal.instance_variable_set(:"@#{field}", field == :read_boundary ? Object.new : "/different/#{field}")
        refute_same before, journal.canonical_event_inventory!(commit: "a" * 40)
      end
      other, other_counts = inventory_reader
      other.canonical_event_inventory!(commit: "a" * 40)
      assert_equal 1, other_counts.fetch(:inventory)
      refute_same original, journal.canonical_event_inventory!(commit: "a" * 40)
    end
    before = counts.fetch(:inventory)
    2.times { journal.canonical_event_inventory!(commit: "a" * 40) }
    assert_equal before + 2, counts.fetch(:inventory)
  end

  def test_inventory_eviction_is_bounded_and_new_operation_verifies_again
    journal, counts = inventory_reader
    Journal.with_event_read_operation do
      oldest = journal.canonical_event_inventory!(commit: "0" * 40)
      Journal::OPERATION_INVENTORY_LIMIT.times do |index|
        journal.canonical_event_inventory!(commit: "%040x" % (index + 1))
      end
      assert_equal Journal::OPERATION_INVENTORY_LIMIT, Thread.current[:ace_assign_event_read_operation].fetch(:inventories).size
      refute_same oldest, journal.canonical_event_inventory!(commit: "0" * 40)
      assert_equal Journal::OPERATION_INVENTORY_LIMIT + 2, counts.fetch(:inventory)
    end
    before = counts.fetch(:inventory)
    Journal.with_event_read_operation { journal.canonical_event_inventory!(commit: "0" * 40) }
    assert_equal before + 1, counts.fetch(:inventory)
    assert_nil Thread.current[:ace_assign_event_read_operation]
  end

  def test_failed_inventory_is_not_cached_and_nested_refusal_restores_only_parent_operation
    journal, counts = inventory_reader
    Journal.with_event_read_operation do
      original = journal.canonical_event_inventory!(commit: "a" * 40)
      assert_raises(IOError) do
        Journal.with_event_read_operation do
          refute_same original, journal.canonical_event_inventory!(commit: "a" * 40)
          raise IOError, "controlled refusal"
        end
      end
      assert_same original, journal.canonical_event_inventory!(commit: "a" * 40)
      2.times { assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { journal.canonical_event_inventory!(commit: "f" * 40) } }
      assert_same original, journal.canonical_event_inventory!(commit: "a" * 40)
      assert_equal 4, counts.fetch(:inventory)
      %w[HEAD aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa].each do |commit|
        journal.instance_variable_set(:@mode, :local)
        before = counts.fetch(:inventory)
        2.times { journal.canonical_event_inventory!(commit: commit) }
        assert_equal before + 2, counts.fetch(:inventory)
      end
    end
    assert_nil Thread.current[:ace_assign_event_read_operation]
  end

  def test_concurrent_inventory_operations_never_share_a_journal_snapshot
    journal, counts = inventory_reader
    ready, release = Queue.new, Queue.new
    threads = 2.times.map do
      Thread.new do
        Journal.with_event_read_operation do
          inventory = journal.canonical_event_inventory!(commit: "a" * 40)
          ready << inventory
          release.pop
          raise "inventory replaced" unless inventory.equal?(journal.canonical_event_inventory!(commit: "a" * 40))
        end
      end
    end
    refute_same ready.pop, ready.pop
    2.times { release << true }
    threads.each(&:value)
    assert_equal 2, counts.fetch(:inventory)
  ensure
    threads&.each { |thread| thread.kill if thread.alive? }
  end

  def test_existing_inventory_answers_only_exact_event_view_and_current_ref_selection
    journal, counts = inventory_reader
    Journal.with_event_read_operation do
      inventory = journal.canonical_event_inventory!(commit: "a" * 40)
      assert_equal inventory.fetch("events").fetch("assignment"), journal.read_events("assignment")
      assert_equal 0, counts.fetch(:reads)
      assert_equal 1, counts.fetch(:refs)
      journal.instance_variable_set(:@test_ref, "b" * 40)
      assert_equal "b" * 40, journal.read_events("assignment").first.fetch("commit")
      assert_equal 1, counts.fetch(:reads)
      assert_equal inventory.fetch("events").fetch("assignment"), journal.read_events("assignment", commit: "a" * 40)
      journal.instance_variable_set(:@read_boundary, Object.new)
      assert_equal "a" * 40, journal.read_events("assignment", commit: "a" * 40).first.fetch("commit")
      assert_equal 2, counts.fetch(:reads)
    end
    journal.read_events("assignment", commit: "a" * 40)
    assert_equal 3, counts.fetch(:reads), "inventory cannot escape its wire operation"
  end

  def test_raw_service_record_reuse_keeps_exact_owner_and_never_retains_missing_or_failed_reads
    journal, _ = reader
    reads = []
    journal.define_singleton_method(:read_service_request_record) do |id, commit:|
      reads << [id, commit]
      raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "controlled corrupt record" if commit == "f" * 40
      next nil if id == "missing"
      {"request_id" => id, "state" => "accepted", "commit" => commit, "nested" => ["original"]}
    end
    Journal.with_event_read_operation do
      first = journal.service_request("request")
      first.fetch("nested") << "forged"
      assert_equal ["original"], journal.service_request("request").fetch("nested")
      assert_equal 1, reads.size
      journal.instance_variable_set(:@test_ref, "b" * 40)
      assert_equal "b" * 40, journal.service_request("request").fetch("commit")
      assert_equal "a" * 40, journal.service_request("request", commit: "a" * 40).fetch("commit")
      assert_equal 3, reads.size
      %i[repo_root ref checkout_root read_boundary evidence_reader service_authorizer].each do |field|
        before = reads.size
        journal.instance_variable_set(:"@#{field}", field.to_s.end_with?("reader", "authorizer", "boundary") ? Object.new : "/changed/#{field}")
        journal.service_request("request", commit: "a" * 40)
        assert_equal before + 1, reads.size
      end
      before = reads.size
      assert_raises(ArgumentError) { journal.service_request("bad/id", commit: "a" * 40) }
      journal.service_request("request", commit: "a" * 40)
      assert_equal before + 1, reads.size, "invalid request evicts the old raw slot"
      before = reads.size
      2.times { assert_nil journal.service_request("missing", commit: "a" * 40) }
      assert_equal before + 2, reads.size
      before = reads.size
      2.times { assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { journal.service_request("request", commit: "f" * 40) } }
      journal.service_request("request", commit: "a" * 40)
      assert_equal before + 3, reads.size
      journal.service_request("another", commit: "a" * 40)
      assert_equal "another", reads.last.first
    end
    before = reads.size
    2.times { journal.service_request("request", commit: "a" * 40) }
    assert_equal before + 2, reads.size
  end

  def test_raw_record_nested_and_concurrent_operations_keep_independent_slots
    journal, _ = reader
    reads = 0
    journal.define_singleton_method(:read_service_request_record) do |id, commit:|
      reads += 1
      {"request_id" => id, "state" => "accepted", "commit" => commit}
    end
    ready, release = Queue.new, Queue.new
    threads = 2.times.map do
      Thread.new do
        Journal.with_event_read_operation do
          first = journal.service_request("request")
          Journal.with_event_read_operation { assert_equal first, journal.service_request("request") }
          ready << first
          release.pop
          assert_equal first, journal.service_request("request")
        end
      end
    end
    2.times { ready.pop }
    2.times { release << true }
    threads.each(&:value)
    assert_equal 4, reads, "each outer/nested operation owns its raw selection"
    assert_nil Thread.current[:ace_assign_event_read_operation]
  ensure
    threads&.each { |thread| thread.kill if thread.alive? }
  end

  private

  # Only the memo's maintained decoder boundary is controlled here; actual
  # Git/Client/Server/CAS composition has a separate feature responsibility.
  def inventory_reader
    journal, counts = reader
    counts[:inventory] = 0
    journal.define_singleton_method(:read_canonical_inventory!) do |commit:|
      counts[:inventory] += 1
      raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "controlled invalid history" if commit == "f" * 40
      freeze_inventory_projection("commit" => commit, "events" => {"assignment" => [{"payload" => {"value" => "original"}}]}, "introductions" => {})
    end
    [journal, counts]
  end

  def reader
    counts = {reads: 0, refs: 0}
    journal = Journal.allocate
    journal.instance_variable_set(:@repo_root, "/fixture/repo")
    journal.instance_variable_set(:@ref, "refs/ace/execution")
    journal.instance_variable_set(:@checkout_root, "/fixture/checkout")
    journal.instance_variable_set(:@mode, :protected)
    journal.instance_variable_set(:@test_ref, "a" * 40)
    journal.define_singleton_method(:ref_value) { counts[:refs] += 1; @test_ref }
    journal.define_singleton_method(:read_event_snapshots!) do |ids, commit:|
      counts[:reads] += 1
      raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "controlled failed read" if commit == "f" * 40
      [{ids.first => [{"commit" => commit, "payload" => {"value" => "original", "nested" => ["original"]}}]}, {}]
    end
    [journal, counts]
  end
end
