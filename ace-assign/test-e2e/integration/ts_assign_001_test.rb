# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"
require "json"

class TSASSIGN001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-assign")
  end

  def run_cmd(*args, chdir: @root)
    Open3.capture3(@exe, *args, chdir: chdir)
  end

  def assignment_id(chdir)
    stdout, stderr, status = run_cmd("list", "--format", "json", chdir: chdir)
    assert status.success?, stderr
    JSON.parse(stdout).first.fetch("id")
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    output = stdout + stderr
    assert_match(/ace-assign/, output)
    assert_match(/create|status|finish|add/, output)
  end

  def test_create_status_and_finish_workflow
    Dir.mktmpdir("ace-assign-e2e-") do |dir|
      File.write(File.join(dir, "job.yaml"), <<~YAML)
        name: integration-smoke
        description: Deterministic integration smoke
        steps:
          - name: first-step
            instructions: First step
          - name: second-step
            instructions: Second step
      YAML
      File.write(File.join(dir, "report.md"), "Finished first step\n")

      stdout, stderr, status = run_cmd("create", "--yaml", "job.yaml", chdir: dir)
      assert status.success?, stderr
      assert_match(/assignment|first-step/i, stdout)

      id = assignment_id(dir)

      stdout, stderr, status = run_cmd("status", "--assignment", id, chdir: dir)
      assert status.success?, stderr
      assert_includes stdout, "first-step"

      stdout, stderr, status = run_cmd("finish", "--assignment", id, "--message", "report.md", chdir: dir)
      assert status.success?, stderr

      stdout, stderr, status = run_cmd("status", "--assignment", id, chdir: dir)
      assert status.success?, stderr
      assert_includes stdout, "second-step"
    end
  end
end
