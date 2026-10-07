# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/launch_lifecycle"

module Ace
  module Assign
    class HistoryOperationTest < AceAssignTestCase
      class Journal
        attr_accessor :repo_root, :ref, :checkout_root, :refuse
        attr_reader :calls
        def initialize
          @repo_root, @ref, @checkout_root = "/original/repo", "refs/ace/execution", "/original/checkout"
          @calls = 0
        end
        def evidence_mode; :protected; end
        def event_commit!(**)
          @calls += 1
          raise AttemptErrors::EvidenceUnavailable, "tampered prefix" if refuse
          "a" * 40
        end
      end

      def with_owner
        with_temp_cache do |root|
          deployment = Object.new
          deployment.define_singleton_method(:authority) { |_| {"state_root" => root} }
          owner = Authority::LaunchLifecycle.new(deployment: deployment)
          map = {"authority_id" => "authority", "execution_scope" => {"slot_id" => "slot"}}
          yield owner, map
        ensure
          owner&.close
        end
      end

      def verify(owner, journal, **changes)
        owner.send(:historical_event_commit!, journal, **{assignment_id: "assignment", event_digest: "b" * 64, commit: "c" * 40}.merge(changes))
      end

      def test_one_held_operation_shares_only_exact_immutable_prefix_and_discards_it
        with_owner do |owner, map|
          journal = Journal.new
          assert_raises(AttemptErrors::EvidenceUnavailable) { verify(owner, journal) }
          owner.send(:with_slot, map) do
            3.times { assert_equal "a" * 40, verify(owner, journal) }
            assert_equal 1, journal.calls
            verify(owner, journal, commit: "d" * 40)
            verify(owner, journal, assignment_id: "other")
            verify(owner, journal, event_digest: "e" * 64)
            journal.repo_root = "/other/repo"
            verify(owner, journal)
            journal.ref = "refs/ace/other"
            verify(owner, journal)
            journal.checkout_root = "/other/checkout"
            verify(owner, journal)
            assert_equal 7, journal.calls
            other = Journal.new
            verify(owner, other)
            assert_equal 1, other.calls
          end
          owner.send(:with_slot, map) { verify(owner, journal) }
          assert_equal 8, journal.calls
          assert_raises(AttemptErrors::EvidenceUnavailable) { verify(owner, journal) }
        end
      end

      def test_actual_first_parent_scan_is_shared_but_changed_history_still_refuses
        with_owner do |owner, map|
          with_temp_cache do |root|
            repo = File.join(root, "repo")
            FileUtils.mkdir_p(repo)
            git = lambda do |*args|
              out, error, status = Open3.capture3("git", "-C", repo, *args, stdin_data: "")
              assert status.success?, error
              out.delete_suffix("\n")
            end
            git.call("init", "-b", "main")
            git.call("config", "user.name", "test")
            git.call("config", "user.email", "test@example.com")
            git.call("commit", "--allow-empty", "-m", "base")
            base = git.call("rev-parse", "HEAD")
            journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(root, "checkout"))
            # Controlled protection classification only; the actual immutable
            # Git reader and first-parent validation below are unmodified.
            journal.define_singleton_method(:evidence_mode) { :protected }
            event = Models::EvidenceEvent.build(type: "intent", attempt_id: "attempt", payload: {"scope" => "one"})
            tip = journal.append(assignment_id: "assignment", attempt_id: "attempt", events: [event])
            scans = 0
            scan = journal.method(:event_commit!)
            journal.define_singleton_method(:event_commit!) { |**args| scans += 1; scan.call(**args) }
            owner.send(:with_slot, map) do
              3.times { assert_equal tip, verify(owner, journal, commit: tip, event_digest: event.fetch("digest")) }
              assert_equal 1, scans
              empty_tree = git.call("rev-parse", "#{base}^{tree}")
              removed = git.call("commit-tree", empty_tree, "-p", tip, "-m", "removed canonical event")
              assert_raises(AttemptErrors::EvidenceUnavailable) do
                verify(owner, journal, commit: removed, event_digest: event.fetch("digest"))
              end
              assert_equal 2, scans
            end
            owner.send(:with_slot, map) { assert_equal tip, verify(owner, journal, commit: tip, event_digest: event.fetch("digest")) }
            assert_equal 3, scans
          end
        end
      end

      def test_refusal_is_not_cached_and_exception_cannot_leak_operation_snapshot
        with_owner do |owner, map|
          journal = Journal.new
          journal.refuse = true
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            owner.send(:with_slot, map) { verify(owner, journal) }
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { verify(owner, journal) }
          owner.send(:with_slot, map) do
            2.times { assert_raises(AttemptErrors::EvidenceUnavailable) { verify(owner, journal) } }
            journal.refuse = false
            assert_equal "a" * 40, verify(owner, journal)
          end
          assert_equal 4, journal.calls
        end
      end
    end
  end
end
