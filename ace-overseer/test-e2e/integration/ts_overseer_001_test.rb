# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "json"

class TSOVERSEER001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-overseer")
  end

  def run_cmd(*args)
    Open3.capture3(@exe, *args, chdir: @root)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    output = stdout + stderr
    assert_match(/ace-overseer/, output)
    assert_match(/work-on|status|prune/, output)
  end

  def test_status_and_prune_dry_run_surfaces
    stdout, stderr, status = run_cmd("status", "--format", "json")
    assert status.success?, stderr
    assert JSON.parse(stdout)

    stdout, stderr, status = run_cmd("prune", "--dry-run")
    assert status.success?, stderr
    assert_match(/prune|nothing|eligible/i, stdout + stderr)
  end
end
