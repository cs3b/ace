# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"

class TSDEMO001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-demo")
  end

  def run_cmd(*args, chdir: @root)
    Open3.capture3(@exe, *args, chdir: chdir)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    output = stdout + stderr
    assert_match(/ace-demo/, output)
    assert_match(/create/, output)
    assert_match(/show/, output)
  end

  def test_create_and_show_tape
    Dir.mktmpdir("ace-demo-e2e-") do |dir|
      stdout, stderr, status = run_cmd("create", "my-demo", "--", "echo hello", chdir: dir)
      assert status.success?, stderr
      assert_match(/my-demo/, stdout + stderr)

      stdout, stderr, status = run_cmd("show", "my-demo", chdir: dir)
      assert status.success?, stderr
      assert_includes stdout, "echo hello"
    end
  end
end
