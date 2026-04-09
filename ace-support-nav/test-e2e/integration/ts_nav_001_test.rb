# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"

class TSNAV001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-nav")
  end

  def run_cmd(*args, chdir: @root)
    Open3.capture3(@exe, *args, chdir: chdir)
  end

  def test_help_and_sources_surface
    stdout, stderr, status = run_cmd("--help")
    assert status.success?, stderr
    assert_match(/ace-nav/, stdout + stderr)

    stdout, stderr, status = run_cmd("--sources")
    assert status.success?, stderr
    refute_empty stdout.strip
  end

  def test_resolves_local_guide_protocol
    Dir.mktmpdir("ace-nav-e2e-") do |dir|
      guide_dir = File.join(dir, ".ace-handbook", "guides")
      FileUtils.mkdir_p(guide_dir)
      File.write(File.join(guide_dir, "configuration.g.md"), "# Configuration\n")

      stdout, stderr, status = run_cmd("resolve", "guide://@project/configuration", chdir: dir)
      assert status.success?, stderr
      assert_includes stdout, "configuration.g.md"
    end
  end
end
