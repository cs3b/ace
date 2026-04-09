# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"

class TSIDEA001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-idea")
  end

  def run_cmd(*args, chdir: @root)
    Open3.capture3(@exe, *args, chdir: chdir)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    assert_match(/ace-idea/, stdout + stderr)
    assert_match(/create|list|update/, stdout + stderr)
  end

  def test_create_list_and_archive_lifecycle
    Dir.mktmpdir("ace-idea-e2e-") do |dir|
      stdout, stderr, status = run_cmd("create", "Integration smoke idea", chdir: dir)
      assert status.success?, stderr
      assert_match(/Integration smoke idea/, stdout)

      idea_file = Dir.glob(File.join(dir, ".ace-ideas", "**", "*.md")).first
      refute_nil idea_file
      idea_id = File.read(idea_file)[/^id:\s*(.+)$/, 1]
      refute_nil idea_id

      stdout, stderr, status = run_cmd("list", "--status", "pending", chdir: dir)
      assert status.success?, stderr
      assert_includes stdout, idea_id

      stdout, stderr, status = run_cmd("update", idea_id, "--move-to", "archive", chdir: dir)
      assert status.success?, stderr

      stdout, stderr, status = run_cmd("list", "--in", "archive", chdir: dir)
      assert status.success?, stderr
      assert_includes stdout, idea_id
    end
  end
end
