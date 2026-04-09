# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"

class TSLINT001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-lint")
  end

  def run_cmd(*args, chdir: @root)
    Open3.capture3(@exe, *args, chdir: chdir)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    output = stdout + stderr
    assert_match(/ace-lint/, output)
    assert_match(/--fix/, output)
    assert_match(/--doctor/, output)
  end

  def test_lints_valid_file_and_runs_doctor
    Dir.mktmpdir("ace-lint-e2e-") do |dir|
      File.write(File.join(dir, "valid.rb"), "class Valid\n  def ok\n    true\n  end\nend\n")

      stdout, stderr, status = run_cmd("valid.rb", chdir: dir)
      assert status.success?, stderr
      assert_match(/passed|ok|valid/i, stdout + stderr)

      stdout, stderr, status = run_cmd("--doctor", chdir: dir)
      assert status.success? || status.exitstatus <= 2, stderr
    end
  end
end
