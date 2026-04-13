# frozen_string_literal: true

require "test_helper"

class DiffFilterTest < AceGitTestCase
  def setup
    super
    @diff_filter = Ace::Git::Molecules::DiffFilter
  end

  # Sample diff for testing
  def sample_diff
    <<~DIFF
      diff --git a/lib/foo.rb b/lib/foo.rb
      index 1234567..abcdefg 100644
      --- a/lib/foo.rb
      +++ b/lib/foo.rb
      @@ -1,3 +1,4 @@
       class Foo
      +  def bar; end
       end
      diff --git a/test/foo_test.rb b/test/foo_test.rb
      index 2345678..bcdefgh 100644
      --- a/test/foo_test.rb
      +++ b/test/foo_test.rb
      @@ -1,3 +1,4 @@
       class FooTest
      +  def test_bar; end
       end
      diff --git a/vendor/bundle/foo.rb b/vendor/bundle/foo.rb
      index 3456789..cdefghi 100644
      --- a/vendor/bundle/foo.rb
      +++ b/vendor/bundle/foo.rb
      @@ -1,3 +1,4 @@
       class VendorFoo
      +  def baz; end
       end
    DIFF
  end

  # --- filter_by_includes tests ---

  def test_filter_by_includes_returns_diff_for_nil_patterns
    result = @diff_filter.filter_by_includes(sample_diff, nil)
    assert_equal sample_diff, result
  end

  def test_filter_by_includes_returns_diff_for_empty_patterns
    result = @diff_filter.filter_by_includes(sample_diff, [])
    assert_equal sample_diff, result
  end

  def test_filter_by_includes_returns_diff_for_nil_diff
    result = @diff_filter.filter_by_includes(nil, ["lib/**/*"])
    assert_nil result
  end

  def test_filter_by_includes_returns_diff_for_empty_diff
    result = @diff_filter.filter_by_includes("", ["lib/**/*"])
    assert_equal "", result
  end

  def test_filter_by_includes_filters_to_matching_files
    result = @diff_filter.filter_by_includes(sample_diff, ["lib/**/*"])

    # Should include lib/foo.rb
    assert_includes result, "lib/foo.rb"
    assert_includes result, "def bar; end"

    # Should NOT include test/foo_test.rb or vendor/
    refute_includes result, "test/foo_test.rb"
    refute_includes result, "vendor/bundle/foo.rb"
  end

  def test_filter_by_includes_supports_multiple_patterns
    result = @diff_filter.filter_by_includes(sample_diff, ["lib/**/*", "test/**/*"])

    # Should include both lib and test
    assert_includes result, "lib/foo.rb"
    assert_includes result, "test/foo_test.rb"

    # Should NOT include vendor
    refute_includes result, "vendor/bundle/foo.rb"
  end

  def test_filter_by_includes_returns_empty_when_no_match
    result = @diff_filter.filter_by_includes(sample_diff, ["nonexistent/**/*"])
    assert_equal "", result
  end

  # --- filter_by_patterns tests ---

  def test_filter_by_patterns_excludes_matching_files
    result = @diff_filter.filter_by_patterns(sample_diff, ["vendor/**/*"])

    # Should include lib and test
    assert_includes result, "lib/foo.rb"
    assert_includes result, "test/foo_test.rb"

    # Should NOT include vendor
    refute_includes result, "vendor/bundle/foo.rb"
  end

  # --- truncate tests ---

  def test_truncate_returns_diff_when_under_limit
    result = @diff_filter.truncate(sample_diff, 1000)
    assert_equal sample_diff, result
  end

  def test_truncate_truncates_when_over_limit
    result = @diff_filter.truncate(sample_diff, 5)

    lines = result.split("\n")
    assert_equal 7, lines.length  # 5 lines + blank + truncation note
    assert_includes result, "... (diff truncated at 5 lines)"
  end
end
