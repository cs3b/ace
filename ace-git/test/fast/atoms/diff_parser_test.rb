# frozen_string_literal: true

require "test_helper"

class DiffParserTest < AceGitTestCase
  def setup
    super
    @parser = Ace::Git::Atoms::DiffParser
  end

  def test_count_lines_returns_zero_for_empty_diff
    assert_equal 0, @parser.count_lines("")
    assert_equal 0, @parser.count_lines(nil)
  end

  def test_count_lines_counts_correctly
    diff = "line1\nline2\nline3"
    assert_equal 3, @parser.count_lines(diff)
  end

  def test_count_changes_returns_zero_for_empty_diff
    result = @parser.count_changes("")

    assert_equal 0, result[:additions]
    assert_equal 0, result[:deletions]
    assert_equal 0, result[:files]
    assert_equal 0, result[:total_changes]
  end

  def test_count_changes_counts_additions_and_deletions
    diff = <<~DIFF
      diff --git a/lib/foo.rb b/lib/foo.rb
      --- a/lib/foo.rb
      +++ b/lib/foo.rb
      @@ -1,2 +1,3 @@
       context line
      +added line
      -removed line
      +another added line
    DIFF

    result = @parser.count_changes(diff)

    assert_equal 2, result[:additions]
    assert_equal 1, result[:deletions]
    assert_equal 1, result[:files]
    assert_equal 3, result[:total_changes]
  end

  def test_count_changes_ignores_diff_headers
    diff = <<~DIFF
      diff --git a/lib/foo.rb b/lib/foo.rb
      --- a/lib/foo.rb
      +++ b/lib/foo.rb
      @@ -1,1 +1,1 @@
      +real addition
    DIFF

    result = @parser.count_changes(diff)

    # Should not count +++ and --- as additions/deletions
    assert_equal 1, result[:additions]
    assert_equal 0, result[:deletions]
  end

  def test_exceeds_limit_returns_true_when_over_limit
    diff = "line\n" * 1000
    assert @parser.exceeds_limit?(diff, 500)
  end

  def test_exceeds_limit_returns_false_when_under_limit
    diff = "line\n" * 100
    refute @parser.exceeds_limit?(diff, 500)
  end

  def test_extract_files_returns_array_of_file_paths
    diff = <<~DIFF
      diff --git a/lib/foo.rb b/lib/foo.rb
      --- a/lib/foo.rb
      +++ b/lib/foo.rb
      diff --git a/lib/bar.rb b/lib/bar.rb
      --- a/lib/bar.rb
      +++ b/lib/bar.rb
    DIFF

    files = @parser.extract_files(diff)

    assert_equal 2, files.length
    assert_includes files, "lib/foo.rb"
    assert_includes files, "lib/bar.rb"
  end

  def test_extract_files_returns_empty_for_empty_diff
    assert_equal [], @parser.extract_files("")
    assert_equal [], @parser.extract_files(nil)
  end

  def test_parse_returns_structured_data
    diff = <<~DIFF
      diff --git a/lib/foo.rb b/lib/foo.rb
      +added line
      -removed line
    DIFF

    result = @parser.parse(diff)

    assert_instance_of Hash, result
    assert result.key?(:content)
    assert result.key?(:stats)
    assert result.key?(:files)
    assert result.key?(:line_count)
    assert result.key?(:empty)

    refute result[:empty]
    assert_equal diff, result[:content]
  end

  def test_parse_handles_empty_diff
    result = @parser.parse("")

    assert result[:empty]
    assert_equal 0, result[:stats][:total_changes]
  end

  def test_has_changes_returns_true_for_diff_with_changes
    diff = "+added line\n-removed line"
    assert @parser.has_changes?(diff)
  end

  def test_has_changes_returns_false_for_empty_diff
    refute @parser.has_changes?("")
    refute @parser.has_changes?(nil)
  end

  def test_has_changes_returns_false_for_diff_with_only_headers
    diff = <<~DIFF
      diff --git a/lib/foo.rb b/lib/foo.rb
      --- a/lib/foo.rb
      +++ b/lib/foo.rb
    DIFF

    refute @parser.has_changes?(diff)
  end
end
