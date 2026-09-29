# frozen_string_literal: true

require "test_helper"
require "ace/git/worktree/commands/cleanup_command"

class CleanupCommandTest < Minitest::Test
  def setup
    super
    @cmd = Ace::Git::Worktree::Commands::CleanupCommand.new
  end

  def test_help_option_returns_zero
    result = @cmd.run(["--help"])
    assert_equal 0, result
  end

  def test_missing_target_returns_error
    result = @cmd.run([])
    assert_equal 1, result
  end

  def test_invalid_format_returns_error
    result = @cmd.run(["--target", "main", "--format", "invalid"])
    assert_equal 1, result
  end

  def test_successful_run_returns_zero
    mock_reporter = Minitest::Mock.new
    mock_reporter.expect :report, {
      success: true,
      target: {ref: "main", sha: "abc1234"},
      remote: {name: "origin", sha: "def5678"},
      refresh: {status: "offline"},
      worktrees: [],
      local_refs: [],
      remote_refs: [],
      actions: [],
      plan_digest: "digest"
    }

    Ace::Git::Worktree::Molecules::CleanupReporter.stub :new, mock_reporter do
      result = @cmd.run(["--target", "main", "--offline"])
      assert_equal 0, result
    end
    mock_reporter.verify
  end

  def test_failed_report_returns_error
    mock_reporter = Minitest::Mock.new
    mock_reporter.expect :report, {success: false, error: "Something went wrong"}

    Ace::Git::Worktree::Molecules::CleanupReporter.stub :new, mock_reporter do
      result = @cmd.run(["--target", "main"])
      assert_equal 1, result
    end
    mock_reporter.verify
  end

  def test_server_flags_forward_to_reporter_and_are_mutually_exclusive
    mock_reporter = Minitest::Mock.new
    mock_reporter.expect :report, {success: false, error: "x"}

    seen = nil
    Ace::Git::Worktree::Molecules::CleanupReporter.stub :new, lambda { |**kwargs|
      seen = kwargs
      mock_reporter
    } do
      @cmd.run(["--target", "main", "--offline", "--server", "forgejo-lab"])
      assert_equal "forgejo-lab", seen[:server_name]
      refute seen[:use_default]
    end

    output = capture_io do
      result = @cmd.run(["--target", "main", "--server", "a", "--default-server"])
      assert_equal 1, result
    end.first
    assert_match(/mutually exclusive/, output)
  end

  def test_apply_recomputes_report_and_rejects_stale_digest
    approved = {
      success: true,
      target: {ref: "main", sha: "abc"},
      remote: {name: "origin", sha: nil},
      server: {name: "forgejo-lab", provider: "forgejo", url: "https://forge.example.com/o/r"},
      refresh: {status: "offline"},
      worktrees: [], local_refs: [], remote_refs: [],
      actions: [],
      plan_digest: "approved-digest"
    }
    # The fresh recomputation drifted: provider proof changed the digest.
    drifted = approved.merge(plan_digest: "drifted-digest")

    reports = [approved, drifted]
    Ace::Git::Worktree::Molecules::CleanupReporter.stub :new, lambda { |**_kw|
      reporter = Object.new
      reporter.define_singleton_method(:report) { reports.shift || drifted }
      reporter
    } do
      output = capture_io do
        result = @cmd.run(["--target", "main", "--offline", "--apply", "--approved-digest", "approved-digest"])
        assert_equal 1, result
      end.first

      assert_match(/Digest mismatch/, output)
    end
  end

  def test_apply_recomputation_failure_refuses_apply
    good = {success: true, target: {ref: "main", sha: "abc"}, remote: {name: "origin", sha: nil},
            refresh: {status: "offline"}, worktrees: [], local_refs: [], remote_refs: [],
            actions: [], plan_digest: "d"}
    reports = [good] # initial display report succeeds; the fresh pre-apply recompute fails
    Ace::Git::Worktree::Molecules::CleanupReporter.stub :new, lambda { |**_kw|
      reporter = Object.new
      reporter.define_singleton_method(:report) { reports.shift || {success: false, error: "Cannot resolve target ref"} }
      reporter
    } do
      output = capture_io do
        result = @cmd.run(["--target", "main", "--offline", "--apply", "--approved-digest", "d"])
        assert_equal 1, result
      end.first

      assert_match(/Report recomputation failed before apply/, output)
    end
  end
end
