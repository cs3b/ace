# frozen_string_literal: true

require_relative "../test_helper"
require "ace/git/molecules/github_issue_sync"

class GithubIssueSyncTest < AceGitTestCase
  def test_sync_task_creates_sticky_comment_and_label
    commands = []
    executor = lambda do |subcommand, args, **_opts|
      commands << [subcommand, args]

      if subcommand == "issue" && args[0..2] == ["view", "276", "--json"]
        return {
          success: true,
          stdout: {"state" => "OPEN", "comments" => [], "labels" => []}.to_json,
          stderr: "",
          exit_code: 0
        }
      end

      {success: true, stdout: "", stderr: "", exit_code: 0}
    end

    Ace::Git::Molecules::GhCliExecutor.stub :execute, executor do
      stub_git_identity do
        result = Ace::Git::Molecules::GithubIssueSync.sync_task(
          task_id: "8r4.t.ilo.2",
          task_title: "Expand ace-git with reusable GitHub issue sync primitives",
          task_status: "in-progress",
          task_path: "#{Dir.pwd}/.ace-tasks/8r4.t.ilo/8r4.t.ilo.s.md",
          issue_ids: [276],
          reason: "manual-sync",
          previous: nil
        )

        assert result[:success]
      end
    end

    assert commands.any? { |cmd, args| cmd == "issue" && args[0] == "comment" && args[1] == "276" }
    assert commands.any? { |cmd, args| cmd == "issue" && args[0] == "edit" && args[1] == "276" }
  end

  def test_sync_task_updates_existing_comment_and_reopens_closed_issue
    commands = []
    existing_body = <<~BODY
      <!-- ace-task:tracked -->
      Tracked in ace-task: [8r4.t.ilo.1](https://github.com/cs3b/ace/blob/main/.ace-tasks/old.s.md)
    BODY

    executor = lambda do |subcommand, args, **_opts|
      commands << [subcommand, args]

      if subcommand == "issue" && args[0..2] == ["view", "276", "--json"]
        return {
          success: true,
          stdout: {
            "state" => "CLOSED",
            "comments" => [{
              "id" => "IC_kwDOPzGJW876eMHw",
              "url" => "https://github.com/cs3b/ace/issues/276#issuecomment-12345",
              "body" => existing_body
            }],
            "labels" => [{"name" => "ace:tracked"}]
          }.to_json,
          stderr: "",
          exit_code: 0
        }
      end

      {success: true, stdout: "", stderr: "", exit_code: 0}
    end

    Ace::Git::Molecules::GhCliExecutor.stub :execute, executor do
      stub_git_identity do
        result = Ace::Git::Molecules::GithubIssueSync.sync_task(
          task_id: "8r4.t.ilo.1",
          task_title: "Add linked issue metadata and auto-sync",
          task_status: "pending",
          task_path: "#{Dir.pwd}/.ace-tasks/new.s.md",
          issue_ids: [276],
          reason: "update",
          previous: nil
        )

        assert result[:success]
      end
    end

    assert commands.any? { |cmd, args| cmd == "api" && args[0].include?("/issues/comments/12345") }
    assert commands.any? { |cmd, args| cmd == "issue" && args[0] == "reopen" && args[1] == "276" }
  end

  def test_sync_task_closes_issue_for_terminal_status_with_single_line
    commands = []
    executor = lambda do |subcommand, args, **_opts|
      commands << [subcommand, args]

      if subcommand == "issue" && args[0..2] == ["view", "276", "--json"]
        return {
          success: true,
          stdout: {
            "state" => "OPEN",
            "comments" => [],
            "labels" => [{"name" => "ace:tracked"}]
          }.to_json,
          stderr: "",
          exit_code: 0
        }
      end

      {success: true, stdout: "", stderr: "", exit_code: 0}
    end

    Ace::Git::Molecules::GhCliExecutor.stub :execute, executor do
      stub_git_identity do
        Ace::Git::Molecules::GithubIssueSync.sync_task(
          task_id: "8r4.t.ilo.2",
          task_title: "Expand ace-git with reusable GitHub issue sync primitives",
          task_status: "done",
          task_path: "#{Dir.pwd}/.ace-tasks/new.s.md",
          issue_ids: [276],
          reason: "update",
          previous: nil
        )
      end
    end

    assert commands.any? { |cmd, args| cmd == "issue" && args[0] == "close" && args[1] == "276" }
  end

  def test_validate_link_rejects_issue_owned_by_another_task
    existing_body = <<~BODY
      <!-- ace-task:tracked -->
      Tracked in ace-task: [8r4.t.i68](https://github.com/cs3b/ace/blob/HEAD/.ace-tasks/8r4.t.i68.s.md)
    BODY

    executor = lambda do |subcommand, args, **_opts|
      if subcommand == "issue" && args[0..2] == ["view", "276", "--json"]
        return {
          success: true,
          stdout: {
            "state" => "OPEN",
            "comments" => [{"id" => "12345", "body" => existing_body}],
            "labels" => [{"name" => "ace:tracked"}]
          }.to_json,
          stderr: "",
          exit_code: 0
        }
      end

      {success: true, stdout: "", stderr: "", exit_code: 0}
    end

    Ace::Git::Molecules::GhCliExecutor.stub :execute, executor do
      err = assert_raises(Ace::Git::Molecules::GithubIssueSync::OwnershipConflict) do
        Ace::Git::Molecules::GithubIssueSync.validate_link!(issue_id: 276, task_id: "8r4.t.i68.1")
      end

      assert_match(/already owned by task 8r4\.t\.i68/, err.message)
    end
  end

  def test_sync_task_reconciles_removed_issue_without_readding_or_lifecycle_changes
    commands = []
    existing_body = <<~BODY
      <!-- ace-task:tracked -->
      Tracked in ace-task: [8r4.t.ilo.2](https://github.com/cs3b/ace/blob/main/.ace-tasks/old.s.md)
    BODY

    executor = lambda do |subcommand, args, **_opts|
      commands << [subcommand, args]

      if subcommand == "issue" && args[0..2] == ["view", "276", "--json"]
        return {
          success: true,
          stdout: {
            "state" => "CLOSED",
            "comments" => [{"id" => "12345", "body" => existing_body}],
            "labels" => [{"name" => "ace:tracked"}]
          }.to_json,
          stderr: "",
          exit_code: 0
        }
      end

      {success: true, stdout: "", stderr: "", exit_code: 0}
    end

    Ace::Git::Molecules::GhCliExecutor.stub :execute, executor do
      stub_git_identity do
        result = Ace::Git::Molecules::GithubIssueSync.sync_task(
          task_id: "8r4.t.ilo.2",
          task_title: "Expand ace-git with reusable GitHub issue sync primitives",
          task_status: "pending",
          task_path: "#{Dir.pwd}/.ace-tasks/new.s.md",
          issue_ids: [276],
          current_issue_ids: [],
          reason: "update",
          previous: {id: "8r4.t.ilo.2"}
        )

        assert result[:success]
      end
    end

    assert commands.any? do |cmd, args|
      cmd == "api" && args[0].include?("/issues/comments/12345") && args.include?("--method") && args.include?("DELETE")
    end
    assert commands.any? do |cmd, args|
      cmd == "issue" && args[0] == "edit" && args[1] == "276" && args.include?("--remove-label") && args.include?("ace:tracked")
    end
    refute commands.any? { |cmd, args| cmd == "issue" && args[0] == "reopen" && args[1] == "276" }
    refute commands.any? { |cmd, args| cmd == "issue" && args[0] == "close" && args[1] == "276" }
  end

  def test_sync_task_uses_branch_agnostic_head_blob_link
    commands = []
    executor = lambda do |subcommand, args, **_opts|
      commands << [subcommand, args]

      if subcommand == "issue" && args[0..2] == ["view", "276", "--json"]
        return {
          success: true,
          stdout: {"state" => "OPEN", "comments" => [], "labels" => []}.to_json,
          stderr: "",
          exit_code: 0
        }
      end

      {success: true, stdout: "", stderr: "", exit_code: 0}
    end

    Ace::Git::Molecules::GhCliExecutor.stub :execute, executor do
      stub_git_identity do
        Ace::Git::Molecules::GithubIssueSync.sync_task(
          task_id: "8r4.t.ilo.2",
          task_title: "Expand ace-git with reusable GitHub issue sync primitives",
          task_status: "in-progress",
          task_path: "#{Dir.pwd}/.ace-tasks/8r4.t.ilo/8r4.t.ilo.s.md",
          issue_ids: [276],
          reason: "manual-sync",
          previous: nil
        )
      end
    end

    comment_cmd = commands.find { |cmd, args| cmd == "issue" && args[0] == "comment" && args[1] == "276" }
    refute_nil comment_cmd
    body = comment_cmd[1][3]
    assert_match(%r{https://github\.com/cs3b/ace/blob/HEAD/\.ace-tasks/8r4\.t\.ilo/8r4\.t\.ilo\.s\.md}, body)
  end

  private

  def stub_git_identity
    original = Open3.method(:capture3)
    status_builder = lambda do |success|
      status = Object.new
      status.define_singleton_method(:success?) { success }
      status.define_singleton_method(:exitstatus) { success ? 0 : 1 }
      status
    end

    Open3.define_singleton_method(:capture3) do |*args|
      if args == ["git", "rev-parse", "--show-toplevel"]
        [Dir.pwd + "\n", "", status_builder.call(true)]
      elsif args == ["git", "remote", "get-url", "origin"]
        ["git@github.com:cs3b/ace.git\n", "", status_builder.call(true)]
      else
        original.call(*args)
      end
    end
    yield
  ensure
    Open3.define_singleton_method(:capture3, original)
  end
end
