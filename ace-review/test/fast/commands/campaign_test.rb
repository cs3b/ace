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
end
