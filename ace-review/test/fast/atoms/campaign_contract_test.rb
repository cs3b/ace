# frozen_string_literal: true
require "test_helper"
require "ace/review/atoms/campaign_contract"
require "ace/review/atoms/campaign_projection"

class CampaignContractTest < AceReviewTest
  Contract = Ace::Review::Atoms::CampaignContract

  def test_normalized_subject_and_canonical_digest
    assert_equal({"repository" => "local:/repo", "local_candidate_id" => "candidate"},
      Contract.subject!({"repository" => "local:/repo", "local_candidate_id" => "candidate"}))
    assert_equal "owner/repo#42", Contract.subject!({"repository" => "https://example.com/owner/repo",
      "pr" => "owner/repo#042"})["pr"]
    canonical = Contract.subject!({"repository" => "https://github.com/owner/repo", "pr" => "owner/repo#42"})
    assert_equal canonical, Contract.subject!({"repository" => "https://github.com/Owner/Repo/", "pr" => "Owner/Repo#042"})
    assert_raises(ArgumentError) { Contract.subject!({"repository" => "https://github.com/other/repo/", "pr" => "owner/repo#42"}) }
    assert_equal Contract.digest({"b" => 1, "a" => 2}), Contract.digest({"a" => 2, "b" => 1})
  end

  def test_rejects_empty_mixed_unknown_and_unqualified_identities
    [{}, {"repository" => "", "local_candidate_id" => "x"},
      {"repository" => "r", "local_candidate_id" => "x", "pr" => "o/r#1"},
      {"repository" => "r", "pr" => "1"}, {"repository" => "r", "local_candidate_id" => "../x"},
      {"repository" => "r", "pr" => "o/r#0"}].each do |subject|
      assert_raises(ArgumentError) { Contract.subject!(subject) }
    end
    assert_raises(ArgumentError) { Contract.sha!("a" * 41, "head") }
  end

  def test_forge_neutral_subject_checks_repository_and_preserves_server_identity
    canonical = Contract.subject!({"repository" => "http://forge.internal:3000/git/Owner/Repo.git/",
      "pr" => "Owner/Repo#042"})
    assert_equal({"repository" => "http://forge.internal:3000/git/owner/repo", "pr" => "owner/repo#42"}, canonical)
    %w[https://forge.example/other/repo https://forge.example/owner/other
      https://forge.example/repo https://user:secret@forge.example/owner/repo
      https://forge.example/owner/repo?token=secret https://forge.example/owner/repo#fragment
      local:/owner/repo].each do |repository|
      assert_raises(Contract::Invalid) { Contract.subject!({"repository" => repository, "pr" => "owner/repo#42"}) }
    end
    other_server = Contract.subject!({"repository" => "https://other.example/owner/repo", "pr" => "owner/repo#42"})
    refute_equal Contract.digest(canonical), Contract.digest(other_server)
    other_port = Contract.subject!({"repository" => "http://forge.internal:3001/git/owner/repo", "pr" => "owner/repo#42"})
    refute_equal Contract.digest(canonical), Contract.digest(other_port)
  end

  def test_policy_requires_explicit_scopes_checks_revision_and_positive_counters
    policy = {"revision" => "delivery-v1", "minimum_rounds" => 3, "clean_rounds" => 2,
      "required_scopes" => ["full"], "required_checks" => ["tests"]}
    assert_equal policy, Contract.policy!(policy)
    assert_raises(ArgumentError) { Contract.policy!(policy.merge("clean_rounds" => 0)) }
    assert_raises(ArgumentError) { Contract.policy!(policy.merge("required_scopes" => [])) }
    assert_raises(ArgumentError) { Contract.policy!(policy.merge("force" => true)) }
  end
end
