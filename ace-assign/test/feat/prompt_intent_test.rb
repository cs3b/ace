# frozen_string_literal: true
require_relative "../test_helper"
require "open3"
require "fileutils"

module Ace
  module Assign
    class PromptIntentTest < AceAssignTestCase
      def with_journal
        with_temp_cache do |cache|
          root = Dir.mktmpdir("prompt-intent-", cache)
          repo = File.join(root, "repo")
          FileUtils.mkdir_p(repo)
          git(repo, "init", "-b", "main")
          git(repo, "-c", "user.name=test", "-c", "user.email=test@localhost", "commit", "--allow-empty", "-m", "candidate")
          yield Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(root, "checkout"))
        end
      end

      def git(repo, *args)
        _output, error, status = Open3.capture3("git", *args, chdir: repo, stdin_data: "")
        assert status.success?, error
      end

      def binding
        {"mutation_id" => "public-prompt", "action" => "prompt_attempt", "assignment_id" => "assignment",
          "attempt_id" => "attempt", "mapping_id" => "mapping", "project_id" => "project", "expected_generation" => 0,
          "caller" => {"role" => "supervisor", "uid" => 11001, "gid" => 11001, "groups" => [11001]},
          "original_binding_digest" => "b" * 64, "text_sha256" => Digest::SHA256.hexdigest("private prompt"), "text_bytes" => 14}
      end

      def peer(birth = "original")
        {"pid" => 100, "parent_pid" => 1, "uid" => 11001, "gid" => 11001, "groups" => [11001], "host" => "host", "started_at" => birth}
      end

      def issue(journal, value = binding, identity = peer, &block)
        journal.issue_prompt(binding: value, issued_by: identity, &(block || ->(*) {}))
      end

      def test_actual_issue_is_canonical_and_same_principal_restart_replays_without_admission
        with_journal do |journal|
          first = issue(journal) { |events, commit, generation| assert_empty events; refute_nil commit; assert_equal 0, generation }
          refute first.fetch(:replayed)
          event = journal.prompt_intent("public-prompt", commit: first.fetch(:data).fetch("journal_commit"))
          assert_equal "original", event.dig("payload", "issued_by", "started_at")
          assert_equal binding, event.dig("payload", "binding")
          refute_includes JSON.generate(journal.read_events("assignment")), "private prompt"
          replay = issue(journal, binding, peer("new process")) { flunk "retry must not obtain dispatch admission" }
          assert replay.fetch(:replayed)
          assert_equal first.fetch(:data), replay.fetch(:data)
          assert_equal 1, journal.read_events("assignment").count { |entry| entry["type"] == "prompt_issued" }
        end
      end

      def test_changed_text_attempt_scope_or_stable_principal_conflicts_before_finalization
        with_journal do |journal|
          issue(journal)
          changes = [{"text_sha256" => "c" * 64}, {"attempt_id" => "other"}, {"mapping_id" => "other"},
            {"caller" => binding.fetch("caller").merge("role" => "launcher")},
            {"caller" => binding.fetch("caller").merge("uid" => 11002)},
            {"caller" => binding.fetch("caller").merge("groups" => [11001, 11002])}]
          changes.each do |change|
            value = binding.merge(change)
            identity = peer.merge(value.fetch("caller").slice("uid", "gid", "groups"))
            assert_raises(AttemptErrors::Conflict) { issue(journal, value, identity) { flunk "changed ID admitted" } }
          end
          assert_equal 1, journal.read_events("assignment").count { |entry| entry["type"] == "prompt_issued" }
          assert_raises(AttemptErrors::Conflict) do
            journal.mutate(assignment_id: "assignment", attempt_id: "attempt", mutation_id: "public-prompt",
              operation: "fixture", parameters_digest: "a" * 64, expected_generation: 1) { flunk "external ID stolen" }
          end
        end
      end

      def test_concurrent_changed_input_has_one_canonical_issue_and_one_dispatch_permit
        with_journal do |journal|
          gate, outcomes = Queue.new, Queue.new
          threads = [binding, binding.merge("text_sha256" => "c" * 64, "attempt_id" => "other")].map do |value|
            Thread.new do
              gate.pop
              outcomes << issue(journal, value)
            rescue AttemptErrors::Conflict => error
              outcomes << error
            end
          end
          2.times { gate << true }
          threads.each(&:join)
          results = 2.times.map { outcomes.pop }
          assert_equal 1, results.count { |result| result.is_a?(Hash) && !result.fetch(:replayed) }
          assert_equal 1, results.count { |result| result.is_a?(AttemptErrors::Conflict) }
          assert_equal 1, journal.read_events("assignment").count { |entry| entry["type"] == "prompt_issued" }
        end
      end

      def origin
        {"terminal_id" => "term_ab", "runtime_incarnation" => "12345678-1234-1234-1234-123456789abc",
          "child" => peer("linux:12345678-1234-1234-1234-123456789abc:42")}
      end

      def finalize(journal, outcome: "submitted", evidence: nil, selector: nil, &block)
        event = journal.prompt_intent("public-prompt")
        evidence ||= {"outcome" => outcome, "origin" => origin}.tap { |value| value["submission"] = "submitted" if outcome == "submitted" }
        journal.finalize_prompt(mutation_id: "public-prompt", intent_event_id: selector || event.fetch("digest"),
          binding_digest: event.dig("payload", "binding_digest"), evidence: evidence,
          &(block || ->(*) { {"binding_digest" => "b" * 64, "origin" => origin} }))
      end

      def test_authenticated_completion_accepts_issue_after_generation_advance_and_replay_is_immutable
        with_journal do |journal|
          issue(journal)
          journal.mutate(assignment_id: "assignment", attempt_id: "attempt", mutation_id: "later",
            operation: "fixture", parameters_digest: "a" * 64, expected_generation: 1) { {data: {}} }
          reply = finalize(journal, outcome: "uncertain") do |events, commit, generation|
            assert_equal 2, generation
            assert_equal journal.ref_value, commit
            assert events.any? { |event| event["type"] == "prompt_issued" }
            {"binding_digest" => "b" * 64, "origin" => origin}
          end
          refute reply.fetch(:replayed)
          assert_equal "uncertain", reply.dig(:data, "outcome")
          assert_equal 3, reply.dig(:data, "generation")
          later = finalize(journal) { flunk "late observation cannot overwrite immutable reply" }
          assert later.fetch(:replayed)
          assert_equal reply.fetch(:data), later.fetch(:data)
          assert_equal 1, journal.read_events("assignment").count { |event| event["type"] == "prompt_outcome" }
        end
      end

      def test_completion_refuses_changed_issue_original_scope_guard_and_malformed_evidence
        with_journal do |journal|
          issue(journal)
          assert_raises(AttemptErrors::EvidenceUnavailable) { finalize(journal, selector: "a" * 64) { flunk "changed issue admitted" } }
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            finalize(journal) { {"binding_digest" => "c" * 64, "origin" => origin} }
          end
          [nil, {"outcome" => "submitted", "origin" => origin},
            {"outcome" => "submitted", "origin" => origin, "submission" => "submitted", "text" => "secret"},
            {"outcome" => "not_issued", "origin" => origin, "code" => "guard_mismatch", "phase" => "issued_or_unknown"},
            {"outcome" => "uncertain", "origin" => nil}].each do |evidence|
            next if evidence.nil?
            assert_raises(AttemptErrors::EvidenceUnavailable) { finalize(journal, evidence: evidence) }
          end
          %w[pid parent_pid uid gid groups].each do |field|
            received = origin
            received["child"][field] = field == "groups" ? received["child"][field].map(&:to_f) : received["child"][field].to_f
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              finalize(journal, evidence: {"outcome" => "submitted", "origin" => received, "submission" => "submitted"})
            end
          end
          assert_nil journal.mutation_result("public-prompt")
          assert_equal 2, journal.read_events("assignment").length
        end
      end

      def test_fixed_completion_mode_cannot_authorize_unrelated_operation_or_missing_issue
        with_journal do |journal|
          selector = {"binding_digest" => "b" * 64, "intent_event_id" => "c" * 64}
          assert_raises(ArgumentError) do
            journal.mutate(assignment_id: "assignment", attempt_id: "attempt", mutation_id: "public-prompt", operation: "fixture",
              parameters_digest: "b" * 64, expected_generation: nil, generation_mode: :prompt_completion, prompt_completion: selector) { flunk "bypass" }
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            journal.mutate(assignment_id: "assignment", attempt_id: "attempt", mutation_id: "public-prompt", operation: "prompt_attempt",
              parameters_digest: "b" * 64, expected_generation: nil, generation_mode: :prompt_completion, prompt_completion: selector) { flunk "missing issue" }
          end
        end
      end

      def test_namespace_reads_pinned_snapshot_then_revalidates_competing_issue_after_lost_cas
        with_journal do |journal|
          seed = journal.mutate(assignment_id: "assignment", attempt_id: "attempt", mutation_id: "seed",
            operation: "fixture", parameters_digest: "a" * 64, expected_generation: 0) { {data: {}} }
          old = seed.fetch("journal_commit")
          competing = issue(journal, binding.merge("expected_generation" => 1, "text_sha256" => "c" * 64)).fetch(:data).fetch("journal_commit")
          git(journal.repo_root, "update-ref", journal.ref, old, competing)
          synchronize = journal.method(:sync_checkout)
          advanced = false
          journal.define_singleton_method(:sync_checkout) do |commit|
            synchronize.call(commit)
            unless advanced
              advanced = true
              _out, error, status = Open3.capture3("git", "update-ref", ref, competing, old, chdir: repo_root, stdin_data: "")
              raise error unless status.success?
            end
          end
          callbacks = 0
          assert_raises(AttemptErrors::Conflict) do
            issue(journal, binding.merge("expected_generation" => 1)) { callbacks += 1 }
          end
          assert_equal 1, callbacks, "first admission reads selected old snapshot; losing CAS never grants send"
          assert_equal competing, journal.ref_value
          assert_equal "c" * 64, journal.prompt_intent("public-prompt").dig("payload", "binding", "text_sha256")
          assert_equal 1, journal.read_events("assignment").count { |event| event["type"] == "prompt_issued" }
        end
      end

      def test_public_existing_mutation_and_reserved_internal_namespace_cannot_be_reused
        with_journal do |journal|
          journal.mutate(assignment_id: "assignment", attempt_id: "attempt", mutation_id: "public-prompt",
            operation: "fixture", parameters_digest: "a" * 64, expected_generation: 0) { {data: {}} }
          assert_raises(AttemptErrors::Conflict) { issue(journal) { flunk "previous public ID admitted" } }
          assert_raises(ArgumentError) { issue(journal, binding.merge("mutation_id" => "prompt-issue.fake")) }
          assert_nil journal.prompt_intent("public-prompt")
          ["prompt-issue.fake", "prompt-issue." + "b" * 64].each do |id|
            assert_raises(ArgumentError) do
              journal.mutate(assignment_id: "assignment", attempt_id: "attempt", mutation_id: id,
                operation: "fixture", parameters_digest: "a" * 64, expected_generation: 1) { flunk "internal namespace stolen" }
            end
          end
        end
      end
    end
  end
end
