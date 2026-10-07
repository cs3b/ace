# frozen_string_literal: true

require_relative "../../test_helper"
require "json"
require "open3"
require "fileutils"

module Ace
  module Assign
    class EvidenceJournalTest < AceAssignTestCase
      REF = "refs/ace/execution"

      def test_event_prefix_selects_introduction_through_normal_inherited_appearances
        with_temp_cache do |cache_dir|
          repo = File.join(cache_dir, "repo")
          init_repo(repo)
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF, checkout_root: File.join(cache_dir, "co"))
          event = build_event(type: "intent", attempt_id: "atj0001", payload: {"operation" => "implement"})
          introduction = journal.append(assignment_id: "8wrja", attempt_id: "atj0001", events: [event])
          second = build_event(type: "process_start", attempt_id: "atj0001", payload: {"pid" => 123}, previous_digest: event.fetch("digest"))
          tip = journal.append(assignment_id: "8wrja", attempt_id: "atj0001", events: [second])
          assert_equal introduction, journal.event_commit!(assignment_id: "8wrja", event_digest: event.fetch("digest"), commit: tip)
          assert_equal tip, journal.event_commit!(assignment_id: "8wrja", event_digest: second.fetch("digest"), commit: tip)
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            journal.event_commit!(assignment_id: "8wrja", event_digest: "f" * 64, commit: tip)
          end
        end
      end

      def test_event_prefix_refuses_disappearance_reappearance_and_merge_topology
        with_temp_cache do |cache_dir|
          repo = File.join(cache_dir, "repo")
          base = init_repo(repo)
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF, checkout_root: File.join(cache_dir, "co"))
          event = build_event(type: "intent", attempt_id: "atj0001", payload: {"operation" => "implement"})
          introduction = journal.append(assignment_id: "8wrja", attempt_id: "atj0001", events: [event])
          empty_tree = git(repo, "rev-parse", "#{base}^{tree}").strip
          full_tree = git(repo, "rev-parse", "#{introduction}^{tree}").strip
          absent = git(repo, "commit-tree", empty_tree, "-p", introduction, "-m", "removed event").strip
          reappeared = git(repo, "commit-tree", full_tree, "-p", absent, "-m", "reintroduced event").strip
          merged = git(repo, "commit-tree", full_tree, "-p", introduction, "-p", base, "-m", "unsupported merge").strip
          [absent, reappeared, merged].each do |tip|
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              journal.event_commit!(assignment_id: "8wrja", event_digest: event.fetch("digest"), commit: tip)
            end
          end
        end
      end

      def test_event_prefix_refuses_changed_serialization_of_the_same_valid_event
        with_temp_cache do |cache_dir|
          repo = File.join(cache_dir, "repo")
          init_repo(repo)
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF, checkout_root: File.join(cache_dir, "co"))
          event = build_event(type: "intent", attempt_id: "atj0001", payload: {"operation" => "implement"})
          introduction = journal.append(assignment_id: "8wrja", attempt_id: "atj0001", events: [event])
          checkout = File.join(cache_dir, "co", "journal")
          path = Dir.glob(File.join(checkout, "execution", "8wrja", "events", "*.json")).fetch(0)
          File.write(path, JSON.generate(event))
          git(checkout, "add", "-A")
          git(checkout, "commit", "-m", "changed serialization")
          tip = git(checkout, "rev-parse", "HEAD").strip
          assert Models::EvidenceEvent.chain_valid?(journal.read_events("8wrja", commit: tip))
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            journal.event_commit!(assignment_id: "8wrja", event_digest: event.fetch("digest"), commit: tip)
          end
          assert_equal introduction, journal.event_commit!(assignment_id: "8wrja", event_digest: event.fetch("digest"), commit: introduction)
        end
      end

      def test_fixed_snapshot_requires_an_actual_readable_commit_object
        with_temp_cache do |cache_dir|
          repo = File.join(cache_dir, "repo")
          commit = init_repo(repo)
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF, checkout_root: File.join(cache_dir, "co"))
          assert journal.verify_commit!(commit)
          assert_raises(AttemptErrors::EvidenceUnavailable) { journal.verify_commit!(nil) }
          assert_raises(AttemptErrors::EvidenceUnavailable) { journal.verify_commit!(git(repo, "rev-parse", "HEAD^{tree}").strip) }
          assert_raises(AttemptErrors::EvidenceUnavailable) { journal.verify_commit!("f" * 40) }
        end
      end

      def with_temp_cache_dir
        dir = nil
        with_temp_cache { |cache_dir| dir = cache_dir }
        dir
      end

      def build_event(type:, attempt_id:, payload:, previous_digest: nil, recorded_at: Time.now.utc)
        Models::EvidenceEvent.build(
          type: type,
          attempt_id: attempt_id,
          payload: payload,
          previous_digest: previous_digest,
          recorded_at: recorded_at
        )
      end

      def init_repo(repo)
        FileUtils.mkdir_p(repo)
        git(repo, "init", "-b", "main")
        git(repo, "config", "user.name", "test")
        git(repo, "config", "user.email", "test@example.com")
        File.write(File.join(repo, "README.md"), "candidate work\n")
        git(repo, "add", "README.md")
        git(repo, "commit", "-m", "candidate base")
        git(repo, "rev-parse", "HEAD").strip
      end

      def git(dir, *argv)
        out, stderr, status = Open3.capture3("git", *argv, chdir: dir, stdin_data: "")
        flunk "git #{argv.join(' ')} failed: #{stderr}" unless status.success?
        out
      end

      def test_append_seeds_ref_journals_events_and_leaves_candidate_head_unchanged
        with_temp_cache do |cache_dir|
          repo = File.join(cache_dir, "repo")
          candidate_head = init_repo(repo)
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF, checkout_root: File.join(cache_dir, "co"))

          event = build_event(type: "intent", attempt_id: "atj0001", payload: {"operation" => "implement"})
          commit = journal.append(assignment_id: "8wrja", attempt_id: "atj0001", events: [event])

          assert_equal commit, journal.ref_value
          refute_equal candidate_head, journal.ref_value
          assert_equal candidate_head, git(repo, "rev-parse", "HEAD").strip

          events = journal.read_events("8wrja")
          assert_equal 1, events.size
          assert_equal "intent", events.first["type"]
          assert_equal "atj0001", events.first["attempt_id"]
          assert Models::EvidenceEvent.valid?(events.first)
        end
      end

      def terminal_receipt(repo, binding, outcome)
        evidence = File.join(repo, "forge", "receipt-#{outcome}")
        FileUtils.mkdir_p(File.dirname(evidence))
        content = "ace-service-attestation request:#{binding["request_id"]} " \
          "input:#{binding["input_digest"]} outcome:#{outcome}\n"
        File.write(evidence, content)
        binding.merge("outcome" => outcome, "executor_uid" => binding["executor_uid"],
          "evidence" => [{"ref" => "forge/receipt-#{outcome}",
                          "sha256" => Digest::SHA256.hexdigest(content)}])
      end

      def test_service_request_claim_is_idempotent_and_journal_backed
        with_temp_cache do |cache_dir|
          repo = File.join(cache_dir, "repo")
          candidate_head = init_repo(repo)
          root = File.join(cache_dir, "co")
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF, checkout_root: root)
          binding = {"request_id" => "req-1", "assignment_id" => "assignment-1", "attempt_id" => "attempt-1",
                     "project_id" => "ace", "operation" => "publish", "input_digest" => "a" * 64,
                     "target" => {"resource" => "gem/ace"}, "candidate_head" => candidate_head,
                     "executor_uid" => Process.uid, "transport" => "local"}

          first = journal.claim_service_request(binding)
          repeated = journal.claim_service_request(binding)
          assert_equal "accepted", first["state"]
          assert_equal first.reject { |key, _| %w[journal_commit claimed_at].include?(key) }, repeated.reject { |key, _| key == "claimed_at" }
          assert_equal 1, journal.read_events("assignment-1").size
          assert_equal candidate_head, git(repo, "rev-parse", "HEAD").strip
          assert_raises(AttemptErrors::Conflict) do
            journal.claim_service_request(binding.merge("input_digest" => "b" * 64))
          end

          journal.transition_service_request("req-1", state: "uncertain")
          # Terminal transitions are validated at the journal boundary: a
          # receipt with the wrong schema, binding, or outcome is refused
          # even with a caller-supplied validated flag.
          assert_raises(AttemptErrors::ReceiptRejected) do
            journal.transition_service_request("req-1", state: "succeeded", receipt: {"evidence" => "ok"},
              validated: true)
          end
          assert_raises(AttemptErrors::ReceiptRejected) do
            journal.transition_service_request("req-1", state: "succeeded",
              receipt: terminal_receipt(repo, binding, "failed"), validated: true)
          end
          journal.transition_service_request("req-1", state: "succeeded",
            receipt: terminal_receipt(repo, binding, "succeeded"), validated: true)
          reloaded = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF, checkout_root: root)
          assert_equal "succeeded", reloaded.service_request("req-1")["state"]
          assert_equal 3, reloaded.read_events("assignment-1").size
          assert_raises(AttemptErrors::InvalidState) do
            reloaded.transition_service_request("req-1", state: "failed", validated: true)
          end
        end
      end

      def test_racing_duplicate_service_claims_create_one_intent
        with_temp_cache do |cache_dir|
          repo = File.join(cache_dir, "repo")
          init_repo(repo)
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF,
            checkout_root: File.join(cache_dir, "co"))
          binding = {"request_id" => "race-1", "assignment_id" => "assignment-race",
                     "attempt_id" => "attempt-race", "project_id" => "ace", "operation" => "forge-sync",
                     "input_digest" => "a" * 64}
          results = 2.times.map { Thread.new { journal.claim_service_request(binding) } }.map(&:value)
          assert_equal %w[accepted accepted], results.map { |result| result["state"] }
          assert_equal 1, journal.read_events("assignment-race").length
        end
      end

      def test_exact_authorization_is_consumed_by_first_live_claim
        with_temp_cache do |cache_dir|
          repo = File.join(cache_dir, "repo")
          init_repo(repo)
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF,
            checkout_root: File.join(cache_dir, "co"))
          base = {"assignment_id" => "assignment-auth", "attempt_id" => "attempt-auth",
                  "project_id" => "ace", "operation" => "publish", "input_digest" => "a" * 64,
                  "target" => {"resource" => "gem/ace-assign"}, "authorization" => "decision-9"}

          # A request born rejected never consumed the decision: a fresh
          # claim for the same exact proposal succeeds.
          journal.reject_service_request(base.merge("request_id" => "auth-0"), reason: "policy_rejected")
          journal.claim_service_request(base.merge("request_id" => "auth-1"))

          error = assert_raises(AttemptErrors::Conflict) do
            journal.claim_service_request(base.merge("request_id" => "auth-2", "input_digest" => "b" * 64))
          end
          assert_includes error.message, "already consumed by request auth-1"

          # A different target under the same reference is a different exact
          # proposal and does not conflict.
          other_target = journal.claim_service_request(
            base.merge("request_id" => "auth-3", "input_digest" => "c" * 64,
              "target" => {"resource" => "gem/ace-lab"}))
          assert_equal "accepted", other_target["state"]

          # Withdrawing a dispatched claim never frees the decision: the
          # effect may have happened even though the receipt was lost.
          journal.reject_service_request(base.merge("request_id" => "auth-1"), reason: "withdrawn")
          assert_raises(AttemptErrors::Conflict) do
            journal.claim_service_request(base.merge("request_id" => "auth-4"))
          end
          assert_equal 3, journal.service_request_records.size
        end
      end

      def test_append_twice_advances_ref_and_keeps_both_batches
        with_temp_cache do |cache_dir|
          repo = File.join(cache_dir, "repo")
          init_repo(repo)
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF, checkout_root: File.join(cache_dir, "co"))

          first = build_event(type: "intent", attempt_id: "atj0002", payload: {"operation" => "implement"})
          journal.append(assignment_id: "8wrjb", attempt_id: "atj0002", events: [first])
          second = build_event(
            type: "receipt_accepted",
            attempt_id: "atj0002",
            payload: {"receipt" => {"digest" => "abc", "operation" => "implement", "verdict" => "succeeded"}},
            previous_digest: first["digest"]
          )
          journal.append(assignment_id: "8wrjb", attempt_id: "atj0002", events: [second])

          events = journal.read_events("8wrjb")
          assert_equal %w[intent receipt_accepted], events.map { |e| e["type"] }
          assert Models::EvidenceEvent.chain_valid?(events)

          receipts = journal.accepted_receipts("8wrjb")
          assert_equal 1, receipts.size
          assert_equal "implement", receipts.first["operation"]
        end
      end

      def test_duplicate_append_is_a_no_op_on_the_ref
        with_temp_cache do |cache_dir|
          repo = File.join(cache_dir, "repo")
          init_repo(repo)
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF, checkout_root: File.join(cache_dir, "co"))

          event = build_event(type: "intent", attempt_id: "atj0003", payload: {"operation" => "review"})
          journal.append(assignment_id: "8wrjc", attempt_id: "atj0003", events: [event])
          value_before = journal.ref_value

          journal.append(assignment_id: "8wrjc", attempt_id: "atj0003", events: [event])

          assert_equal value_before, journal.ref_value
          assert_equal 1, journal.read_events("8wrjc").size
        end
      end

      def test_events_survive_checkout_loss_and_reload_from_ref
        with_temp_cache do |cache_dir|
          repo = File.join(cache_dir, "repo")
          init_repo(repo)
          checkout_root = File.join(cache_dir, "co")
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF, checkout_root: checkout_root)

          event = build_event(type: "intent", attempt_id: "atj0004", payload: {"operation" => "verify"})
          journal.append(assignment_id: "8wrjd", attempt_id: "atj0004", events: [event])

          # Simulate a lost terminal session: the disposable checkout vanishes.
          FileUtils.rm_rf(checkout_root)

          reloaded = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF, checkout_root: checkout_root)
          events = reloaded.read_events("8wrjd")
          assert_equal 1, events.size
          assert_equal "verify", events.first["payload"]["operation"]
        end
      end

      def test_cas_conflict_replays_on_top_of_competing_writer
        with_temp_cache do |cache_dir|
          repo = File.join(cache_dir, "repo")
          init_repo(repo)
          checkout_root = File.join(cache_dir, "co")
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF, checkout_root: checkout_root)

          event = build_event(type: "intent", attempt_id: "atj0005", payload: {"operation" => "merge"})
          original = Molecules::EvidenceJournal.instance_method(:update_ref_cas)
          calls = 0
          rival_appended = false

          journal.stub(:update_ref_cas, lambda { |new_commit, expected_old|
            calls += 1
            if calls == 1
              # A competing writer on another machine advances the same ref
              # between our read and our compare-and-swap.
              unless rival_appended
                rival_event = build_event(type: "intent", attempt_id: "atrival", payload: {"operation" => "publish"})
                rival = Molecules::EvidenceJournal.new(
                  repo_root: repo, ref: REF, checkout_root: File.join(cache_dir, "rival-co")
                )
                rival.append(assignment_id: "8wrjrival", attempt_id: "atrival", events: [rival_event])
                rival_appended = true
              end
              false
            else
              original.bind(journal).call(new_commit, expected_old)
            end
          }) do
            journal.append(assignment_id: "8wrje", attempt_id: "atj0005", events: [event])
          end

          assert_equal 1, journal.read_events("8wrje").size
          assert_equal 1, journal.read_events("8wrjrival").size
          assert_equal 2, Dir.glob(File.join(checkout_root, "journal", "execution", "*", "events", "*.json")).size
        end
      end

      def test_events_are_ordered_by_digest_chain_not_filename
        with_temp_cache do |cache_dir|
          repo = File.join(cache_dir, "repo")
          init_repo(repo)
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF, checkout_root: File.join(cache_dir, "co"))

          same_second = Time.utc(2026, 9, 28, 12, 0, 0)
          intent = build_event(type: "intent", attempt_id: "atchn01", payload: {"scope" => "010"}, recorded_at: same_second)
          journal.append(assignment_id: "8wrchn", attempt_id: "atchn01", events: [intent])

          transition = build_event(
            type: "transition", attempt_id: "atchn01", payload: {"from" => "running", "to" => "uncertain"},
            previous_digest: intent["digest"], recorded_at: same_second
          )
          journal.append(assignment_id: "8wrchn", attempt_id: "atchn01", events: [transition])

          # Same second as the transition; filename sort would place the
          # reconciliation BEFORE the transition ("r" < "t").
          reconciliation = build_event(
            type: "reconciliation", attempt_id: "atchn01",
            payload: {"resolution" => "succeeded", "receipt_digest" => "abc"},
            previous_digest: transition["digest"], recorded_at: same_second
          )
          journal.append(assignment_id: "8wrchn", attempt_id: "atchn01", events: [reconciliation])

          events = journal.read_events("8wrchn")
          assert_equal %w[intent transition reconciliation], events.map { |e| e["type"] }
          assert Models::EvidenceEvent.chain_valid?(events)
        end
      end

      def test_unavailable_repo_fails_closed
        with_temp_cache do |cache_dir|
          journal = Molecules::EvidenceJournal.new(
            repo_root: File.join(cache_dir, "not-a-repo"),
            ref: REF,
            checkout_root: File.join(cache_dir, "co")
          )

          refute journal.available?
          event = build_event(type: "intent", attempt_id: "atj0006", payload: {"operation" => "review"})
          error = assert_raises(AttemptErrors::EvidenceUnavailable) do
            journal.append(assignment_id: "8wrjf", attempt_id: "atj0006", events: [event])
          end
          assert_equal 5, error.exit_code
        end
      end

      def test_cas_conflict_stderr_is_retryable_not_fatal
        journal = Molecules::EvidenceJournal.new(repo_root: Dir.pwd, ref: REF, checkout_root: File.join(with_temp_cache_dir, "co"))

        conflict = "fatal: cannot lock ref 'refs/ace/execution': is at 1111111 but expected 2222222"
        refute journal.send(:git_broken?, conflict)
        assert journal.send(:git_broken?, "fatal: could not read from remote repository")
        refute journal.send(:git_broken?, "")
      end

      def test_journal_discovers_assignment_ids_from_the_ref
        with_temp_cache do |cache_dir|
          repo = File.join(cache_dir, "repo")
          init_repo(repo)
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF, checkout_root: File.join(cache_dir, "co"))

          event = build_event(type: "intent", attempt_id: "ataidi1", payload: {"scope" => "010"})
          journal.append(assignment_id: "8wraids", attempt_id: "ataidi1", events: [event])

          FileUtils.rm_rf(cache_dir) if false
          assert_includes journal.assignment_ids, "8wraids"
        end
      end

      def test_seed_only_ref_reports_absent_attempt_without_recreating_cache_or_checkout
        with_temp_cache do |cache_dir|
          repo = File.join(cache_dir, "repo")
          candidate_head = init_repo(repo)
          checkout = File.join(cache_dir, "co")
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF, checkout_root: checkout)
          # Reproduce the crash window after seed publication, before the first event.
          journal.send(:seed_ref)
          seed = journal.ref_value
          attempt_cache = File.join(cache_dir, "lost-cache")
          FileUtils.mkdir_p(attempt_cache)
          FileUtils.rm_rf(attempt_cache)
          assert_empty journal.assignment_ids
          coordinator = Organisms::AttemptCoordinator.new(repo_root: repo, cache_base: attempt_cache, journal: journal)
          error = assert_raises(AttemptErrors::NotFound) do
            coordinator.evidence(attempt_id: "absent", receipt_digest: "a" * 64)
          end
          assert_includes error.message, "not found"
          refute File.exist?(attempt_cache)
          refute File.exist?(checkout)
          assert_equal seed, journal.ref_value
          assert_equal candidate_head, git(repo, "rev-parse", "HEAD").strip
        end
      end

      def test_read_events_empty_when_ref_missing
        with_temp_cache do |cache_dir|
          repo = File.join(cache_dir, "repo")
          init_repo(repo)
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: REF, checkout_root: File.join(cache_dir, "co"))

          assert_empty journal.read_events("8wrjg")
          assert_nil journal.ref_value
        end
      end
    end
  end
end
