# frozen_string_literal: true

require "test_helper"
require "ace/review/molecules/gh_pr_comment_fetcher"

class GhPrCommentFetcherTest < AceReviewTest
  def test_qualified_pr_uses_explicit_repo_for_comment_fetch
    arguments = []
    executor = lambda do |command, args, **_options|
      arguments << [command, args]
      {success: true, stdout: '{"comments":[],"reviews":[],"number":42,"title":"Test","author":{"login":"owner"}}'}
    end

    Ace::Git::Github::CliExecutor.stub :execute, executor do
      Ace::Review::Molecules::GhPrCommentFetcher.stub :fetch_review_threads, [] do
        result = Ace::Review::Molecules::GhPrCommentFetcher.fetch("owner/repo#42")
        assert result[:success], result[:error]
      end
    end

    assert_equal [["pr", ["view", "42", "--repo", "owner/repo", "--json",
      "comments,reviews,number,title,author"]]], arguments
  end
end
