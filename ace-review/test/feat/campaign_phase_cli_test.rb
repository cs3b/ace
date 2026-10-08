# frozen_string_literal: true
require "test_helper"
require "open3"
require "rbconfig"

# Small public process flow: real committed candidate, no model or assignment engine.
class CampaignPhaseCLITest < AceReviewTest
  def git(*args)
    out, err, status = Open3.capture3("git", *args, chdir: @test_dir)
    assert status.success?, err
    out.strip
  end

  def cli(*args)
    output, error, status = Open3.capture3(RbConfig.ruby, File.join(REPO_ROOT, "bin/ace-review"), *args, chdir: @test_dir)
    [JSON.parse(output), error, status]
  end

  def test_execution_failure_phase_authorization_dry_run_and_restart_through_public_processes
    git("init", "-b", "main")
    git("config", "user.name", "test")
    git("config", "user.email", "test@example.com")
    File.write(".gitignore", ".ace-local/\n")
    File.write("candidate.rb", "puts :base\n")
    git("add", ".gitignore", "candidate.rb")
    git("commit", "-m", "base")
    base = git("rev-parse", "HEAD")
    File.write("candidate.rb", "puts :candidate\n")
    git("commit", "-am", "candidate")
    head = git("rev-parse", "HEAD")
    FileUtils.mkdir_p(".ace-local/input")
    subject = {"repository" => "local:#{File.realpath(@test_dir)}", "local_candidate_id" => "phase-candidate"}
    File.write(".ace-local/input/subject.json", JSON.generate(subject))
    File.write(".ace-local/input/contract.md", "Frozen candidate requirements")
    start = %w[campaign start --subject .ace-local/input/subject.json --contract .ace-local/input/contract.md]
    campaign, err, status = cli(*start)
    assert status.success?, err
    id = campaign.fetch("campaign_id")
    manager = Ace::Review::Organisms::CampaignManager.new(repo_root: @test_dir)
    manager.record_round(id, {"attempt_id" => "pin", "round_id" => "round", "head" => head, "base" => base,
      "required_scopes" => ["full"], "scope_identity" => {"full" => {"preset" => "code-valid", "subjects" => ["diff:#{base}..#{head}"]}},
      "sessions" => [], "dispositions" => []})
    entry = manager.reserve_execution(id, round_id: "round", scope: "full", provider: "fixture:selected")
    manager.complete_execution(id, execution_id: entry.fetch("id"), status: "failed", failure: "authentication")
    failed, err, status = cli("campaign", "status", id)
    assert status.success?, err
    assert_equal "execution_failed", failed.fetch("outcome")
    assert_match(/authentication/, failed.fetch("execution_failure"))
    _, _, status = cli("campaign", "finish", id)
    refute status.success?
    path = manager.store.path(id)
    bytes = File.binread(path)
    resume = ["campaign", "resume", id, "--phase", "authorized", "--reason", "Select explicitly repaired authorization",
      "--route", "review", "--additional-rounds", "1"]
    preview, err, status = cli(*resume, "--dry-run")
    assert status.success?, err
    assert_equal 1, preview.fetch("remaining_rounds")
    assert_equal bytes, File.binread(path)
    resumed, err, status = cli(*resume)
    assert status.success?, err
    replayed, err, status = cli(*resume)
    assert status.success?, err
    assert_equal resumed.fetch("result_identity"), replayed.fetch("result_identity")
    restarted, err, status = cli(*start)
    assert status.success?, err
    assert_equal id, restarted.fetch("campaign_id")
    assert_equal 2, restarted.fetch("phases").size
    assert_equal 1, restarted.fetch("execution_attempts").size
    assert_equal 0, restarted.fetch("completed_rounds")
    refute restarted.fetch("accepted")
  end
end
