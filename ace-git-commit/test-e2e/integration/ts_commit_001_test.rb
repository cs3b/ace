# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"

class TSCOMMIT001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-git-commit")
  end

  def run_cmd(*args, chdir:, env: {})
    Open3.capture3(env, @exe, *args, chdir: chdir)
  end

  def git(*args, chdir:)
    stdout, stderr, status = Open3.capture3("git", *args, chdir: chdir)
    raise stderr unless status.success?
    stdout
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help", chdir: @root)

    assert status.success?, stderr
    assert_match(/ace-git-commit/, stdout + stderr)
    assert_match(/--message|-m/, stdout + stderr)
  end

  def test_commits_tracked_changes_with_explicit_message
    Dir.mktmpdir("ace-git-commit-e2e-") do |dir|
      git("init", chdir: dir)
      git("config", "user.name", "Test User", chdir: dir)
      git("config", "user.email", "test@example.com", chdir: dir)
      File.write(File.join(dir, "README.md"), "first\n")
      git("add", "README.md", chdir: dir)
      git("commit", "-m", "initial", chdir: dir)
      File.write(File.join(dir, "README.md"), "second\n")

      _stdout, stderr, status = run_cmd("-m", "test: update readme", "README.md", chdir: dir)
      assert status.success?, stderr

      message = git("log", "-1", "--pretty=%s", chdir: dir).strip
      assert_equal "test: update readme", message
    end
  end
end
