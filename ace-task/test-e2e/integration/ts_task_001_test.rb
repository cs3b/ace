# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"

class TSTASK001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-task")
  end

  def run_cmd(*args, chdir: @root)
    Open3.capture3(@exe, *args, chdir: chdir)
  end

  def extract_ref(dir)
    task_file = Dir.glob(File.join(dir, ".ace-tasks", "**", "*.s.md")).first
    refute_nil task_file
    File.read(task_file)[/^id:\s*(.+)$/, 1]
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    assert_match(/ace-task/, stdout + stderr)
    assert_match(/create|update|doctor/, stdout + stderr)
  end

  def test_create_show_update_and_doctor_lifecycle
    Dir.mktmpdir("ace-task-e2e-") do |dir|
      stdout, stderr, status = run_cmd("create", "Integration smoke task", chdir: dir)
      assert status.success?, stderr

      ref = extract_ref(dir)

      stdout, stderr, status = run_cmd("list", "--status", "pending", chdir: dir)
      assert status.success?, stderr
      assert_includes stdout, ref

      stdout, stderr, status = run_cmd("show", ref, chdir: dir)
      assert status.success?, stderr
      assert_includes stdout, "Integration smoke task"

      stdout, stderr, status = run_cmd("update", ref, "--set", "status=done", "--move-to", "archive", chdir: dir)
      assert status.success?, stderr
      refute_empty Dir.glob(File.join(dir, ".ace-tasks", "_archive", "**", "*.s.md"))

      stdout, stderr, status = run_cmd("doctor", chdir: dir)
      assert status.success? || status.exitstatus <= 2, stderr
    end
  end
end
