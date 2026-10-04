# frozen_string_literal: true

require_relative "../../test_helper"

class ResumeCommandTest < AceAssignTestCase
  def test_public_resume_dry_run_preserves_history_and_actual_resume_preserves_writer_slot
    with_attempt_cli_env do |cache, repo|
      assignment = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache).create(
        name: "resume", source_config: "job.yml", task_id: "8wq.t.1w5", project_id: "ace")
      capture_io do
        Ace::Assign::CLI.start(["attempt", "start", "--assignment", assignment.id,
          "--step", "010", "--project", "ace"])
      end
      journal = Ace::Assign::Molecules::EvidenceJournal.new(repo_root: repo)
      ref = journal.ref_value
      head = git_in(repo, "rev-parse", "HEAD")
      output = capture_io do
        assert_equal 0, Ace::Assign::CLI.start(["resume", "--assignment", assignment.id, "--dry-run"])
      end.first
      snapshot = JSON.parse(output)
      assert_equal "reconcile-required", snapshot["decision"]
      assert_equal "unknown", snapshot["liveness"]
      assert_equal ref, journal.ref_value
      output = capture_io { Ace::Assign::CLI.start(["resume", "--assignment", assignment.id]) }.first
      assert_equal "uncertain", JSON.parse(output)["attempts"].first["state"]
      assert_equal head, git_in(repo, "rev-parse", "HEAD")
      assert_equal 1, journal.derived_attempts(assignment.id).length
    end
  end

  def test_assignment_is_required
    assert_raises(Ace::Support::Cli::Error) { Ace::Assign::CLI::Commands::Resume.new.call }
  end
end
