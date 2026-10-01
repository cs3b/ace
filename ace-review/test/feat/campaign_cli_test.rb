# frozen_string_literal: true
require "test_helper"
require "open3"
require "rbconfig"
require_relative "../campaign_fixtures"
require_relative "../campaign_assignment_fixtures"

# Fresh processes and real Git exercise the public entrypoint and restart contract.
class CampaignCLITest < AceReviewTest
  include CampaignFixtures
  include CampaignAssignmentFixtures

  def git(*args)
    out, err, status = Open3.capture3("git", *args, chdir: @test_dir)
    assert status.success?, err
    out.strip
  end

  def cli(*args)
    bin = File.join(REPO_ROOT, "bin/ace-review")
    out, err, status = Open3.capture3(RbConfig.ruby, bin, *args, chdir: @test_dir)
    [JSON.parse(out), err, status]
  end

  def test_public_json_dry_run_restart_replay_head_drift_and_acceptance
    git("init", "-b", "main")
    git("config", "user.name", "test")
    git("config", "user.email", "test@example.com")
    File.write(".gitignore", ".ace-local/\nsubject.json\ncontract.md\nround.json\n")
    File.write("candidate.rb", "puts :candidate\n")
    git("add", ".gitignore", "candidate.rb")
    git("commit", "-m", "candidate")
    @head = @base = git("rev-parse", "HEAD")
    File.write("subject.json", JSON.generate(campaign_subject))
    File.write("contract.md", "Frozen requirements")
    args = %w[campaign start --subject subject.json --contract contract.md --profile delivery]
    preview, err, status = cli(*args, "--dry-run")
    assert status.success?, err
    assert preview["dry_run"]
    refute File.exist?(".ace-local/review/campaigns")
    campaign, err, status = cli(*args)
    assert status.success?, err
    id = campaign["campaign_id"]
    fabricated = round_input("invalid-base")
    fabricated["base"] = "f" * 40
    fabricated["scope_identity"]["full"]["subjects"] = ["files:candidate.rb"]
    File.write("round.json", JSON.generate(fabricated))
    rejected, _, status = cli("campaign", "record-round", id, "--input", "round.json")
    refute status.success?
    assert_includes rejected["error"], "not an available Git commit"
    unchanged, err, status = cli("campaign", "status", id)
    assert status.success?, err
    assert_equal 0, unchanged["counters"]["recording_attempts"]
    3.times do |n|
      input = round_input(n)
      File.write("round.json", JSON.generate(input))
      pinned, err, status = cli("campaign", "record-round", id, "--input", "round.json")
      assert status.success?, err
      refute pinned["recorded_complete"]
      input["attempt_id"] = "completed-#{n}"
      make_campaign_session(campaign, input)
      add_campaign_approval(campaign, input) if n == 2
      File.write("round.json", JSON.generate(input))
      recorded, err, status = cli("campaign", "record-round", id, "--input", "round.json", "--quiet")
      assert status.success?, err
      assert_equal n + 1, recorded["completed_rounds"]
    end
    result, err, status = cli("campaign", "finish", id, "--format", "json")
    assert status.success?, err
    assert result["accepted"]
    replay, err, status = cli("campaign", "record-round", id, "--input", "round.json")
    assert status.success?, err
    assert replay["replayed"]
    assert_equal 3, replay["completed_rounds"]
    File.write("candidate.rb", "puts :changed\n")
    git("add", "candidate.rb")
    git("commit", "-m", "new head")
    stale, err, status = cli("campaign", "status", id)
    assert status.success?, err
    assert_equal 3, stale["clean_streak"]
    refute stale["evidence"]["valid"]
    rejected, _, status = cli("campaign", "finish", id)
    refute status.success?
    refute rejected["accepted"]
    same, err, status = cli(*args)
    assert status.success?, err
    assert_equal id, same["campaign_id"]
  end
end
