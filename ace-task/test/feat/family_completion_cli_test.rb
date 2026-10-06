# frozen_string_literal: true

require "test_helper"
require "open3"

class FamilyCompletionCliTest < AceTaskTestCase
  def setup
    @project = Dir.mktmpdir("task-family-cli")
    @root = File.join(@project, ".ace-tasks")
    FileUtils.mkdir_p(File.join(@project, ".git"))
    FileUtils.mkdir_p(File.join(@project, ".ace", "task"))
    File.write(File.join(@project, ".ace", "task", "config.yml"),
      {"task" => {"root_dir" => @root}}.to_yaml)
    @manager = Ace::Task::Organisms::TaskManager.new(root_dir: @root)
    @parent = @manager.create("CLI parent", status: "in-progress")
    @child = @manager.create_subtask(@parent.id, "CLI child")
    @bin = File.expand_path("../../../bin/ace-task", __dir__)
  end

  def teardown
    FileUtils.rm_rf(@project)
  end

  def test_cli_blocked_sibling_keeps_family_active_and_doctor_preserves_evidence
    sibling = @manager.create_subtask(@parent.id, "Blocked sibling", status: "blocked")
    evidence = File.join(sibling.path, "evidence.txt")
    File.write(evidence, "still required")
    before = File.read(sibling.file_path)

    output, status = cli("update", @child.id, "--set", "status=done")
    assert status.success?, output
    assert_includes output, @child.id
    output, status = cli("show", @parent.id)
    assert status.success?, output
    assert_includes output, "in-progress"
    output, status = cli("show", sibling.id)
    assert status.success?, output
    assert_includes output, "blocked"
    output, status = cli("list")
    assert status.success?, output
    assert_includes output, @parent.id
    cli("doctor", "--auto-fix", "--check", "scope")
    assert_equal before, File.read(sibling.file_path)
    assert_equal "still required", File.read(evidence)
    assert_equal @parent.path, @manager.show(@parent.id).path

    output, status = cli("update", @parent.id, "--set", "status=done", "--move-to", "archive")
    assert status.success?, output
    assert_includes output, "not archived"
    assert_equal "in-progress", @manager.show(@parent.id).status
  end

  def test_cli_complete_family_returns_child_and_show_list_resolve_archive
    @manager.create_subtask(@parent.id, "Skipped sibling", status: "skipped")
    @manager.create_subtask(@parent.id, "Cancelled sibling", status: "cancelled")
    output, status = cli("update", @child.id, "--set", "status=done")
    assert status.success?, output
    assert_includes output, @child.id
    refute_includes output, "not found"
    output, status = cli("show", @child.id)
    assert status.success?, output
    assert_includes output, "done"
    output, status = cli("list", "--in", "archive")
    assert status.success?, output
    assert_includes output, @parent.id
    assert_equal "_archive", @manager.show(@child.id).special_folder
    assert File.exist?(@manager.show(@child.id).file_path)
    output, status = cli("doctor", "--check", "scope")
    assert status.success?, output
  end

  private

  def cli(*args)
    output, error, status = Open3.capture3({"PROJECT_ROOT_PATH" => @project}, @bin, *args, chdir: @project)
    [output + error, status]
  end
end
