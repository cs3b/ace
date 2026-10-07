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

  private

  # Only the memo's maintained decoder boundary is controlled here; actual
  # Git/Client/Server/CAS composition has a separate feature responsibility.
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
