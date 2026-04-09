# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"

class TSBUNDLE001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-bundle")
  end

  def run_cmd(*args, chdir: @root)
    Open3.capture3(@exe, *args, chdir: chdir)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    output = stdout + stderr
    assert_match(/ace-bundle/, output)
    assert_match(/--output/, output)
  end

  def test_bundles_local_frontmatter_file
    Dir.mktmpdir("ace-bundle-e2e-") do |dir|
      File.write(File.join(dir, "sample.md"), "# Sample\n\nBundled content\n")
      File.write(File.join(dir, "context.md"), <<~MARKDOWN)
        ---
        bundle:
          files:
            - sample.md
        ---
        Prompt body
      MARKDOWN

      stdout, stderr, status = run_cmd("context.md", "--output", "stdio", chdir: dir)

      assert status.success?, stderr
      assert_includes stdout, "Bundled content"
      assert_includes stdout, "sample.md"
    end
  end
end
