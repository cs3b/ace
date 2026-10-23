# frozen_string_literal: true
require "test_helper"
require "ace/git/cli"
require "ace/test_support/cli_helpers"

class FormalApprovalCliTest < AceGitTestCase
  include Ace::TestSupport::CliHelpers

  def test_json_approve_and_read_only_approval_round_trip
    fake = Object.new
    calls = []
    receipt = Struct.new(:to_h).new({provider: :forgejo, server_name: "forge", pr_number: 25,
      head_sha: "a" * 40, reviewer: "reviewer", reviewer_id: 7, review_id: 99, state: :approved,
      effective: true, correlation: "r1", evidence_sha256: "b" * 64, idempotency: :created})
    fake.define_singleton_method(:approve) { |id, **options| calls << [:approve, id, options]; receipt }
    fake.define_singleton_method(:approval) { |id, **options| calls << [:approval, id, options]; receipt }
    Ace::Git::Organisms::PullRequestLifecycle.stub(:new, fake) do
      result = invoke_cli(Ace::Git::CLI, ["pr", "approve", "25", "--expected-head", "a" * 40,
        "--body-file", "review.md", "--correlation", "r1", "--server", "forge", "--format", "json"])
      assert_equal "approved", JSON.parse(result[:stdout]).fetch("state")
      assert_equal "review.md", calls.first.last.fetch(:body_file)
      result = invoke_cli(Ace::Git::CLI, ["pr", "approval", "25", "--expected-head", "a" * 40,
        "--review-id", "99", "--server", "forge", "--format", "json"])
      assert_equal 99, JSON.parse(result[:stdout]).fetch("review_id")
      assert_equal [:approval, "25", {expected_head: "a" * 40, review_id: 99}], calls.last
    end
  end

  def test_classified_unknown_is_json_error_and_never_success
    fake = Object.new
    fake.define_singleton_method(:approve) { |*args, **options| raise Ace::Git::ProviderUnknownOutcomeError, "reconcile r1" }
    Ace::Git::Organisms::PullRequestLifecycle.stub(:new, fake) do
      result = invoke_cli(Ace::Git::CLI, ["pr", "approve", "25", "--expected-head", "a" * 40,
        "--body-file", "review.md", "--correlation", "r1", "--format", "json"])
      parsed = JSON.parse(result[:stdout])
      assert_equal "unknown_outcome", parsed.fetch("error").fetch("category")
      refute parsed.key?("effective")
    end
  end

  def test_lifecycle_rejects_conflicting_repo_before_provider_access
    Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge("servers" => [
      {"name" => "forge", "provider" => "forgejo", "url" => "https://forge.example/owner/repo"}]))
    life = Ace::Git::Organisms::PullRequestLifecycle.new(server_name: "forge")
    assert_raises(Ace::Git::ProviderIdentityMismatchError, Ace::Git::AmbiguousRemoteError) do
      life.approval("https://forge.example/other/repo/pulls/25", expected_head: "a" * 40, review_id: 99)
    end
    assert_raises(ArgumentError) do
      life.approve("25", expected_head: "a" * 40, body_file: "/nonexistent/approval.md", correlation: "r1")
    end
  end
end
