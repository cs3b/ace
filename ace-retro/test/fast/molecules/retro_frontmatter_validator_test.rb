# frozen_string_literal: true

require "test_helper"
require "ace/retro/molecules/retro_frontmatter_validator"

class RetroFrontmatterValidatorTest < AceRetroTestCase
  Validator = Ace::Retro::Molecules::RetroFrontmatterValidator

  def test_valid_retro_file_has_no_issues
    with_retros_dir do |root|
      dir = create_retro_fixture(root, id: "abc123", slug: "good-retro", status: "active", tags: ["test"])
      file = Dir.glob(File.join(dir, "*.retro.md")).first

      issues = Validator.validate(file)
      errors = issues.select { |i| i[:type] == :error }
      assert_empty errors
    end
  end

  def test_missing_file_returns_error
    issues = Validator.validate("/tmp/nonexistent-#{rand(99999)}.retro.md")
    assert_equal 1, issues.size
    assert_equal :error, issues.first[:type]
    assert_match(/does not exist/, issues.first[:message])
  end

  def test_missing_opening_delimiter
    with_retros_dir do |root|
      dir = File.join(root, "abc123-no-open")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "abc123-no-open.retro.md"), "id: abc123\n---\n# Test")

      issues = Validator.validate(File.join(dir, "abc123-no-open.retro.md"))
      assert issues.any? { |i| i[:message].include?("Missing opening") }
    end
  end

  def test_missing_closing_delimiter
    with_retros_dir do |root|
      dir = File.join(root, "abc123-no-close")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "abc123-no-close.retro.md"), "---\nid: abc123\ntitle: Test\n")

      issues = Validator.validate(File.join(dir, "abc123-no-close.retro.md"))
      assert issues.any? { |i| i[:message].include?("Missing closing") }
    end
  end

  def test_missing_required_fields
    with_retros_dir do |root|
      dir = File.join(root, "abc123-missing")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "abc123-missing.retro.md"), <<~CONTENT)
        ---
        title: Missing fields
        ---
      CONTENT

      issues = Validator.validate(File.join(dir, "abc123-missing.retro.md"))
      messages = issues.map { |i| i[:message] }
      assert messages.any? { |m| m.include?("Missing required field: id") }
      assert messages.any? { |m| m.include?("Missing required field: status") }
    end
  end

  def test_invalid_status_value
    with_retros_dir do |root|
      dir = File.join(root, "abc123-bad-status")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "abc123-bad-status.retro.md"), <<~CONTENT)
        ---
        id: abc123
        title: Bad status
        type: standard
        status: draft
        created_at: 2026-01-01 00:00:00
        ---
      CONTENT

      issues = Validator.validate(File.join(dir, "abc123-bad-status.retro.md"))
      assert issues.any? { |i| i[:message].include?("Invalid status value") }
    end
  end

  def test_invalid_id_format
    with_retros_dir do |root|
      dir = File.join(root, "abc123-bad-id")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "abc123-bad-id.retro.md"), <<~CONTENT)
        ---
        id: INVALID
        title: Bad ID
        type: standard
        status: active
        created_at: 2026-01-01 00:00:00
        ---
      CONTENT

      issues = Validator.validate(File.join(dir, "abc123-bad-id.retro.md"))
      assert issues.any? { |i| i[:message].include?("Invalid retro ID format") }
    end
  end

  def test_tags_not_array
    with_retros_dir do |root|
      dir = File.join(root, "abc123-bad-tags")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "abc123-bad-tags.retro.md"), <<~CONTENT)
        ---
        id: abc123
        title: Bad tags
        type: standard
        status: active
        created_at: 2026-01-01 00:00:00
        tags: "not-an-array"
        ---
      CONTENT

      issues = Validator.validate(File.join(dir, "abc123-bad-tags.retro.md"))
      assert issues.any? { |i| i[:message].include?("tags' is not an array") }
    end
  end

  def test_scope_consistency_check
    with_retros_dir do |root|
      dir = File.join(root, "abc123-done-root")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "abc123-done-root.retro.md"), <<~CONTENT)
        ---
        id: abc123
        title: Done root
        type: standard
        status: done
        created_at: 2026-01-01 00:00:00
        tags: []
        ---
      CONTENT

      issues = Validator.validate(File.join(dir, "abc123-done-root.retro.md"))
      assert issues.any? { |i| i[:message].include?("not in _archive") }
    end
  end
end
