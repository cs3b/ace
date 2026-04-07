# frozen_string_literal: true

require "test_helper"
require "ace/task/molecules/task_frontmatter_validator"

class TaskFrontmatterValidatorTest < AceTaskTestCase
  Validator = Ace::Task::Molecules::TaskFrontmatterValidator

  # --- delimiter checks ---

  def test_validates_missing_opening_delimiter
    with_tasks_dir do |root|
      file = write_task_file(root, "no-open", <<~CONTENT)
        id: 8pp.t.q7w
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
    with_tasks_dir do |root|
      file = write_task_file(root, "no-close", <<~CONTENT)
        ---
        id: 8pp.t.q7w
        status: pending
        title: Test

        # Content
      CONTENT

      issues = Validator.validate(file)
      assert issues.any? { |i| i[:message].include?("Missing closing") }
    end
  end

  def test_valid_frontmatter_no_errors
    with_tasks_dir do |root|
      file = write_task_file(root, "valid", <<~CONTENT)
        ---
        id: 8pp.t.q7w
        status: pending
        title: Test task
        tags: [ux]
        created_at: 2026-02-28 12:00:00
        ---

        # Test task
      CONTENT

      issues = Validator.validate(file)
      errors = issues.select { |i| i[:type] == :error }
      assert_empty errors
    end
  end

  # --- required fields ---

  def test_validates_missing_id
    with_tasks_dir do |root|
      file = write_task_file(root, "no-id", <<~CONTENT)
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
    with_tasks_dir do |root|
      file = write_task_file(root, "no-status", <<~CONTENT)
        ---
        id: 8pp.t.q7w
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
    with_tasks_dir do |root|
      file = write_task_file(root, "bad-status", <<~CONTENT)
        ---
        id: 8pp.t.q7w
        status: obsolete
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
    with_tasks_dir do |root|
      file = write_task_file(root, "bad-id", <<~CONTENT)
        ---
        id: not-valid-id
        status: pending
        title: Test
        tags: []
        created_at: 2026-02-28 12:00:00
        ---
      CONTENT

      issues = Validator.validate(file)
      assert issues.any? { |i| i[:message].include?("Invalid task ID format") }
    end
  end

  def test_validates_tags_not_array
    with_tasks_dir do |root|
      file = write_task_file(root, "bad-tags", <<~CONTENT)
        ---
        id: 8pp.t.q7w
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
    with_tasks_dir do |root|
      file = write_task_file(root, "no-tags", <<~CONTENT)
        ---
        id: 8pp.t.q7w
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
    with_tasks_dir do |root|
      file = write_task_file(root, "no-date", <<~CONTENT)
        ---
        id: 8pp.t.q7w
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
    with_tasks_dir do |root|
      file = write_task_file(root, "done-root", <<~CONTENT)
        ---
        id: 8pp.t.q7w
        status: done
        title: Done task
        tags: []
        created_at: 2026-02-28 12:00:00
        ---
      CONTENT

      issues = Validator.validate(file, special_folder: nil)
      assert issues.any? { |i| i[:message].include?("not in _archive") }
    end
  end

  def test_validates_scope_archive_non_terminal
    with_tasks_dir do |root|
      file = write_task_file(root, "pending-archive", <<~CONTENT)
        ---
        id: 8pp.t.q7w
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

  # --- title length ---

  def test_warns_on_long_title
    with_tasks_dir do |root|
      long_title = "A" * 81
      file = write_task_file(root, "long-title", <<~CONTENT)
        ---
        id: 8pp.t.q7w
        status: pending
        title: #{long_title}
        tags: []
        created_at: 2026-02-28 12:00:00
        ---
      CONTENT

      issues = Validator.validate(file)
      assert issues.any? { |i| i[:type] == :warning && i[:message].include?("Title exceeds 80 characters") }
    end
  end

  def test_no_warning_for_short_title
    with_tasks_dir do |root|
      file = write_task_file(root, "ok-title", <<~CONTENT)
        ---
        id: 8pp.t.q7w
        status: pending
        title: Short title
        tags: []
        created_at: 2026-02-28 12:00:00
        ---
      CONTENT

      issues = Validator.validate(file)
      refute issues.any? { |i| i[:message].include?("Title exceeds") }
    end
  end

  # --- github linkage fields ---

  def test_valid_github_issues_array
    with_tasks_dir do |root|
      file = write_task_file(root, "github-valid", <<~CONTENT)
        ---
        id: 8pp.t.q7w
        status: pending
        title: Linked task
        tags: []
        created_at: 2026-02-28 12:00:00
        github:
          issues: [276, 278]
        ---
      CONTENT

      issues = Validator.validate(file)
      refute issues.any? { |i| i[:message].include?("github.issues") }
    end
  end

  def test_invalid_github_issues_type
    with_tasks_dir do |root|
      file = write_task_file(root, "github-type", <<~CONTENT)
        ---
        id: 8pp.t.q7w
        status: pending
        title: Linked task
        tags: []
        created_at: 2026-02-28 12:00:00
        github:
          issues: 276
        ---
      CONTENT

      issues = Validator.validate(file)
      assert issues.any? { |i| i[:message].include?("github.issues") && i[:type] == :error }
    end
  end

  def test_invalid_github_issue_value
    with_tasks_dir do |root|
      file = write_task_file(root, "github-value", <<~CONTENT)
        ---
        id: 8pp.t.q7w
        status: pending
        title: Linked task
        tags: []
        created_at: 2026-02-28 12:00:00
        github:
          issues: [276, "abc"]
        ---
      CONTENT

      issues = Validator.validate(file)
      assert issues.any? { |i| i[:message].include?("Invalid GitHub issue ID") && i[:type] == :error }
    end
  end

  # --- nonexistent file ---

  def test_nonexistent_file
    issues = Validator.validate("/tmp/nonexistent-task-file.md")
    assert issues.any? { |i| i[:type] == :error && i[:message].include?("does not exist") }
  end

  private

  def write_task_file(root, name, content)
    dir = File.join(root, "8pp.t.q7w-#{name}")
    FileUtils.mkdir_p(dir)
    file = File.join(dir, "8pp.t.q7w-#{name}.s.md")
    File.write(file, content)
    file
  end
end
