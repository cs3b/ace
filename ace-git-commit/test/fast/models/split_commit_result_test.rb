# frozen_string_literal: true

require_relative "../../test_helper"

class SplitCommitResultTest < TestCase
  def test_tracks_success_and_failure
    result = Ace::GitCommit::Models::SplitCommitResult.new(original_head: "abc123")
    group = Ace::GitCommit::Models::CommitGroup.new(
      scope_name: "docs",
      source: ".ace/git/commit.yml",
      config: {},
      files: ["a.md"]
    )

    result.add_success(group, "def456")
    result.add_failure(group, "hook failed")

    assert_equal ["def456"], result.commit_shas
    refute result.success?
    assert result.failed?
  end
end
