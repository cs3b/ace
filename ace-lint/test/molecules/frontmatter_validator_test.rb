# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class Ace::Lint::Molecules::FrontmatterValidatorTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir("frontmatter-validator-test")
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir) if @temp_dir
  end

  def test_readme_without_frontmatter_is_allowed_by_default
    path = "ace-docs/README.md"
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "# README\n")

    result = Ace::Lint::Molecules::FrontmatterValidator.lint(path)

    assert result.success?
    assert_empty result.errors
  end

  def test_non_matching_markdown_without_frontmatter_fails
    path = "ace-docs/docs/usage.md"
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "# Usage\n")

    result = Ace::Lint::Molecules::FrontmatterValidator.lint(path)

    refute result.success?
    assert_match(/No frontmatter found/, result.errors.first.message)
  end

  def test_custom_frontmatter_free_pattern_from_docs_config
    config_path = ".ace/docs/config.yml"
    FileUtils.mkdir_p(File.dirname(config_path))
    File.write(config_path, <<~YAML)
      frontmatter_free:
        - "**/CONTRIBUTING.md"
    YAML

    path = "ace-docs/CONTRIBUTING.md"
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "# Contributing\n")

    result = Ace::Lint::Molecules::FrontmatterValidator.lint(path)

    assert result.success?
  end

  def test_readme_with_frontmatter_still_validates_required_fields
    path = "ace-docs/README.md"
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, <<~MD)
      ---
      doc-type: user
      ---

      # README
    MD

    result = Ace::Lint::Molecules::FrontmatterValidator.lint(path)

    refute result.success?
    assert_equal "Missing required field: 'purpose'", result.errors.first.message
  end
end
