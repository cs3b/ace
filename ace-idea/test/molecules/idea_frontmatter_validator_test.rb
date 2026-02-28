# frozen_string_literal: true

require "test_helper"
require "ace/idea/molecules/idea_frontmatter_validator"

class IdeaFrontmatterValidatorTest < AceIdeaTestCase
  Validator = Ace::Idea::Molecules::IdeaFrontmatterValidator

  # --- delimiter checks ---

  def test_validates_missing_opening_delimiter
    with_ideas_dir do |root|
      file = write_idea_file(root, "no-open", <<~CONTENT)
        id: abc123
        status: pending
        title: Test
        ---

        # Content
      CONTENT

      issues = Validator.validate(file)
      assert issues.any? { |i| i[:message].include?("Missing opening") }
    end
  end

  def test_validates_missing_closing_delimiter
    with_ideas_dir do |root|
      file = write_idea_file(root, "no-close", <<~CONTENT)
        ---
        id: abc123
        status: pending
        title: Test

        # Content
      CONTENT

      issues = Validator.validate(file)
      assert issues.any? { |i| i[:message].include?("Missing closing") }
    end
  end

  def test_valid_frontmatter_no_errors
    with_ideas_dir do |root|
      file = write_idea_file(root, "valid", <<~CONTENT)
        ---
        id: abc123
        status: pending
        title: Test idea
        tags: [ux]
        created_at: 2026-02-28 12:00:00
        ---

        # Test idea
      CONTENT

      issues = Validator.validate(file)
      errors = issues.select { |i| i[:type] == :error }
      assert_empty errors
    end
  end

  # --- required fields ---

  def test_validates_missing_id
    with_ideas_dir do |root|
      file = write_idea_file(root, "no-id", <<~CONTENT)
        ---
        status: pending
        title: Test
        tags: []
        created_at: 2026-02-28 12:00:00
        ---
      CONTENT

      issues = Validator.validate(file)
      assert issues.any? { |i| i[:message].include?("Missing required field: id") }
    end
  end

  def test_validates_missing_status
    with_ideas_dir do |root|
      file = write_idea_file(root, "no-status", <<~CONTENT)
        ---
        id: abc123
        title: Test
        tags: []
        created_at: 2026-02-28 12:00:00
        ---
      CONTENT

      issues = Validator.validate(file)
      assert issues.any? { |i| i[:message].include?("Missing required field: status") }
    end
  end

  # --- field values ---

  def test_validates_invalid_status_value
    with_ideas_dir do |root|
      file = write_idea_file(root, "bad-status", <<~CONTENT)
        ---
        id: abc123
        status: draft
        title: Test
        tags: []
        created_at: 2026-02-28 12:00:00
        ---
      CONTENT

      issues = Validator.validate(file)
      assert issues.any? { |i| i[:message].include?("Invalid status value") }
    end
  end

  def test_validates_invalid_id_format
    with_ideas_dir do |root|
      file = write_idea_file(root, "bad-id", <<~CONTENT)
        ---
        id: not-valid-id
        status: pending
        title: Test
        tags: []
        created_at: 2026-02-28 12:00:00
        ---
      CONTENT

      issues = Validator.validate(file)
      assert issues.any? { |i| i[:message].include?("Invalid idea ID format") }
    end
  end

  def test_validates_tags_not_array
    with_ideas_dir do |root|
      file = write_idea_file(root, "bad-tags", <<~CONTENT)
        ---
        id: abc123
        status: pending
        title: Test
        tags: "not-an-array"
        created_at: 2026-02-28 12:00:00
        ---
      CONTENT

      issues = Validator.validate(file)
      assert issues.any? { |i| i[:message].include?("not an array") }
    end
  end

  # --- recommended fields ---

  def test_validates_missing_tags
    with_ideas_dir do |root|
      file = write_idea_file(root, "no-tags", <<~CONTENT)
        ---
        id: abc123
        status: pending
        title: Test
        created_at: 2026-02-28 12:00:00
        ---
      CONTENT

      issues = Validator.validate(file)
      assert issues.any? { |i| i[:message].include?("Missing recommended field: tags") }
    end
  end

  def test_validates_missing_created_at
    with_ideas_dir do |root|
      file = write_idea_file(root, "no-date", <<~CONTENT)
        ---
        id: abc123
        status: pending
        title: Test
        tags: []
        ---
      CONTENT

      issues = Validator.validate(file)
      assert issues.any? { |i| i[:message].include?("Missing recommended field: created_at") }
    end
  end

  # --- scope consistency ---

  def test_validates_scope_done_not_in_archive
    with_ideas_dir do |root|
      file = write_idea_file(root, "done-root", <<~CONTENT)
        ---
        id: abc123
        status: done
        title: Done idea
        tags: []
        created_at: 2026-02-28 12:00:00
        ---
      CONTENT

      issues = Validator.validate(file, special_folder: nil)
      assert issues.any? { |i| i[:message].include?("not in _archive") }
    end
  end

  def test_validates_scope_archive_non_terminal
    with_ideas_dir do |root|
      file = write_idea_file(root, "pending-archive", <<~CONTENT)
        ---
        id: abc123
        status: pending
        title: Pending in archive
        tags: []
        created_at: 2026-02-28 12:00:00
        ---
      CONTENT

      issues = Validator.validate(file, special_folder: "_archive")
      assert issues.any? { |i| i[:message].include?("in _archive/ but status") }
    end
  end

  # --- nonexistent file ---

  def test_nonexistent_file
    issues = Validator.validate("/tmp/nonexistent-idea-file.md")
    assert issues.any? { |i| i[:type] == :error && i[:message].include?("does not exist") }
  end

  private

  def write_idea_file(root, name, content)
    dir = File.join(root, "abc123-#{name}")
    FileUtils.mkdir_p(dir)
    file = File.join(dir, "abc123-#{name}.idea.s.md")
    File.write(file, content)
    file
  end
end
