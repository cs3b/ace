# frozen_string_literal: true

require_relative "../test_helper"

class RepositoryStateDetectorTest < AceGitTestCase
  def setup
    super
    @detector = Ace::Git::Atoms::RepositoryStateDetector
  end

  def test_detect_returns_symbol
    skip "Not in git repo" unless Ace::Git::Atoms::CommandExecutor.in_git_repo?

    result = @detector.detect
    assert %i[clean dirty rebasing merging unknown].include?(result)
  end

  def test_clean_check_returns_boolean
    skip "Not in git repo" unless Ace::Git::Atoms::CommandExecutor.in_git_repo?

    result = @detector.clean?
    assert [true, false].include?(result)
  end

  def test_dirty_check_returns_boolean
    skip "Not in git repo" unless Ace::Git::Atoms::CommandExecutor.in_git_repo?

    result = @detector.dirty?
    assert [true, false].include?(result)
  end

  def test_state_description_returns_string
    skip "Not in git repo" unless Ace::Git::Atoms::CommandExecutor.in_git_repo?

    result = @detector.state_description
    assert_instance_of String, result
    refute_empty result
  end
end
