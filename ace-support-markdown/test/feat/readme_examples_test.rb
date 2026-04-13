# frozen_string_literal: true

require_relative "../test_helper"
require "tempfile"
require "fileutils"

# Test that validates all code examples in README.md
# This ensures documentation stays in sync with the actual API
class ReadmeExamplesTest < Minitest::Test
  include TestHelpers

  def setup
    @readme_path = File.expand_path("../../README.md", __dir__)
    @temp_dir = Dir.mktmpdir("readme_examples_test")
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir) if File.exist?(@temp_dir)
  end

  # Test that README examples use correct API patterns
  def test_example_1_task_status_fix
    # Create test fixture
    task_content = <<~MARKDOWN
      ---
      id: task.042
      status: pending
      priority: high
      ---

      # Implement Feature

      ## Description
      Task description here
    MARKDOWN

    file_path = File.join(@temp_dir, "task.042.md")
    File.write(file_path, task_content)

    # Execute example code pattern
    editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(file_path)
    editor.update_frontmatter("status" => "done")
    result = editor.save!(backup: true, validate_before: true)

    # Verify expected behavior
    assert result[:success], "Example 1 should succeed"
    assert File.exist?(file_path), "Original file should exist"
    assert result[:backup_path], "Backup should be created"
    assert File.exist?(result[:backup_path]), "Backup file should exist"

    # Verify content was updated
    updated_content = File.read(file_path)
    assert_includes updated_content, "status: done", "Status should be updated to 'done'"
  end

  def test_example_2_documentation_updates
    # Create test fixtures
    docs = []
    3.times do |i|
      doc_content = <<~MARKDOWN
        ---
        id: doc.00#{i}
        update:
          last-updated: '2024-01-01'
          frequency: daily
        metadata:
          version: '0.1.0'
        ---

        # Documentation #{i}

        Content here
      MARKDOWN

      file_path = File.join(@temp_dir, "doc.00#{i}.md")
      File.write(file_path, doc_content)
      docs << file_path
    end

    # Execute example pattern
    results = {success: 0, failed: 0, errors: []}
    updates = {frequency: "weekly", version: "1.0"}

    docs.each do |doc_path|
      editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(doc_path)

      processed_updates = {
        "update.last-updated" => "today",
        "update.frequency" => updates[:frequency],
        "metadata.version" => updates[:version]
      }

      editor.update_frontmatter(processed_updates)
      result = editor.save!(backup: true, validate_before: false)

      if result[:success]
        results[:success] += 1
      else
        results[:failed] += 1
        results[:errors] << {path: doc_path, errors: result[:errors]}
      end
    rescue => e
      results[:failed] += 1
      results[:errors] << {path: doc_path, errors: [e.message]}
    end

    # Verify bulk operation succeeded
    assert_equal 3, results[:success], "All 3 documents should be updated"
    assert_equal 0, results[:failed], "No failures expected"
    assert_empty results[:errors], "No errors expected"
  end

  def test_example_4_safe_file_writing_with_validation
    # Test custom validator pattern from Example 4
    template = <<~TEMPLATE
      ---
      id: %{task_id}
      status: draft
      created_at: %{created_at}
      ---

      # %{title}

      ## Objective

      [Task objective here]

      ## Acceptance Criteria

      - [ ] Criterion 1
      - [ ] Criterion 2
    TEMPLATE

    content = template % {
      task_id: "v.1.0+task.080",
      title: "Test Task",
      created_at: Time.now.strftime("%Y-%m-%d")
    }

    file_path = File.join(@temp_dir, "task.080.md")

    # Custom validator from example
    validator = ->(content) {
      errors = []
      errors << "Missing '## Objective' section" unless content.include?("## Objective")
      errors << "Missing '## Acceptance Criteria' section" unless content.include?("## Acceptance Criteria")
      errors << "Task ID must match format" unless content.match?(/id: v\.\d+\.\d+\+task\.\d+/)
      errors
    }

    # Execute example pattern
    result = Ace::Support::Markdown::Organisms::SafeFileWriter.write(
      file_path,
      content,
      backup: true,
      validate: true,
      validator: validator
    )

    # Verify validation succeeded
    assert result[:success], "File write with custom validation should succeed"
    assert File.exist?(file_path), "File should be created"

    written_content = File.read(file_path)
    assert_includes written_content, "## Objective", "Should contain Objective section"
    assert_includes written_content, "## Acceptance Criteria", "Should contain Acceptance Criteria"
  end

  def test_example_5_error_handling_pattern
    # Create invalid test file (missing required fields)
    task_content = <<~MARKDOWN
      ---
      id: task.042
      ---

      # Test Task
    MARKDOWN

    file_path = File.join(@temp_dir, "task.042.md")
    File.write(file_path, task_content)

    # Test error handling pattern from Example 5
    editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(file_path)

    begin
      # Pre-flight validation should fail (missing status field)
      valid = editor.valid?(rules: {required_fields: ["id", "status"]})
      refute valid, "Document should be invalid without status field"

      # This simulates the early return in the example
      result = {success: false, error: "Document invalid before update"}

      assert_equal false, result[:success]
      assert_includes result[:error], "invalid"
    end
  end

  def test_example_6_batch_operations
    # Create test fixtures
    task_files = []
    5.times do |i|
      task_content = <<~MARKDOWN
        ---
        id: task.#{100 + i}
        status: pending
        priority: medium
        ---

        # Task #{100 + i}

        Content here
      MARKDOWN

      file_path = File.join(@temp_dir, "task.#{100 + i}.md")
      File.write(file_path, task_content)
      task_files << file_path
    end

    # Execute batch operation pattern
    results = {
      total: task_files.length,
      succeeded: 0,
      failed: 0,
      errors: [],
      backups: []
    }

    updates = {"updated_at" => "today", "version" => "1.0"}

    task_files.each do |file_path|
      editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(file_path)
      editor.update_frontmatter(updates)

      result = editor.save!(backup: true, validate_before: true)

      if result[:success]
        results[:succeeded] += 1
        results[:backups] << result[:backup_path]
      else
        results[:failed] += 1
        results[:errors] << {
          file: file_path,
          errors: result[:errors]
        }
      end
    rescue => e
      results[:failed] += 1
      results[:errors] << {
        file: file_path,
        errors: [e.message]
      }
    end

    # Verify batch operation
    assert_equal 5, results[:total], "Should process 5 files"
    assert_equal 5, results[:succeeded], "All should succeed"
    assert_equal 0, results[:failed], "No failures expected"
    assert_equal 5, results[:backups].length, "Should create 5 backups"
    assert_empty results[:errors], "No errors expected"

    # Verify backups exist
    results[:backups].each do |backup_path|
      assert File.exist?(backup_path), "Backup file should exist: #{backup_path}"
    end
  end

  def test_document_editor_api_as_shown_in_quick_start
    # Test Quick Start example from README
    task_content = sample_markdown

    file_path = File.join(@temp_dir, "task.md")
    File.write(file_path, task_content)

    # Quick Start example pattern
    editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(file_path)
    editor.update_frontmatter({"status" => "done", "updated_at" => "today"})
    editor.replace_section("References", "- New reference")
    result = editor.save!(backup: true, validate_before: true)

    # Verify
    assert result[:success], "Quick Start example should work"
    assert File.exist?(file_path)

    updated_content = File.read(file_path)
    assert_includes updated_content, "status: done"
    assert_includes updated_content, "- New reference"
  end

  def test_document_builder_api_as_shown_in_quick_start
    # Test DocumentBuilder pattern from Quick Start
    builder = Ace::Support::Markdown::Molecules::DocumentBuilder.new
    doc = builder
      .frontmatter({"id" => "task.001", "status" => "draft"})
      .title("My Task")
      .add_section(heading: "Description", content: "Task details here")
      .build

    markdown = doc.to_markdown

    # Verify structure
    assert_includes markdown, "id: task.001"
    assert_includes markdown, "status: draft"
    assert_includes markdown, "# My Task"
    assert_includes markdown, "## Description"
    assert_includes markdown, "Task details here"
  end

  def test_api_documentation_examples
    # Test examples from API Documentation section
    file_path = File.join(@temp_dir, "test.md")
    File.write(file_path, sample_markdown)

    editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(file_path)

    # Frontmatter operations
    editor.update_frontmatter({"status" => "done", "priority" => "high"})
    editor.set_field("estimate", "2h")

    # Section operations
    editor.replace_section("References", "New content")
    editor.append_to_section("Section 1", "\n\nAdditional content")

    # Save with validation rules
    result = editor.save!(
      backup: true,
      validate_before: true,
      rules: {
        required_fields: ["id", "status"],
        enums: {"status" => ["pending", "done"]}
      }
    )

    # Verify all operations succeeded
    assert result[:success], "API documentation example should work"
    assert result[:backup_path], "Should create backup"

    updated_content = File.read(file_path)
    assert_includes updated_content, "status: done"
    assert_includes updated_content, "priority: high"
    assert_includes updated_content, "estimate: 2h"
    assert_includes updated_content, "New content"
  end
end
