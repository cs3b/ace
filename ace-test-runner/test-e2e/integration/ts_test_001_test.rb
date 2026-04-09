# frozen_string_literal: true

require "minitest/autorun"
require "open3"

class TSTEST001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-test")
  end

  def run_cmd(*args)
    Open3.capture3({"RUBYOPT" => "-W0"}, @exe, *args, chdir: @root)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    assert_match(/ace-test/, stdout + stderr)
  end

  def test_runs_atoms_group_from_sandbox_copy
    stdout, stderr, status = run_cmd("atoms")

    assert status.success?, stderr
    assert_match(/atoms|tests|assertions/i, stdout)
  end
end
