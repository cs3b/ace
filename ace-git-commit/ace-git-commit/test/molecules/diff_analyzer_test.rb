# frozen_string_literal: true

require_relative "../test_helper"

class DiffAnalyzerTest < TestCase
  def setup
    @git = MockGitExecutor.new
    @analyzer = Ace::GitCommit::Molecules::DiffAnalyzer.new(@git)
  end

  def test_analyze_diff_extracts_file_information
    diff = <<~DIFF
      diff --git a/file1.rb b/file1.rb
      index abc123..def456 100644
      --- a/file1.rb
      +++ b/file1.rb
      @@ -1,3 +1,4 @@
       line 1
      +new line
       line 2
       line 3
      -old line
    DIFF

    result = @analyzer.analyze_diff(diff)

    assert_equal ["file1.rb"], result[:files_changed]
    assert_equal 1, result[:insertions]
    assert_equal 1, result[:deletions]
  end

  def test_detect_scope_identifies_gem_scope
    files = ["ace-git-commit/lib/file.rb", "ace-git-commit/test/test.rb"]
    scope = @analyzer.detect_scope(files)
    assert_equal "ace-git-commit", scope
  end

  def test_detect_scope_identifies_test_scope
    files = ["test/unit/test1.rb", "spec/integration/test2.rb"]
    scope = @analyzer.detect_scope(files)
    assert_equal "test", scope
  end

  def test_detect_scope_identifies_docs_scope
    files = ["README.md", "docs/guide.md"]
    scope = @analyzer.detect_scope(files)
    assert_equal "docs", scope
  end

  def test_detect_scope_returns_nil_for_mixed_files
    files = ["lib/file.rb", "docs/guide.md", "test/test.rb"]
    scope = @analyzer.detect_scope(files)
    assert_nil scope
  end

  # Mock GitExecutor for testing
  class MockGitExecutor
    def execute(*args)
      case args.first
      when "diff"
        ""
      when "diff", "--cached", "--name-only"
        "file1.rb\nfile2.rb"
      when "ls-files"
        ""
      else
        ""
      end
    end
  end
end