# frozen_string_literal: true

require "test_helper"

class SlugGeneratorTest < AceGitWorktreeTestCase
  def setup
    @generator = Ace::Git::Worktree::Atoms::SlugGenerator
  end

  def test_generate_basic_slug
    assert_equal "hello-world", @generator.generate("Hello World")
    assert_equal "fix-authentication-bug", @generator.generate("Fix Authentication Bug")
  end

  def test_generate_removes_special_characters
    assert_equal "test-123", @generator.generate("Test #123")
    assert_equal "hello-world", @generator.generate("Hello, World!")
    assert_equal "a-b-c", @generator.generate("a/b\\c")
  end

  def test_generate_handles_empty_input
    assert_equal "", @generator.generate(nil)
    assert_equal "", @generator.generate("")
    assert_equal "", @generator.generate("   ")
  end

  def test_generate_respects_max_length
    long_text = "This is a very long title that should be truncated"
    slug = @generator.generate(long_text, max_length: 20)
    assert slug.length <= 20
    assert_equal "this-is-a-very-long", slug
  end

  def test_branch_name_generation
    assert_equal "fix-bug", @generator.branch_name("Fix Bug")
    assert_equal "081-fix-bug", @generator.branch_name("Fix Bug", prefix: "081")
  end

  def test_valid_branch_name
    assert @generator.valid_branch_name?("feature-branch")
    assert @generator.valid_branch_name?("081-fix-bug")

    refute @generator.valid_branch_name?(".hidden")
    refute @generator.valid_branch_name?("-start-dash")
    refute @generator.valid_branch_name?("has space")
    refute @generator.valid_branch_name?("HEAD")
    refute @generator.valid_branch_name?("branch.lock")
  end

  def test_format_template
    template = "task.{id}-{slug}"
    variables = { id: "081", slug: "fix-bug" }
    assert_equal "task.081-fix-bug", @generator.format_template(template, variables)
  end

  def test_extract_variables
    template = "{id}-{slug}-{release}"
    variables = @generator.extract_variables(template)
    assert_equal %w[id slug release], variables
  end

  def test_sanitize_path
    assert_equal "hello-world", @generator.sanitize_path("hello/world")
    assert_equal "test-file", @generator.sanitize_path("test:file")
    assert_equal "no-spaces", @generator.sanitize_path("no spaces")
  end
end