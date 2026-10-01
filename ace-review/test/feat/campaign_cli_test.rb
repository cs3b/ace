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
    campaign_bytes = File.binread(".ace-local/review/campaigns/#{id}.json")
    reused_preview, err, status = cli(*args, "--dry-run")
    assert status.success?, err
    assert reused_preview["dry_run"]
    assert_equal id, reused_preview["campaign_id"]
    assert_equal campaign_bytes, File.binread(".ace-local/review/campaigns/#{id}.json")
    %w[false null].each do |invalid_policy|
      File.write(".ace-local/policy.json", invalid_policy)
      rejected_policy, _, status = cli(*args, "--policy", ".ace-local/policy.json")
      refute status.success?
      assert_includes rejected_policy["error"], "must be an object"
    end
    File.write(".ace-local/check-control.json", JSON.generate("name" => "tests", "head" => @head,
      "status" => "succeeded", "exit_code" => 0))
    control_check = accepted_check_reference(".ace-local/check-control.json")
    fabricated = round_input("invalid-base")
    fabricated["base"] = "f" * 40
    fabricated["scope_identity"]["full"]["subjects"] = ["files:candidate.rb"]
    File.write("round.json", JSON.generate(fabricated))
    rejected, _, status = cli("campaign", "record-round", id, "--input", "round.json")
    refute status.success?
    assert_includes rejected["error"], "full scope requires"
    fabricated["attempt_id"] = "unknown-base"
    fabricated["scope_identity"]["full"]["subjects"] = ["diff:#{fabricated['base']}..#{@head}"]
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
      if n == 0
        forged = Marshal.load(Marshal.dump(input))
        [nil, control_check].each do |invalid_authority|
          forged["sessions"].first["receipt"] = invalid_authority
          File.write("round.json", JSON.generate(forged))
          rejected_session, _, status = cli("campaign", "record-round", id, "--input", "round.json")
          refute status.success?
          refute rejected_session["accepted"]
        end
        unchanged, err, status = cli("campaign", "status", id)
        assert status.success?, err
        assert_equal 0, unchanged["completed_rounds"]
      end
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
    @head = @base = git("rev-parse", "HEAD")
    current = round_input(3)
    File.write("round.json", JSON.generate(current))
    _, err, status = cli("campaign", "record-round", id, "--input", "round.json")
    assert status.success?, err
    drifted, err, status = cli("campaign", "status", id)
    assert status.success?, err
    assert_equal @base, drifted["evidence"]["current_base"]
    refute_equal @base, drifted["evidence"]["source_base"]
    assert_equal 3, drifted["completed_rounds"]
    current["attempt_id"] = "complete-h2"
    make_campaign_session(campaign, current)
    add_campaign_approval(campaign, current)
    File.write("round.json", JSON.generate(current))
    recorded, err, status = cli("campaign", "record-round", id, "--input", "round.json")
    assert status.success?, err
    assert_equal 4, recorded["completed_rounds"]
    assert_equal 4, recorded["clean_streak"]
    assert recorded["accepted"], recorded["reasons"].inspect
    same, err, status = cli(*args)
    assert status.success?, err
    assert_equal id, same["campaign_id"]
  end
  def test_collection_excludes_untracked_tool_artifacts_but_detects_candidate_changes_without_gitignore
    git("init", "-b", "main")
    git("config", "user.name", "test")
    git("config", "user.email", "test@example.com")
    FileUtils.mkdir_p(".ace-local")
    File.write(".ace-local/tracked-source.rb", "puts :tracked\n")
    File.write("candidate.rb", "puts :candidate\n")
    git("add", "candidate.rb", ".ace-local/tracked-source.rb")
    git("commit", "-m", "candidate")
    @head = @base = git("rev-parse", "HEAD")
    manager = Ace::Review::Organisms::CampaignManager.new(repo_root: @test_dir)
    campaign = manager.start(subject: campaign_subject, contract: "Frozen requirements", policy: campaign_policy)
    manager.record_round(campaign["campaign_id"], round_input(1))
    FileUtils.mkdir_p(".ace-local/campaign-input")
    File.write(".ace-local/campaign-input/round.json", JSON.generate(round_input(1)))
    args = {round_id: "round-1", scope: "full", preset: "code-valid", head: @head, base: @base,
      subjects: ["diff:#{@base}..#{@head}"]}
    binding = manager.session_binding(campaign["campaign_id"], **args)
    assert_equal campaign["campaign_id"], binding["campaign_id"]
    File.write("new-source.rb", "puts :untracked\n")
    assert_raises(ArgumentError) { manager.session_binding(campaign["campaign_id"], **args) }
    File.delete("new-source.rb")
    File.write("candidate.rb", "puts :changed\n")
    assert_raises(ArgumentError) { manager.session_binding(campaign["campaign_id"], **args) }
    File.write("candidate.rb", "puts :candidate\n")
    File.write(".ace-local/tracked-source.rb", "puts :changed\n")
    assert_raises(ArgumentError) { manager.session_binding(campaign["campaign_id"], **args) }
    git("add", ".ace-local/tracked-source.rb")
    assert_raises(ArgumentError) { manager.session_binding(campaign["campaign_id"], **args) }
  end

end
