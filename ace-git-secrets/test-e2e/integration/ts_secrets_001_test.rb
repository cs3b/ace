# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"
require "json"

class TSSECRETS001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-git-secrets")
  end

  def run_cmd(*args, chdir: @root)
    Open3.capture3(@exe, *args, chdir: chdir)
  end

  def git(*args, chdir:)
    stdout, stderr, status = Open3.capture3("git", *args, chdir: chdir)
    raise stderr unless status.success?
    stdout
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    assert_match(/ace-git-secrets/, stdout + stderr)
    assert_match(/scan/, stdout + stderr)
  end

  def test_scan_clean_repository_returns_structured_report
    Dir.mktmpdir("ace-git-secrets-e2e-") do |dir|
      git("init", chdir: dir)
      git("config", "user.name", "Test User", chdir: dir)
      git("config", "user.email", "test@example.com", chdir: dir)
      File.write(File.join(dir, "README.md"), "clean repo\n")
      git("add", "README.md", chdir: dir)
      git("commit", "-m", "initial", chdir: dir)

      stdout, stderr, status = run_cmd("scan", "--report-format", "json", chdir: dir)
      assert status.success?, stderr

      assert_match(/Scan|clean|no secrets/i, stdout)
    end
  end
end
