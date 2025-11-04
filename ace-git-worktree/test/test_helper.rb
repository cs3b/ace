# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "ace/git/worktree"

# Base test case class
class AceGitWorktreeTestCase < Minitest::Test
  def setup
    # Reset configuration before each test
    Ace::Git::Worktree.reset_configuration!
  end

  def teardown
    # Clean up after tests
    Ace::Git::Worktree.reset_configuration!
  end

  # Helper to capture stdout and stderr
  def capture_output
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new

    yield

    [$stdout.string, $stderr.string]
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  # Helper to create temporary directory
  def with_temp_dir
    require 'tmpdir'
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        yield dir
      end
    end
  end

  # Helper to create a test git repository
  def with_test_repo
    with_temp_dir do |dir|
      system("git init --quiet")
      system("git config user.email 'test@example.com'")
      system("git config user.name 'Test User'")
      File.write("README.md", "# Test Repo")
      system("git add README.md")
      system("git commit -m 'Initial commit' --quiet")
      yield dir
    end
  end

  # Mock configuration for testing
  def mock_config(overrides = {})
    default_config = {
      root_path: ".test-wt",
      mise_trust_auto: false,
      task: {
        directory_format: "task.{id}",
        branch_format: "{id}-{slug}",
        auto_mark_in_progress: false,
        auto_commit_task: false
      }
    }

    config_hash = deep_merge(default_config, overrides)
    Ace::Git::Worktree::Models::WorktreeConfig.new(config_hash)
  end

  private

  def deep_merge(hash1, hash2)
    hash1.merge(hash2) do |key, old_val, new_val|
      if old_val.is_a?(Hash) && new_val.is_a?(Hash)
        deep_merge(old_val, new_val)
      else
        new_val
      end
    end
  end
end