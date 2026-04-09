# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"

class TSRETRO001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-retro")
  end

  def run_cmd(*args, chdir: @root)
    Open3.capture3(@exe, *args, chdir: chdir)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    assert_match(/ace-retro/, stdout + stderr)
    assert_match(/create|list/, stdout + stderr)
  end

  def test_create_and_filter_retro
    Dir.mktmpdir("ace-retro-e2e-") do |dir|
      stdout, stderr, status = run_cmd("create", "Sprint Review", "--type", "standard", "--tags", "sprint,team", chdir: dir)
      assert status.success?, stderr
      assert_match(/Sprint Review/, stdout + stderr)

      stdout, stderr, status = run_cmd("list", "--tags", "sprint", chdir: dir)
      assert status.success?, stderr
      assert_match(/Sprint Review|sprint/i, stdout)
    end
  end
end
