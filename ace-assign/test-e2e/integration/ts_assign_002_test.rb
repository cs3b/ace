# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"
require "json"

class TSASSIGN002IntegrationTest < Minitest::Test
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

  def test_add_child_and_scoped_status
    Dir.mktmpdir("ace-assign-hierarchy-e2e-") do |dir|
      File.write(File.join(dir, "job.yaml"), <<~YAML)
        name: hierarchy-smoke
        description: Deterministic hierarchy smoke
        steps:
          - name: parent-job
            instructions: Parent step
          - name: final-step
            instructions: Final step
      YAML
      File.write(File.join(dir, "child.yaml"), <<~YAML)
        steps:
          - name: child-job
            instructions: Child step
      YAML

      stdout, stderr, status = run_cmd("create", "--yaml", "job.yaml", chdir: dir)
      assert status.success?, stderr

      id = assignment_id(dir)

      stdout, stderr, status = run_cmd("add", "--yaml", "child.yaml", "--assignment", id, "--after", "010", "--child", chdir: dir)
      assert status.success?, stderr

      stdout, stderr, status = run_cmd("status", "--assignment", id, chdir: dir)
      assert status.success?, stderr
      assert_includes stdout, "child-job"

      stdout, stderr, status = run_cmd("status", "--assignment", "#{id}@010", chdir: dir)
      assert status.success?, stderr
      assert_includes stdout, "child-job"
    end
  end
end
