# frozen_string_literal: true

require_relative "../../test_helper"

class CommitSummarizerTest < TestCase
  def setup
    @git = MockGitExecutor.new
    @summarizer = Ace::GitCommit::Molecules::CommitSummarizer.new(@git)
  end

  def test_summarize_returns_formatted_output
    @git.set_commit_log("abc1234 (HEAD -> main) feat: add new feature")
    @git.set_diff_stat(" file1.rb | 10 +++++++---\n file2.rb |  5 +++++\n 2 files changed, 12 insertions(+), 3 deletions(-)")

    output = @summarizer.summarize("HEAD")

    assert_match(/^abc1234/, output)
    assert_match(/feat: add new feature/, output)
    assert_match(/2 files changed/, output)
    assert_match(/12 insertions/, output)
    assert_match(/3 deletions/, output)
  end

  def test_summarize_includes_file_stats
    @git.set_commit_log("def5678 fix: bug fix")
    @git.set_diff_stat(" lib/file.rb | 5 +++--\n 1 file changed, 3 insertions(+), 2 deletions(-)")

    output = @summarizer.summarize("HEAD")

    assert_includes output, "lib/file.rb"
    assert_includes output, "5 +++--"
    assert_includes output, "1 file changed"
  end

  def test_summarize_handles_first_commit
    @git.set_commit_log("aaa111 (HEAD -> main) Initial commit")
    @git.set_no_parent_commit(true)
    @git.set_show_stat(" README.md | 3 +++\n 1 file changed, 3 insertions(+)")

    output = @summarizer.summarize("HEAD")

    assert_match(/^aaa111/, output)
    assert_match(/Initial commit/, output)
    assert_match(/README.md/, output)
    assert_match(/1 file changed, 3 insertions/, output)
  end

  def test_summarize_with_specific_commit_sha
    @git.set_commit_log("bbb222 refactor: improve code")
    @git.set_diff_stat(" src/main.rb | 15 ++++++---------\n 1 file changed, 6 insertions(+), 9 deletions(-)")

    output = @summarizer.summarize("bbb222")

    assert_match(/^bbb222/, output)
    assert_match(/refactor: improve code/, output)
  end

  def test_summarize_with_refs
    @git.set_commit_log("ccc333 (HEAD -> feature, origin/feature) feat(api): add endpoint")
    @git.set_diff_stat(" api/endpoint.rb | 20 ++++++++++++++++++++\n 1 file changed, 20 insertions(+)")

    output = @summarizer.summarize("HEAD")

    assert_includes output, "(HEAD -> feature, origin/feature)"
    assert_includes output, "feat(api): add endpoint"
  end

  def test_summarize_strips_whitespace
    @git.set_commit_log("  ddd444 test: add tests  \n")
    @git.set_diff_stat(" test/file_test.rb | 10 ++++++++++\n 1 file changed, 10 insertions(+)\n")

    output = @summarizer.summarize("HEAD")

    # First line should not have leading whitespace
    # It will have a trailing newline from the format
    first_line = output.lines.first.chomp
    refute_match(/^\s/, first_line)
    refute_match(/\s$/, first_line)
  end

  # Mock GitExecutor for testing
  class MockGitExecutor
    attr_accessor :no_parent_commit

    def initialize
      @commit_log = ""
      @diff_stat = ""
      @show_stat = ""
      @no_parent_commit = false
    end

    def set_commit_log(log)
      @commit_log = log
    end

    def set_diff_stat(stat)
      @diff_stat = stat
    end

    def set_show_stat(stat)
      @show_stat = stat
    end

    def set_no_parent_commit(value)
      @no_parent_commit = value
    end

    def execute(*args, **kwargs)
      case args
      in ["log", "--oneline", _, "-1"]
        @commit_log
      in ["diff", "--stat", parent, child]
        if @no_parent_commit
          raise Ace::GitCommit::GitError, "fatal: ambiguous argument '#{parent}': unknown revision"
        end
        @diff_stat
      in ["show", "--stat", "--format=", _]
        @show_stat
      else
        raise "Unexpected git command: #{args.inspect}"
      end
    end
  end
end
