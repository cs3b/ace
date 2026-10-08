# frozen_string_literal: true
require_relative "../test_helper"
require "ace/lab/organisms/protected_cleanup_owner"

class ProtectedCleanupAdmissionReadScopeTest < Minitest::Test
  Journal = Ace::Assign::Molecules::EvidenceJournal
  class EffectBoundaryReached < StandardError; end

  def test_each_route_reuses_only_its_held_read_and_discards_before_effects_and_next_connection
    %w[execute preview inspect].each do |kind|
      with_owner do |owner, journal, reads, observations|
        observations[:admit] = lambda do
          first = journal.read_events("assignment")
          assert_same first, journal.read_events("assignment")
          assert_raises(FrozenError) { first.first.fetch("payload")["value"].replace("forged") }
        end
        2.times do |index|
          error = assert_raises(EffectBoundaryReached) { invoke(owner, kind, "request-#{index}") }
          assert_equal "effect boundary", error.message
          assert_nil Thread.current[:ace_assign_event_read_operation]
        end
        assert_equal 2, reads.size
        assert_equal 2, observations[:effects]
        assert_equal 2, observations[:peers]
        assert_equal 2, observations[:admissions]
      end
    end
  end

  def test_changed_current_commit_is_read_fresh_and_explicit_original_remains_original
    with_owner do |owner, journal, reads, observations|
      observations[:admit] = lambda do
        assert_equal "a" * 40, journal.read_events("assignment").first.fetch("commit")
        journal.instance_variable_set(:@test_ref, "b" * 40)
        assert_equal "b" * 40, journal.read_events("assignment").first.fetch("commit")
        assert_equal "a" * 40, journal.read_events("assignment", commit: "a" * 40).first.fetch("commit")
      end
      assert_raises(EffectBoundaryReached) { invoke(owner, "execute", "original") }
      assert_equal ["a" * 40, "b" * 40, "a" * 40], reads
      assert_nil Thread.current[:ace_assign_event_read_operation]
    end
  end

  def test_admission_refusal_discards_reads_without_effect_and_next_connection_reauthenticates
    with_owner do |owner, journal, reads, observations|
      observations[:admit] = lambda do
        journal.read_events("assignment")
        raise SecurityError, "canonical selection refused"
      end
      error = assert_raises(SecurityError) { invoke(owner, "execute", "refused") }
      assert_equal "canonical selection refused", error.message
      assert_nil Thread.current[:ace_assign_event_read_operation]
      assert_equal 0, observations[:effects]
      observations[:admit] = -> { journal.read_events("assignment") }
      assert_raises(EffectBoundaryReached) { invoke(owner, "execute", "accepted") }
      assert_equal 2, reads.size
      assert_equal 2, observations[:peers]
      assert_equal 2, observations[:admissions]
      assert_equal 1, observations[:effects]
    end
  end

  private

  # This test owns transport/read lifetime only: the event decoder and native
  # collaborators are controlled. Actual canonical admission/import/refusals
  # remain in protected_cleanup_dispatch_test with temporary Git and sockets.
  def with_owner
    Dir.mktmpdir("cleanup-read-scope", Etc.getpwuid(Process.uid).dir) do |root|
      journal = Journal.allocate
      journal.instance_variable_set(:@mode, :protected)
      journal.instance_variable_set(:@repo_root, root)
      journal.instance_variable_set(:@ref, "refs/ace/execution")
      journal.instance_variable_set(:@checkout_root, root)
      journal.instance_variable_set(:@test_ref, "a" * 40)
      reads = []
      journal.define_singleton_method(:ref_value) { @test_ref }
      journal.define_singleton_method(:read_event_snapshots!) do |ids, commit:|
        reads << commit
        [{ids.first => [{"commit" => commit, "payload" => {"value" => "original"}}]}, {}]
      end
      observations = {effects: 0, peers: 0, admissions: 0}
      peer = {"uid" => 13005}
      original = {"controlled" => "root lifetime"}
      observer = Object.new
      observer.define_singleton_method(:observe_self!) { |**_| original }
      kernel = Object.new
      kernel.define_singleton_method(:peer) { |_| observations[:peers] += 1; peer }
      admission = Object.new
      admission.define_singleton_method(:receiver!) { |_| observations[:admissions] += 1 }
      %i[admit! preview! inspect!].each do |method|
        admission.define_singleton_method(method) do |frame:, journal:, **_|
          observations.fetch(:admit).call
          {"record" => {"request_id" => frame.fetch("request_id"), "operation_owner_binding" => {"controlled" => "other"}}}
        end
      end
      installer = Object.new
      %i[execute_cleanup! preview_cleanup! inspect_cleanup!].each do |method|
        installer.define_singleton_method(method) do |**_|
          raise "read memo crossed effect boundary" if Thread.current[:ace_assign_event_read_operation]
          observations[:effects] += 1
          raise EffectBoundaryReached, "effect boundary"
        end
      end
      snapshot = Object.new
      snapshot.define_singleton_method(:with) { |deadline:, &block| block.call(:held) }
      owner = Ace::Lab::Organisms::ProtectedCleanupOwner.new(observer: observer, admission: admission,
        snapshots: ->(&block) { block.call(snapshot) }, journals: ->(view) { raise "wrong view" unless view == :held; journal },
        kernel: kernel, installer: installer, scratch_root: root)
      yield owner, journal, reads, observations
    end
  end

  def invoke(owner, kind, request_id)
    local, remote = UNIXSocket.pair
    wire = Ace::Runtime::Molecules::ProtectedSocket
    wire.write(local, {"schema" => Ace::Lab::Molecules::ProtectedCleanupOwnerClient::SCHEMA,
      "kind" => kind, "request_id" => request_id}, deadline: wire.deadline(5))
    local.shutdown(Socket::SHUT_WR)
    owner.handle(remote)
  ensure
    local&.close unless local&.closed?
    remote&.close unless remote&.closed?
  end
end
