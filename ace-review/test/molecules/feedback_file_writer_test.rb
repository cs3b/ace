# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"

class FeedbackFileWriterTest < AceReviewTest
  def setup
    @temp_dir = Dir.mktmpdir("feedback-writer-test")
    @writer = Ace::Review::Molecules::FeedbackFileWriter.new
    @valid_item = Ace::Review::Models::FeedbackItem.new(
      id: "8o7abc",
      title: "Missing error handling",
      files: ["src/handlers/user.rb:42-55", "src/db/query.rb:10"],
      reviewer: "google:gemini-2.5-flash",
      status: "pending",
      priority: "high",
      finding: "The error handling is incomplete.",
      context: "This could cause crashes in production.",
      research: "Verified by static analysis.",
      resolution: nil
    )
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
  end

  # ============================================================================
  # Basic write tests
  # ============================================================================

  def test_write_creates_file
    result = @writer.write(@valid_item, @temp_dir)

    assert result[:success], "Expected write to succeed: #{result[:error]}"
    assert File.exist?(result[:path]), "Expected file to exist"
  end

  def test_write_returns_correct_path
    result = @writer.write(@valid_item, @temp_dir)

    assert result[:success]
    assert_match(/8o7abc-missing-error-handling\.s\.md$/, result[:path])
  end

  def test_write_file_contains_yaml_frontmatter
    result = @writer.write(@valid_item, @temp_dir)

    content = File.read(result[:path])
    assert_match(/\A---\n/, content, "Expected file to start with YAML frontmatter delimiter")
    assert_match(/\n---\n/, content, "Expected closing YAML frontmatter delimiter")
  end

  def test_write_file_contains_correct_frontmatter_fields
    result = @writer.write(@valid_item, @temp_dir)

    content = File.read(result[:path])

    # Check all frontmatter fields
    assert_match(/^id: 8o7abc$/, content)
    assert_match(/^title: Missing error handling$/, content)
    assert_match(/^reviewer: google:gemini-2.5-flash$/, content)
    assert_match(/^status: pending$/, content)
    assert_match(/^priority: high$/, content)
    assert_match(/- src\/handlers\/user\.rb:42-55/, content)
    assert_match(/- src\/db\/query\.rb:10/, content)
  end

  def test_write_file_contains_markdown_sections
    result = @writer.write(@valid_item, @temp_dir)

    content = File.read(result[:path])

    assert_includes content, "## Finding"
    assert_includes content, "The error handling is incomplete."
    assert_includes content, "## Context"
    assert_includes content, "This could cause crashes in production."
    assert_includes content, "## Research"
    assert_includes content, "Verified by static analysis."
  end

  def test_write_file_omits_empty_sections
    item = Ace::Review::Models::FeedbackItem.new(
      id: "xyz123",
      title: "Simple finding",
      reviewer: "test",
      finding: "Just a finding"
    )

    result = @writer.write(item, @temp_dir)
    content = File.read(result[:path])

    assert_includes content, "## Finding"
    refute_includes content, "## Context"
    refute_includes content, "## Research"
    refute_includes content, "## Resolution"
  end

  # ============================================================================
  # Validation tests
  # ============================================================================

  def test_write_fails_with_nil_feedback_item
    result = @writer.write(nil, @temp_dir)

    refute result[:success]
    assert_includes result[:error], "feedback_item is required"
  end

  def test_write_fails_with_nil_directory
    result = @writer.write(@valid_item, nil)

    refute result[:success]
    assert_includes result[:error], "directory is required"
  end

  def test_write_fails_with_empty_directory
    result = @writer.write(@valid_item, "")

    refute result[:success]
    assert_includes result[:error], "directory is required"
  end

  def test_write_fails_with_nonexistent_directory
    result = @writer.write(@valid_item, "/nonexistent/path")

    refute result[:success]
    assert_includes result[:error], "directory does not exist"
  end

  def test_write_fails_with_non_feedback_item
    result = @writer.write("not a feedback item", @temp_dir)

    refute result[:success]
    assert_includes result[:error], "must be a FeedbackItem"
  end

  def test_write_fails_when_id_missing
    # Create item with nil id by bypassing validation
    item = Ace::Review::Models::FeedbackItem.new(
      id: "",
      title: "Test",
      reviewer: "test",
      finding: "test"
    )

    result = @writer.write(item, @temp_dir)

    refute result[:success]
    assert_includes result[:error], "feedback_item.id is required"
  end

  def test_write_fails_when_title_missing
    item = Ace::Review::Models::FeedbackItem.new(
      id: "abc123",
      title: "",
      reviewer: "test",
      finding: "test"
    )

    result = @writer.write(item, @temp_dir)

    refute result[:success]
    assert_includes result[:error], "feedback_item.title is required"
  end

  # ============================================================================
  # Atomic write tests
  # ============================================================================

  def test_write_is_atomic_no_partial_files
    # Write a file
    result = @writer.write(@valid_item, @temp_dir)
    assert result[:success]

    # Check that no temp files remain
    temp_files = Dir.glob(File.join(@temp_dir, "*.tmp*"))
    assert_empty temp_files, "Expected no temp files to remain"
  end

  def test_write_overwrites_existing_file
    # Write first version
    result1 = @writer.write(@valid_item, @temp_dir)
    assert result1[:success]
    first_content = File.read(result1[:path])

    # Create modified item with same ID
    modified_item = @valid_item.dup_with(status: "done", resolution: "Fixed it!")

    # Write second version
    result2 = @writer.write(modified_item, @temp_dir)
    assert result2[:success]
    second_content = File.read(result2[:path])

    # Content should be different
    refute_equal first_content, second_content
    assert_includes second_content, "status: done"
    assert_includes second_content, "## Resolution"
    assert_includes second_content, "Fixed it!"
  end

  # ============================================================================
  # Concurrent write tests
  # ============================================================================

  def test_concurrent_writes_succeed
    items = 5.times.map do |i|
      Ace::Review::Models::FeedbackItem.new(
        id: "item#{i.to_s.rjust(2, "0")}",
        title: "Concurrent test item #{i}",
        reviewer: "test",
        finding: "Finding #{i}"
      )
    end

    threads = items.map do |item|
      Thread.new do
        writer = Ace::Review::Molecules::FeedbackFileWriter.new
        writer.write(item, @temp_dir)
      end
    end

    results = threads.map(&:value)

    # All writes should succeed
    assert results.all? { |r| r[:success] }, "Expected all concurrent writes to succeed"

    # All files should exist
    items.each do |item|
      files = Dir.glob(File.join(@temp_dir, "#{item.id}-*.s.md"))
      assert_equal 1, files.length, "Expected exactly one file for item #{item.id}"
    end
  end

  def test_write_cleans_up_lock_file
    result = @writer.write(@valid_item, @temp_dir)

    assert result[:success], "Expected write to succeed: #{result[:error]}"

    lock_file = File.join(@temp_dir, ".feedback.lock")
    refute File.exist?(lock_file), "Expected lock file to be cleaned up after write"
  end

  def test_concurrent_writes_to_same_file_use_lock
    # Write same item multiple times concurrently
    threads = 3.times.map do
      Thread.new do
        writer = Ace::Review::Molecules::FeedbackFileWriter.new
        writer.write(@valid_item, @temp_dir)
      end
    end

    results = threads.map(&:value)

    # All writes should succeed (they coordinate via lock)
    assert results.all? { |r| r[:success] }, "Expected all concurrent writes to succeed"

    # Lock file should be cleaned up after all writes complete
    lock_file = File.join(@temp_dir, ".feedback.lock")
    refute File.exist?(lock_file), "Expected lock file to be cleaned up after concurrent writes"
  end

  # ============================================================================
  # Filename generation tests
  # ============================================================================

  def test_filename_uses_id_and_slug
    item = Ace::Review::Models::FeedbackItem.new(
      id: "abc123",
      title: "SQL Injection in User Input Handler",
      reviewer: "test",
      finding: "test"
    )

    result = @writer.write(item, @temp_dir)

    # Slug should be lowercase, hyphenated
    assert_match(/^abc123-sql-injection-in-user-input-handler\.s\.md$/, File.basename(result[:path]))
  end

  def test_filename_handles_special_characters_in_title
    item = Ace::Review::Models::FeedbackItem.new(
      id: "xyz789",
      title: "Fix bug in caf module (urgent!)",
      reviewer: "test",
      finding: "test"
    )

    result = @writer.write(item, @temp_dir)

    # Special characters should be removed/normalized
    filename = File.basename(result[:path])
    assert_match(/^xyz789-/, filename)
    refute_includes filename, "("
    refute_includes filename, ")"
    refute_includes filename, "!"
  end

  def test_filename_truncates_long_titles
    item = Ace::Review::Models::FeedbackItem.new(
      id: "long01",
      title: "A very long title that exceeds the forty character maximum length limit for slugs",
      reviewer: "test",
      finding: "test"
    )

    result = @writer.write(item, @temp_dir)

    filename = File.basename(result[:path])
    # Filename should be: id (6) + hyphen (1) + slug (max 40) + extension (5) = max 52 chars
    # But slug generator truncates to 40 chars
    assert filename.length <= 52, "Filename too long: #{filename}"
  end
end
