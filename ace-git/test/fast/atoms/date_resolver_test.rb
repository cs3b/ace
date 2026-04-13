# frozen_string_literal: true

require "test_helper"

class DateResolverTest < AceGitTestCase
  def setup
    super
    @resolver = Ace::Git::Atoms::DateResolver
  end

  def test_commit_sha_recognizes_valid_shas
    assert @resolver.commit_sha?("abc1234")           # 7 chars (min)
    assert @resolver.commit_sha?("1234567")           # 7 chars
    assert @resolver.commit_sha?("a1b2c3d4e5f6")      # 12 chars
    assert @resolver.commit_sha?("1234567890abcdef1234567890abcdef12345678")  # 40 chars (full)
  end

  def test_commit_sha_rejects_invalid_shas
    refute @resolver.commit_sha?("short")
    refute @resolver.commit_sha?("not-a-sha")
    refute @resolver.commit_sha?("HEAD")
  end

  def test_git_ref_recognizes_refs_paths
    assert @resolver.git_ref?("refs/heads/main")
    assert @resolver.git_ref?("refs/remotes/origin/develop")
    assert @resolver.git_ref?("refs/tags/v1.0.0")
  end

  def test_git_ref_recognizes_remote_branches
    assert @resolver.git_ref?("origin/main")
    assert @resolver.git_ref?("upstream/develop")
  end

  def test_git_ref_recognizes_head_references
    assert @resolver.git_ref?("HEAD")
    assert @resolver.git_ref?("HEAD~1")
    assert @resolver.git_ref?("HEAD^")
  end

  def test_git_ref_recognizes_branch_names
    assert @resolver.git_ref?("main")
    assert @resolver.git_ref?("feature-branch")
    assert @resolver.git_ref?("feature/new-thing")
  end

  def test_git_ref_rejects_non_refs
    refute @resolver.git_ref?("2025-01-01")
    refute @resolver.git_ref?("7d")
  end

  def test_parse_relative_time_handles_days
    result = @resolver.parse_relative_time("7d")
    expected = (Date.today - 7).strftime("%Y-%m-%d")
    assert_equal expected, result
  end

  def test_parse_relative_time_handles_days_ago
    result = @resolver.parse_relative_time("5 days ago")
    expected = (Date.today - 5).strftime("%Y-%m-%d")
    assert_equal expected, result
  end

  def test_parse_relative_time_handles_weeks_ago
    result = @resolver.parse_relative_time("1 week ago")
    expected = (Date.today - 7).strftime("%Y-%m-%d")
    assert_equal expected, result
  end

  def test_parse_relative_time_handles_months_ago
    result = @resolver.parse_relative_time("2 months ago")
    expected = (Date.today << 2).strftime("%Y-%m-%d")
    assert_equal expected, result
  end

  def test_parse_relative_time_handles_date_strings
    result = @resolver.parse_relative_time("2025-01-01")
    assert_equal "2025-01-01", result
  end

  def test_parse_relative_time_returns_nil_for_invalid_strings
    result = @resolver.parse_relative_time("invalid")
    assert_nil result
  end

  def test_format_since_handles_date_objects
    date = Date.new(2025, 1, 15)
    result = @resolver.format_since(date)
    assert_equal "2025-01-15", result
  end

  def test_format_since_handles_time_objects
    time = Time.new(2025, 1, 15, 10, 30)
    result = @resolver.format_since(time)
    assert_equal "2025-01-15", result
  end

  def test_format_since_handles_string_inputs
    result = @resolver.format_since("7d")
    expected = (Date.today - 7).strftime("%Y-%m-%d")
    assert_equal expected, result
  end

  def test_resolve_since_to_commit_returns_sha_unchanged
    sha = "abc1234567"
    result = @resolver.resolve_since_to_commit(sha)
    assert_equal sha, result
  end

  def test_resolve_since_to_commit_returns_ref_unchanged
    ref = "origin/main"
    result = @resolver.resolve_since_to_commit(ref)
    assert_equal ref, result
  end

  def test_resolve_since_to_commit_returns_head_for_nil
    result = @resolver.resolve_since_to_commit(nil)
    assert_equal "HEAD", result
  end

  def test_resolve_since_to_commit_returns_head_for_empty_string
    result = @resolver.resolve_since_to_commit("")
    assert_equal "HEAD", result
  end
end
