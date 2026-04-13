# frozen_string_literal: true

require "test_helper"
require "ace/review/atoms/diff_boundary_finder"

class DiffBoundaryFinderTest < AceReviewTest
  # Use shared temp dir to reduce overhead (no file operations needed here)
  def self.use_shared_temp_dir?
    true
  end

  def setup
    super
    @finder = Ace::Review::Atoms::DiffBoundaryFinder
  end

  # Basic parsing tests
  def test_parse_returns_empty_array_for_nil
    result = @finder.parse(nil)

    assert_equal [], result
  end

  def test_parse_returns_empty_array_for_empty_string
    result = @finder.parse("")

    assert_equal [], result
  end

  def test_parse_single_file_diff
    diff = <<~DIFF
      diff --git a/lib/foo.rb b/lib/foo.rb
      index 1234567..abcdefg 100644
      --- a/lib/foo.rb
      +++ b/lib/foo.rb
      @@ -1,3 +1,4 @@
       class Foo
      +  def bar
      +  end
       end
    DIFF

    result = @finder.parse(diff)

    assert_equal 1, result.length
    assert_equal "lib/foo.rb", result[0][:path]
    assert_equal :modified, result[0][:change_type]
    assert_equal 9, result[0][:lines]
    assert_includes result[0][:content], "diff --git"
    assert_includes result[0][:content], "class Foo"
  end

  def test_parse_multiple_file_diffs
    diff = <<~DIFF
      diff --git a/lib/foo.rb b/lib/foo.rb
      index 1234567..abcdefg 100644
      --- a/lib/foo.rb
      +++ b/lib/foo.rb
      @@ -1,3 +1,4 @@
       class Foo
       end
      diff --git a/test/foo_test.rb b/test/foo_test.rb
      index 2345678..bcdefgh 100644
      --- a/test/foo_test.rb
      +++ b/test/foo_test.rb
      @@ -1,2 +1,3 @@
       class FooTest
       end
    DIFF

    result = @finder.parse(diff)

    assert_equal 2, result.length
    assert_equal "lib/foo.rb", result[0][:path]
    assert_equal "test/foo_test.rb", result[1][:path]
  end

  def test_parse_detects_new_file
    diff = <<~DIFF
      diff --git a/lib/new_file.rb b/lib/new_file.rb
      new file mode 100644
      index 0000000..abcdefg
      --- /dev/null
      +++ b/lib/new_file.rb
      @@ -0,0 +1,3 @@
      +class NewFile
      +end
    DIFF

    result = @finder.parse(diff)

    assert_equal 1, result.length
    assert_equal "lib/new_file.rb", result[0][:path]
    assert_equal :added, result[0][:change_type]
  end

  def test_parse_detects_deleted_file
    diff = <<~DIFF
      diff --git a/lib/old_file.rb b/lib/old_file.rb
      deleted file mode 100644
      index abcdefg..0000000
      --- a/lib/old_file.rb
      +++ /dev/null
      @@ -1,3 +0,0 @@
      -class OldFile
      -end
    DIFF

    result = @finder.parse(diff)

    assert_equal 1, result.length
    assert_equal "lib/old_file.rb", result[0][:path]
    assert_equal :deleted, result[0][:change_type]
  end

  def test_parse_handles_renamed_file
    # Renamed files show as: diff --git a/old/path b/new/path
    diff = <<~DIFF
      diff --git a/lib/old_name.rb b/lib/new_name.rb
      similarity index 95%
      rename from lib/old_name.rb
      rename to lib/new_name.rb
      index 1234567..abcdefg 100644
      --- a/lib/old_name.rb
      +++ b/lib/new_name.rb
      @@ -1,3 +1,3 @@
       class Foo
       end
    DIFF

    result = @finder.parse(diff)

    assert_equal 1, result.length
    # Uses b/ side (destination path) for renamed files
    assert_equal "lib/new_name.rb", result[0][:path]
    assert_equal :modified, result[0][:change_type]
  end

  def test_parse_preserves_complete_diff_content
    original_diff = <<~DIFF
      diff --git a/lib/foo.rb b/lib/foo.rb
      index 1234567..abcdefg 100644
      --- a/lib/foo.rb
      +++ b/lib/foo.rb
      @@ -1,3 +1,4 @@
       class Foo
      +  def bar
      +  end
       end
    DIFF

    result = @finder.parse(original_diff)

    # Content should be identical to original (single file)
    assert_equal original_diff, result[0][:content]
  end

  def test_parse_handles_paths_with_spaces
    diff = <<~DIFF
      diff --git a/lib/my file.rb b/lib/my file.rb
      index 1234567..abcdefg 100644
      --- a/lib/my file.rb
      +++ b/lib/my file.rb
      @@ -1,1 +1,2 @@
       class Foo
      +end
    DIFF

    result = @finder.parse(diff)

    assert_equal 1, result.length
    assert_equal "lib/my file.rb", result[0][:path]
  end

  # file_paths tests
  def test_file_paths_returns_empty_for_nil
    result = @finder.file_paths(nil)

    assert_equal [], result
  end

  def test_file_paths_returns_list_of_paths
    diff = <<~DIFF
      diff --git a/lib/foo.rb b/lib/foo.rb
      --- a/lib/foo.rb
      +++ b/lib/foo.rb
      @@ -1 +1 @@
      -old
      +new
      diff --git a/lib/bar.rb b/lib/bar.rb
      --- a/lib/bar.rb
      +++ b/lib/bar.rb
      @@ -1 +1 @@
      -old
      +new
    DIFF

    result = @finder.file_paths(diff)

    assert_equal ["lib/foo.rb", "lib/bar.rb"], result
  end

  # file_count tests
  def test_file_count_returns_zero_for_nil
    result = @finder.file_count(nil)

    assert_equal 0, result
  end

  def test_file_count_returns_zero_for_empty_string
    result = @finder.file_count("")

    assert_equal 0, result
  end

  def test_file_count_returns_correct_count
    diff = <<~DIFF
      diff --git a/lib/foo.rb b/lib/foo.rb
      --- a/lib/foo.rb
      +++ b/lib/foo.rb
      diff --git a/lib/bar.rb b/lib/bar.rb
      --- a/lib/bar.rb
      +++ b/lib/bar.rb
      diff --git a/lib/baz.rb b/lib/baz.rb
      --- a/lib/baz.rb
      +++ b/lib/baz.rb
    DIFF

    result = @finder.file_count(diff)

    assert_equal 3, result
  end

  # group_by_directory tests
  def test_group_by_directory_groups_correctly
    blocks = [
      {path: "lib/atoms/foo.rb", content: "...", lines: 10, change_type: :modified},
      {path: "lib/atoms/bar.rb", content: "...", lines: 20, change_type: :added},
      {path: "test/atoms/foo_test.rb", content: "...", lines: 15, change_type: :modified},
      {path: "lib/molecules/baz.rb", content: "...", lines: 25, change_type: :deleted}
    ]

    result = @finder.group_by_directory(blocks)

    assert_equal 3, result.keys.length
    assert_equal 2, result["lib/atoms"].length
    assert_equal 1, result["test/atoms"].length
    assert_equal 1, result["lib/molecules"].length
  end

  def test_group_by_directory_handles_empty_array
    result = @finder.group_by_directory([])

    assert_equal({}, result)
  end

  def test_group_by_directory_handles_root_level_files
    blocks = [
      {path: "README.md", content: "...", lines: 5, change_type: :modified}
    ]

    result = @finder.group_by_directory(blocks)

    assert_equal 1, result.keys.length
    assert_equal 1, result["."].length
  end

  # Edge cases
  def test_parse_handles_binary_file_diff
    diff = <<~DIFF
      diff --git a/image.png b/image.png
      new file mode 100644
      index 0000000..abcdefg
      Binary files /dev/null and b/image.png differ
    DIFF

    result = @finder.parse(diff)

    assert_equal 1, result.length
    assert_equal "image.png", result[0][:path]
    assert_equal :added, result[0][:change_type]
  end

  def test_parse_handles_diff_without_content_lines
    # A diff header with no actual changes (edge case)
    diff = <<~DIFF
      diff --git a/lib/foo.rb b/lib/foo.rb
      index 1234567..1234567 100644
    DIFF

    result = @finder.parse(diff)

    assert_equal 1, result.length
    assert_equal "lib/foo.rb", result[0][:path]
    assert_equal 2, result[0][:lines]
  end
end
