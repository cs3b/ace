# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"

class TSCOMP001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-compressor")
  end

  def run_cmd(*args, chdir: @root)
    Open3.capture3(@exe, *args, chdir: chdir)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    output = stdout + stderr
    assert_match(/ace-compressor/, output)
    assert_match(/--mode/, output)
    assert_match(/--source-scope/, output)
  end

  def test_exact_stdio_and_per_source_output
    Dir.mktmpdir("ace-compressor-e2e-") do |dir|
      first = File.join(dir, "a.md")
      second = File.join(dir, "b.md")
      File.write(first, "# Alpha\n\nOne\n")
      File.write(second, "# Beta\n\nTwo\n")

      stdout, stderr, status = run_cmd(first, "--mode", "exact", "--format", "stdio", chdir: dir)
      assert status.success?, stderr
      assert_match(/SEC\|alpha/i, stdout)

      exports = File.join(dir, "exports")
      FileUtils.mkdir_p(exports)
      stdout, stderr, status = run_cmd(second, first, "--mode", "exact", "--source-scope", "per-source", "--output", exports, chdir: dir)
      assert status.success?, stderr
      assert_equal 2, Dir.glob(File.join(exports, "*")).size
      assert_match(/exports/, stdout + stderr)
    end
  end
end
