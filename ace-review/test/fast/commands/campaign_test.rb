# frozen_string_literal: true
require "test_helper"
require_relative "../../campaign_fixtures"

class CampaignCommandTest < AceReviewTest
  include CampaignFixtures

  def setup
    super
    @head = "a" * 40
    @base = "b" * 40
  end

  def command(args)
    output, = capture_io { Ace::Review::CLI.start(args) }
    output
  end

  def test_help_dispatch_and_repeatable_review_options_remain_primary
    assert_includes command(%w[campaign --help]), "record-round"
    assert_includes command(%w[campaign start --help]), "--contract"
    args = Ace::Review::CLI.preprocess_array_options(%w[--subject files:a.rb,b.rb --subject staged
      --model model-one --model model-two --evidence-session first --evidence-session second])
    assert_includes args, "files:a.rb,b.rb\x1Fstaged"
    assert_includes args, "model-one,model-two"
    assert_includes args, "first\x1Fsecond"
  end

  def test_unknown_malformed_campaign_and_finish_are_parseable_failures
    output, = capture_io do
      assert_raises(Ace::Support::Cli::Error) { Ace::Review::CLI.start(%w[campaign status missing --format json]) }
    end
    refute JSON.parse(output)["accepted"]
    File.write("subject.json", "[]")
    File.write("contract.md", "requirements")
    output, = capture_io do
      assert_raises(Ace::Support::Cli::Error) do
        Ace::Review::CLI.start(%w[campaign start --subject subject.json --contract contract.md])
      end
    end
    assert_match(/object/, JSON.parse(output)["error"])
  end

  def test_collection_binding_requires_pinned_scope_and_actual_repository_identity
    campaign = start_campaign
    assert_raises(ArgumentError) do
      campaign_manager.session_binding(campaign["campaign_id"], round_id: "round-1", scope: "full",
        preset: "code-valid", head: @head, base: @base, subjects: ["diff:#{@base}..#{@head}"])
    end
    input = round_input(1)
    campaign_manager.record_round(campaign["campaign_id"], input)
    conflicting_diff = round_input(2)
    conflicting_diff["scope_identity"]["full"]["subjects"] = ["diff:#{@base}..#{'c' * 40}"]
    assert_raises(ArgumentError) { campaign_manager.record_round(campaign["campaign_id"], conflicting_diff) }
    binding = campaign_manager.session_binding(campaign["campaign_id"], round_id: "round-1", scope: "full",
      preset: "code-valid", head: @head, base: @base, subjects: ["diff:#{@base}..#{@head}"])
    assert_equal campaign["campaign_id"], binding["campaign_id"]
    assert_raises(ArgumentError) do
      campaign_manager.session_binding(campaign["campaign_id"], round_id: "round-1", scope: "full",
        preset: "code-valid", head: @head, base: @base, subjects: ["files:unrelated.md"])
    end
    assert_raises(ArgumentError) do
      campaign_manager.session_binding(campaign["campaign_id"], round_id: "round-1", scope: "full",
        preset: "wrong", head: @head, base: @base, subjects: ["diff:#{@base}..#{@head}"])
    end
  end
  def test_pr_delta_collection_requires_exact_pinned_reference
    manager = campaign_manager
    campaign = manager.start(subject: {"repository" => "https://github.com/owner/repo", "pr" => "owner/repo#42"},
      contract: "requirements", policy: campaign_policy(scopes: ["delta"]))
    input = round_input(1, scopes: ["delta"])
    input["scope_identity"]["delta"]["subjects"] = ["pr:owner/repo#42"]
    manager.record_round(campaign["campaign_id"], input)
    args = {round_id: "round-1", scope: "delta", preset: "code-valid", head: @head, base: @base,
      pr_url: "https://github.com/owner/repo/pull/42"}
    assert_raises(ArgumentError) do
      manager.session_binding(campaign["campaign_id"], **args, delta_reference_head: "c" * 40)
    end
    delta = round_input(2, scopes: ["delta"])
    delta["scope_identity"]["delta"] = {"preset" => "code-valid", "subjects" => ["pr:owner/repo#42"],
      "delta_reference_head" => "c" * 40}
    manager.record_round(campaign["campaign_id"], delta)
    args[:round_id] = "round-2"
    args[:diff_manifest] = full_pr_manifest(delta: "c" * 40)
    assert_raises(ArgumentError) { manager.session_binding(campaign["campaign_id"], **args) }
    assert_raises(ArgumentError) do
      manager.session_binding(campaign["campaign_id"], **args, delta_reference_head: "d" * 40)
    end
    bound = manager.session_binding(campaign["campaign_id"], **args, delta_reference_head: "c" * 40)
    assert_equal "c" * 40, bound["scope_identity"]["delta_reference_head"]
  end

  def test_full_pr_collection_rejects_filtered_or_unverified_inventory
    manager = campaign_manager
    campaign = manager.start(subject: {"repository" => "https://github.com/owner/repo", "pr" => "owner/repo#42"},
      contract: "requirements", policy: campaign_policy)
    input = round_input(1)
    input["scope_identity"]["full"]["subjects"] = ["pr:owner/repo#42"]
    invalid_delta = Marshal.load(Marshal.dump(input))
    invalid_delta["scope_identity"]["full"]["delta_reference_head"] = "c" * 40
    assert_raises(ArgumentError) { manager.record_round(campaign["campaign_id"], invalid_delta) }
    manager.record_round(campaign["campaign_id"], input)
    args = {round_id: "round-1", scope: "full", preset: "code-valid", head: @head, base: @base,
      pr_url: "https://github.com/owner/repo/pull/42"}
    [nil, full_pr_manifest.merge("excluded_files" => ["two.rb"]),
      full_pr_manifest.merge("exempt_files" => ["two.rb"]),
      full_pr_manifest.merge("selected_sha256" => "e" * 64),
      full_pr_manifest.merge("pr_file_inventory_verified" => false)].each do |manifest|
      assert_raises(ArgumentError) do
        manager.session_binding(campaign["campaign_id"], **args, diff_manifest: manifest)
      end
    end
    assert_raises(ArgumentError) do
      manager.session_binding(campaign["campaign_id"], **args, diff_manifest: full_pr_manifest(delta: "c" * 40))
    end
    binding = manager.session_binding(campaign["campaign_id"], **args, diff_manifest: full_pr_manifest)
    assert_equal "full", binding["scope"]
    assert_equal 0, manager.status(campaign["campaign_id"])["completed_rounds"]
  end

end
