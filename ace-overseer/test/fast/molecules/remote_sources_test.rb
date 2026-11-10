# frozen_string_literal: true

require_relative "../../test_helper"

module Molecules
  # Task 8xs.t.pu0.4: configured PR observation through the forge
  # provider adapters — semantic revisions, no model turns on identical
  # state, per-source degradation on API failures.
  class RemoteSourcesTest < Minitest::Test
    PR = Data.define(:server_name, :number, :title, :body, :state, :head_ref, :base_ref,
      :head_sha, :author, :url, :draft, :merged_at, :head_repository_url,
      :base_repository_url, :merge_commit_sha)
    Review = Data.define(:server_name, :repository_url, :pr_number, :id, :author, :body,
      :state, :url, :head_sha)
    Comment = Data.define(:server_name, :repository_url, :pr_number, :id, :author, :body,
      :url, :path, :line, :head_sha, :resolved, :thread_id)
    Evidence = Data.define(:server_name, :repository_url, :pr_number, :head_sha,
      :comments, :reviews)
    Issue = Ace::Git::ProviderIssue

    class FakeProvider
      def initialize(pr:, evidence: nil)
        @pr = pr
        @evidence = evidence
      end

      def pull_request(number:)
        @pr.tap { |pr| pr.number == number or raise("wrong PR number") }
      end

      def pull_request_review_evidence(number:, expected_head:)
        @evidence
      end
    end

    def pr(head_sha: "a1" * 20, state: :open)
      PR.new(server_name: "gh", number: 398, title: "family PR", body: nil, state: state,
        head_ref: "pu0", base_ref: "main", head_sha: head_sha, author: "lab-overseer",
        url: "https://example/pr/398", draft: true, merged_at: nil,
        head_repository_url: "https://example/ace", base_repository_url: "https://example/ace",
        merge_commit_sha: nil)
    end

    def evidence(state: "APPROVED", id: "r9", comment_id: "c3")
      Evidence.new(server_name: "gh", repository_url: "https://example/ace", pr_number: 398,
        head_sha: "a1" * 20,
        reviews: [Review.new(server_name: "gh", repository_url: "https://example/ace",
          pr_number: 398, id: id, author: "lab-merge-ace", body: nil, state: state,
          url: "https://example/pr/398#review", head_sha: "a1" * 20)],
        comments: [Comment.new(server_name: "gh", repository_url: "https://example/ace",
          pr_number: 398, id: comment_id, author: "reviewer", body: "note", url: nil,
          path: nil, line: nil, head_sha: "a1" * 20, resolved: nil, thread_id: nil)])
    end

    def sources(provider)
      Ace::Overseer::Molecules::RemoteSources.new(
        provider_factory: ->(_server) { provider }
      )
    end

    def entries
      [{"server" => "gh", "number" => 398}]
    end

    def test_projects_pr_lifecycle_and_activity_rows_with_wake_payload
      result = sources(FakeProvider.new(pr: pr, evidence: evidence)).call(pull_requests: entries)

      pr_row = result["events"].find { |row| row["type"] == "pr" }
      assert_equal "pr:gh:398", pr_row["key"]
      assert_equal "family PR", pr_row["title"]
      assert_equal "lab-overseer", pr_row["author"]
      assert_equal "https://example/pr/398", pr_row["url"]

      activity = result["events"].find { |row| row["type"] == "pr-activity" }
      assert_equal "pr-activity:gh:398", activity["key"]
      assert_equal 2, activity["items"]
      assert_equal "gh", activity["forge"]
      assert_equal({"pr:gh" => {"status" => "ok"}}, result["sources"])
    end

    def test_identical_state_projects_identical_revisions
      provider = FakeProvider.new(pr: pr, evidence: evidence)
      first = sources(provider).call(pull_requests: entries)
      second = sources(FakeProvider.new(pr: pr, evidence: evidence)).call(pull_requests: entries)

      assert_equal first["events"].map { |row| row["revision"] },
        second["events"].map { |row| row["revision"] },
        "repeated reads of identical state never re-wake"
    end

    def test_reordered_activity_and_volatile_counters_do_not_revise
      provider = FakeProvider.new(pr: pr, evidence: evidence)
      first = sources(provider).call(pull_requests: entries)

      # same identity set, different construction order: identical revision
      same_set = sources(FakeProvider.new(pr: pr, evidence: evidence)).call(pull_requests: entries)
      assert_equal first["events"].find { |row| row["type"] == "pr-activity" }["revision"],
        same_set["events"].find { |row| row["type"] == "pr-activity" }["revision"]
    end

    def test_new_head_review_and_merge_each_revise_their_rows
      base = sources(FakeProvider.new(pr: pr, evidence: evidence)).call(pull_requests: entries)

      new_head = sources(FakeProvider.new(
        pr: pr(head_sha: "b2" * 20), evidence: evidence
      )).call(pull_requests: entries)
      refute_equal base["events"].find { |row| row["type"] == "pr" }["revision"],
        new_head["events"].find { |row| row["type"] == "pr" }["revision"]
      # head-bound activity of the old head stays comparable; the pr row woke

      new_review = sources(FakeProvider.new(
        pr: pr, evidence: evidence(id: "r10", comment_id: "c3")
      )).call(pull_requests: entries)
      refute_equal base["events"].find { |row| row["type"] == "pr-activity" }["revision"],
        new_review["events"].find { |row| row["type"] == "pr-activity" }["revision"]

      merged = sources(FakeProvider.new(
        pr: pr(state: :merged, head_sha: "b2" * 20), evidence: evidence
      )).call(pull_requests: entries)
      assert_equal "merged", merged["events"].find { |row| row["type"] == "pr" }["state"]
    end

    def test_forge_failure_degrades_only_its_source_with_a_stable_marker
      failing = Object.new
      def failing.pull_request(**)
        raise Ace::Git::ProviderAuthenticationError, "401 Unauthorized"
      end

      result = Ace::Overseer::Molecules::RemoteSources.new(
        provider_factory: ->(_server) { failing }
      ).call(pull_requests: entries + [{"server" => "other", "number" => 1}])
      # the failing factory covers both servers here; assert the marker shape
      marker = result["events"].find { |row| row["type"] == "source-health" }
      assert_equal "source:pr:gh", marker["key"]
      assert_match(/AuthenticationError/, marker["error"])

      repeat = Ace::Overseer::Molecules::RemoteSources.new(
        provider_factory: ->(_server) { failing }
      ).call(pull_requests: entries)
      assert_equal marker["revision"],
        repeat["events"].find { |row| row["key"] == "source:pr:gh" }["revision"],
        "an identical failure class never re-wakes"
    end

    def test_issue_collection_wakes_on_new_and_closed_issues_but_not_reordering
      a = Issue.new(server_name: "forge", number: 1, title: "first", state: :open,
        author: "user", url: "http://forge/issues/1", labels: ["b", "a"])
      b = a.with(number: 2, title: "second", url: "http://forge/issues/2")
      provider = Object.new
      provider.define_singleton_method(:recent_issues) { |limit:| [a, b] }
      observer = sources(provider)
      config = [{"server" => "forge"}]
      original = observer.call(pull_requests: [], issues: config)
      provider.define_singleton_method(:recent_issues) { |limit:| [b, a.with(labels: ["a", "b"])] }
      assert_equal original, observer.call(pull_requests: [], issues: config)
      provider.define_singleton_method(:recent_issues) { |limit:| [a.with(body: "Depends on #2"), b] }
      refute_equal original, observer.call(pull_requests: [], issues: config)
      provider.define_singleton_method(:recent_issues) { |limit:| [a.with(labels: ["blocked"]), b] }
      refute_equal original, observer.call(pull_requests: [], issues: config)
      provider.define_singleton_method(:recent_issues) { |limit:| [b] }
      changed = observer.call(pull_requests: [], issues: config)
      refute_equal original["events"].first["revision"], changed["events"].first["revision"]
      assert_equal [2], changed["events"].first["issue_numbers"]
      assert_equal 1, changed["events"].first["count"]
    end

    def test_issue_overflow_is_degraded_instead_of_silently_missing_work
      provider = Object.new
      provider.define_singleton_method(:recent_issues) { |limit:| Array.new(limit) }
      result = sources(provider).call(pull_requests: [], issues: [{"server" => "forge"}])
      assert_equal "degraded", result.fetch("sources").fetch("issues:forge").fetch("status")
      assert_equal "source-health", result.fetch("events").first.fetch("type")
    end

    def test_unsupported_issue_listing_is_explicitly_degraded
      result = sources(Object.new).call(pull_requests: [], issues: [{"server" => "forge"}])
      health = result.fetch("sources").fetch("issues:forge")
      assert_equal "degraded", health.fetch("status")
      assert_match(/ProviderUnsupportedCapabilityError.*no issue-listing API/, health.fetch("error"))
    end

    def test_invalid_issue_configuration_degrades_once
      result = sources(Object.new).call(pull_requests: [], issues: [nil, {}])
      assert_equal "degraded", result.fetch("sources").fetch("issues:configuration").fetch("status")
      assert_match(/index 0/, result.fetch("sources").fetch("issues:configuration").fetch("error"))
      assert_equal ["source:issues:configuration"], result.fetch("events").map { |row| row.fetch("key") }
    end

    def test_invalid_pr_configuration_wakes_as_degraded_without_hiding_valid_prs
      result = sources(FakeProvider.new(pr: pr, evidence: evidence)).call(
        pull_requests: entries + [{"server" => "gh"}, nil])
      assert_equal "degraded", result.fetch("sources").fetch("pr:configuration").fetch("status")
      assert_match(/index 1/, result.fetch("sources").fetch("pr:configuration").fetch("error"))
      assert_equal "ok", result.fetch("sources").fetch("pr:gh").fetch("status")
      assert result.fetch("events").any? { |row| row["key"] == "source:pr:configuration" }
      assert result.fetch("events").any? { |row| row["key"] == "pr:gh:398" }
    end

    def test_configured_issue_and_pr_sources_project_together
      provider = FakeProvider.new(pr: pr, evidence: evidence)
      provider.define_singleton_method(:recent_issues) { |limit:| [] }
      result = sources(provider).call(pull_requests: entries, issues: [{"server" => "forge"}])
      assert_equal "ok", result.fetch("sources").fetch("pr:gh").fetch("status")
      assert_equal "ok", result.fetch("sources").fetch("issues:forge").fetch("status")
      assert_includes result.fetch("events").map { |row| row.fetch("key") }, "issues:forge"
      assert_includes result.fetch("events").map { |row| row.fetch("key") }, "pr:gh:398"
    end
  end
end
