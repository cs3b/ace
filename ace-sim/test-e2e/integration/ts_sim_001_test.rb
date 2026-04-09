# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"

class TSSIM001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-sim")
  end

  def run_cmd(*args, chdir: @root)
    Open3.capture3(@exe, *args, chdir: chdir)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    output = stdout + stderr
    assert_match(/ace-sim/, output)
    assert_match(/run/, output)
    assert_match(/preset|provider/, output)
  end

  def test_synthesis_provider_guard
    Dir.mktmpdir("ace-sim-e2e-") do |dir|
      File.write(File.join(dir, "source.md"), "# Example idea\n\nAdd a retry policy.\n")

      _stdout, stderr, status = run_cmd(
        "run",
        "--preset", "validate-idea",
        "--source", "source.md",
        "--provider", "glite",
        "--repeat", "1",
        "--synthesis-provider", "claude:haiku",
        chdir: dir
      )

      refute status.success?
      assert_match(/synthesis_provider requires synthesis_workflow/i, stderr)
    end
  end
end
