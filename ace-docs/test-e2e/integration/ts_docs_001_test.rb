# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"
require "date"

class TSDOCS001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-docs")
  end

  def run_cmd(*args, chdir: @root)
    Open3.capture3(@exe, *args, chdir: chdir)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    assert_match(/ace-docs/, stdout + stderr)
    assert_match(/status/, stdout + stderr)
  end

  def test_status_reports_seeded_docs
    Dir.mktmpdir("ace-docs-e2e-") do |dir|
      FileUtils.mkdir_p(File.join(dir, ".ace", "docs"))
      File.write(File.join(dir, ".ace", "docs", "config.yml"), <<~YAML)
        document_types:
          guide:
            paths:
              - "*.md"
      YAML
      File.write(File.join(dir, "guide.md"), <<~MARKDOWN)
        ---
        doc-type: guide
        purpose: Test doc
        ace-docs:
          last-updated: #{Date.today}
        ---

        # Guide
      MARKDOWN

      stdout, stderr, status = run_cmd("status", chdir: dir)
      assert status.success?, stderr
      assert_includes stdout, "guide.md"
      assert_match(/Managed Documents|guide/, stdout)
    end
  end
end
