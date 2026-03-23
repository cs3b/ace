# frozen_string_literal: true

require "test_helper"

class SlugGeneratorTest < Minitest::Test
  include TestHelper

  def setup
    @generator = Ace::Git::Worktree::Atoms::SlugGenerator
  end

  def test_from_title_basic
    slug = @generator.from_title("Fix authentication bug")
    assert_equal "fix-authentication-bug", slug
  end

  def test_from_title_with_special_characters
    slug = @generator.from_title("Fix user:profile endpoint (v2)")
    assert_equal "fix-userprofile-endpoint-v2", slug
  end

  def test_from_title_with_long_title
    long_title = "This is a very long task title that exceeds the maximum length for generating slugs and should be truncated appropriately"
    slug = @generator.from_title(long_title, max_length: 50)
    assert slug.length <= 50
    refute slug.end_with?("-")  # Should not end with hyphen
    refute slug.empty?  # Should not be empty
  end

  def test_from_title_empty
    slug = @generator.from_title("")
    assert_equal "task", slug
  end

  def test_from_title_nil
    slug = @generator.from_title(nil)
    assert_equal "task", slug
  end

  def test_from_task_id_numeric
    slug = @generator.from_task_id("081")
    assert_equal "task-081", slug
  end

  def test_from_task_id_full
    slug = @generator.from_task_id("task.081")
    assert_equal "task-081", slug
  end

  def test_from_task_id_with_version
    slug = @generator.from_task_id("v.0.9.0+081")
    assert_equal "task-081", slug
  end

  def test_combined
    slug = @generator.combined("081", "Fix authentication bug")
    assert_equal "081-fix-authentication-bug", slug
  end

  def test_combined_with_long_title
    slug = @generator.combined("081", "This is a very long title that should be truncated properly when combined with task ID", max_length: 50)
    assert slug.start_with?("081-")
    assert slug.length <= 50
  end

  def test_sanitize_basic
    slug = @generator.sanitize("valid-branch-name")
    assert_equal "valid-branch-name", slug
  end

  def test_sanitize_with_special_characters
    slug = @generator.sanitize("invalid@branch#name")
    assert_equal "invalid-branch-name", slug
  end

  def test_sanitize_with_separators
    slug = @generator.sanitize("test/branch\\name")
    assert_equal "test-branch-name", slug
  end

  def test_sanitize_empty
    slug = @generator.sanitize("")
    assert_equal "task", slug
  end

  def test_valid_branch_name
    assert @generator.valid?("valid-branch-name")
    assert @generator.valid?("task-081")
    assert @generator.valid?("feature-auth")
  end

  def test_invalid_branch_name
    refute @generator.valid?("branch@invalid")
    refute @generator.valid?("branch with spaces")
    refute @generator.valid?("HEAD")
    refute @generator.valid?("branch..name")
    refute @generator.valid?("branch.name.")  # ends with dot
  end

  def test_valid_branch_name_empty
    refute @generator.valid?("")
    refute @generator.valid?(nil)
  end

  def test_valid_branch_name_too_long
    long_name = "a" * 256
    refute @generator.valid?(long_name)
  end

  def test_from_title_preserves_meaning
    slug = @generator.from_title("Add user authentication feature")
    assert_includes slug, "add"
    assert_includes slug, "user"
    assert_includes slug, "authentication"
    assert_includes slug, "feature"
  end

  def test_from_title_handles_multiple_spaces
    slug = @generator.from_title("Fix   multiple   spaces")
    assert_equal "fix-multiple-spaces", slug
  end

  def test_from_title_handles_underscores
    slug = @generator.from_title("fix_underscore_separation")
    assert_equal "fix-underscore-separation", slug
  end

  def test_custom_max_length
    slug = @generator.from_title("This is a test title", max_length: 20)
    assert slug.length <= 20
    refute slug.end_with?("-")  # Should not end with hyphen after truncation
  end

  def test_custom_fallback
    slug = @generator.from_title("", fallback: "custom")
    assert_equal "custom", slug
  end
end
