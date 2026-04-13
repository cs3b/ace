# frozen_string_literal: true

require "test_helper"

class PatternFilterTest < AceGitTestCase
  def setup
    super
    @filter = Ace::Git::Atoms::PatternFilter
  end

  def test_glob_to_regex_converts_simple_patterns
    patterns = @filter.glob_to_regex(["test/**/*"])

    assert_instance_of Array, patterns
    assert_equal 1, patterns.length
    assert_instance_of Regexp, patterns.first
  end

  def test_glob_to_regex_handles_double_star
    patterns = @filter.glob_to_regex(["**/test/*"])
    regex = patterns.first

    assert regex.match?("foo/test/bar")
    assert regex.match?("test/bar")
  end

  def test_glob_to_regex_handles_single_star
    patterns = @filter.glob_to_regex(["test/*.rb"])
    regex = patterns.first

    assert regex.match?("test/foo.rb")
    refute regex.match?("test/foo/bar.rb")
  end

  def test_should_exclude_returns_true_for_matching_pattern
    patterns = @filter.glob_to_regex(["test/**/*"])

    assert @filter.should_exclude?("test/foo.rb", patterns)
    assert @filter.should_exclude?("test/bar/baz.rb", patterns)
  end

  def test_should_exclude_returns_false_for_non_matching_pattern
    patterns = @filter.glob_to_regex(["test/**/*"])

    refute @filter.should_exclude?("lib/foo.rb", patterns)
    refute @filter.should_exclude?("spec/bar.rb", patterns)
  end

  def test_should_exclude_handles_empty_patterns
    refute @filter.should_exclude?("test/foo.rb", [])
  end

  def test_file_header_recognizes_diff_headers
    assert @filter.file_header?("diff --git a/foo.rb b/foo.rb")
    assert @filter.file_header?("+++ b/foo.rb")
    assert @filter.file_header?("--- a/foo.rb")
    assert @filter.file_header?("index abc123..def456")
  end

  def test_file_header_rejects_non_headers
    refute @filter.file_header?("+added line")
    refute @filter.file_header?("-removed line")
    refute @filter.file_header?(" context line")
  end

  def test_extract_file_path_from_diff_git_line
    path = @filter.extract_file_path("diff --git a/lib/foo.rb b/lib/foo.rb")
    assert_equal "lib/foo.rb", path
  end

  def test_extract_file_path_from_plus_line
    path = @filter.extract_file_path("+++ b/lib/bar.rb")
    assert_equal "lib/bar.rb", path
  end

  def test_extract_file_path_from_minus_line
    path = @filter.extract_file_path("--- a/lib/baz.rb")
    assert_equal "lib/baz.rb", path
  end

  def test_filter_diff_by_patterns_filters_excluded_files
    diff = <<~DIFF
      diff --git a/lib/foo.rb b/lib/foo.rb
      --- a/lib/foo.rb
      +++ b/lib/foo.rb
      @@ -1,1 +1,2 @@
      +new line
      diff --git a/test/foo_test.rb b/test/foo_test.rb
      --- a/test/foo_test.rb
      +++ b/test/foo_test.rb
      @@ -1,1 +1,2 @@
      +test line
    DIFF

    patterns = @filter.glob_to_regex(["test/**/*"])
    filtered = @filter.filter_diff_by_patterns(diff, patterns)

    assert_includes filtered, "lib/foo.rb"
    refute_includes filtered, "test/foo_test.rb"
  end

  def test_filter_diff_by_patterns_handles_empty_diff
    assert_equal "", @filter.filter_diff_by_patterns("", [])
    assert_equal "", @filter.filter_diff_by_patterns(nil, [])
  end

  def test_matches_include_returns_true_for_matching_pattern
    assert @filter.matches_include?("lib/foo.rb", ["lib/**/*.rb"])
    assert @filter.matches_include?("src/bar.js", ["src/**/*.js"])
  end

  def test_matches_include_returns_false_for_non_matching_pattern
    refute @filter.matches_include?("test/foo.rb", ["lib/**/*.rb"])
    refute @filter.matches_include?("lib/foo.js", ["lib/**/*.rb"])
  end

  def test_matches_include_returns_true_for_empty_patterns
    assert @filter.matches_include?("any/file.rb", [])
    assert @filter.matches_include?("any/file.rb", nil)
  end
end
