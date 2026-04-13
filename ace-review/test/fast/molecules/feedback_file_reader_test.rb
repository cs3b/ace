# frozen_string_literal: true

require "test_helper"
require "fileutils"

class FeedbackFileReaderTest < AceReviewTest
  def self.use_shared_temp_dir?
    true
  end

  def setup
    super
    @temp_dir = @test_dir
    @reader = Ace::Review::Molecules::FeedbackFileReader.new
    @writer = Ace::Review::Molecules::FeedbackFileWriter.new
  end

  # ============================================================================
  # Basic read tests
  # ============================================================================

  def test_read_returns_feedback_item
    create_feedback_file("8o7abc", "Missing error handling")
    file_path = File.join(@temp_dir, "8o7abc-missing-error-handling.s.md")

    result = @reader.read(file_path)

    assert result[:success], "Expected read to succeed: #{result[:error]}"
    assert_instance_of Ace::Review::Models::FeedbackItem, result[:feedback_item]
  end

  def test_read_parses_frontmatter_fields
    create_feedback_file("test01", "SQL Injection Bug",
      status: "pending",
      priority: "critical",
      reviewer: "google:gemini-2.5-flash")
    file_path = File.join(@temp_dir, "test01-sql-injection-bug.s.md")

    result = @reader.read(file_path)

    assert result[:success]
    item = result[:feedback_item]
    assert_equal "test01", item.id
    assert_equal "SQL Injection Bug", item.title
    assert_equal "pending", item.status
    assert_equal "critical", item.priority
    assert_equal "google:gemini-2.5-flash", item.reviewer
  end

  def test_read_parses_files_array
    create_feedback_file("files1", "Multi file issue",
      files: ["src/a.rb:10", "src/b.rb:20-30"])
    file_path = File.join(@temp_dir, "files1-multi-file-issue.s.md")

    result = @reader.read(file_path)

    assert result[:success]
    assert_equal ["src/a.rb:10", "src/b.rb:20-30"], result[:feedback_item].files
  end

  def test_read_parses_markdown_sections
    file_path = File.join(@temp_dir, "sections-test.s.md")
    File.write(file_path, <<~MD)
      ---
      id: sect01
      title: Section test
      status: draft
      priority: medium
      reviewer: test
      ---

      ## Finding
      This is the finding text.

      ## Context
      This is the context text.

      ## Research
      This is the research text.

      ## Resolution
      This is the resolution text.
    MD

    result = @reader.read(file_path)

    assert result[:success]
    item = result[:feedback_item]
    assert_equal "This is the finding text.", item.finding
    assert_equal "This is the context text.", item.context
    assert_equal "This is the research text.", item.research
    assert_equal "This is the resolution text.", item.resolution
  end

  def test_read_handles_multiline_sections
    file_path = File.join(@temp_dir, "multiline-test.s.md")
    File.write(file_path, <<~MD)
      ---
      id: multi1
      title: Multiline test
      status: draft
      priority: medium
      reviewer: test
      ---

      ## Finding
      Line one of finding.
      Line two of finding.

      More finding content.

      ## Context
      Context content.
    MD

    result = @reader.read(file_path)

    assert result[:success]
    finding = result[:feedback_item].finding
    assert_includes finding, "Line one of finding."
    assert_includes finding, "Line two of finding."
    assert_includes finding, "More finding content."
  end

  # ============================================================================
  # Roundtrip tests (write then read)
  # ============================================================================

  def test_roundtrip_preserves_all_fields
    original = Ace::Review::Models::FeedbackItem.new(
      id: "round1",
      title: "Roundtrip test item",
      files: ["src/test.rb:1-10", "src/other.rb:5"],
      reviewer: "claude:opus",
      status: "pending",
      priority: "high",
      finding: "The original finding.",
      context: "Important context.",
      research: "Verification research.",
      resolution: "How it was fixed."
    )

    # Write
    write_result = @writer.write(original, @temp_dir)
    assert write_result[:success], "Write failed: #{write_result[:error]}"

    # Read
    read_result = @reader.read(write_result[:path])
    assert read_result[:success], "Read failed: #{read_result[:error]}"

    restored = read_result[:feedback_item]
    assert_equal original.id, restored.id
    assert_equal original.title, restored.title
    assert_equal original.files, restored.files
    assert_equal original.reviewer, restored.reviewer
    assert_equal original.status, restored.status
    assert_equal original.priority, restored.priority
    assert_equal original.finding, restored.finding
    assert_equal original.context, restored.context
    assert_equal original.research, restored.research
    assert_equal original.resolution, restored.resolution
  end

  # ============================================================================
  # Error handling tests
  # ============================================================================

  def test_read_returns_error_for_missing_file
    result = @reader.read("/nonexistent/path/file.s.md")

    refute result[:success]
    assert_includes result[:error], "File not found"
  end

  def test_read_returns_error_for_nil_path
    result = @reader.read(nil)

    refute result[:success]
    assert_includes result[:error], "file_path is required"
  end

  def test_read_returns_error_for_empty_path
    result = @reader.read("")

    refute result[:success]
    assert_includes result[:error], "file_path is required"
  end

  def test_read_returns_error_for_missing_frontmatter
    file_path = File.join(@temp_dir, "no-frontmatter.s.md")
    File.write(file_path, "Just plain markdown without frontmatter.")

    result = @reader.read(file_path)

    refute result[:success]
    assert_includes result[:error], "Missing YAML frontmatter"
  end

  def test_read_returns_error_for_invalid_yaml
    file_path = File.join(@temp_dir, "bad-yaml.s.md")
    File.write(file_path, <<~MD)
      ---
      id: [unclosed bracket
      title: Bad yaml
      ---

      ## Finding
      Content
    MD

    result = @reader.read(file_path)

    refute result[:success]
    assert_includes result[:error], "YAML syntax error"
  end

  def test_read_returns_error_for_invalid_status
    file_path = File.join(@temp_dir, "bad-status.s.md")
    File.write(file_path, <<~MD)
      ---
      id: bad001
      title: Bad status
      status: invalid_status_value
      priority: medium
      reviewer: test
      ---

      ## Finding
      Content
    MD

    result = @reader.read(file_path)

    refute result[:success]
    assert_includes result[:error], "Invalid status"
  end

  def test_read_returns_error_for_invalid_priority
    file_path = File.join(@temp_dir, "bad-priority.s.md")
    File.write(file_path, <<~MD)
      ---
      id: bad002
      title: Bad priority
      status: draft
      priority: super_urgent
      reviewer: test
      ---

      ## Finding
      Content
    MD

    result = @reader.read(file_path)

    refute result[:success]
    assert_includes result[:error], "Invalid priority"
  end

  def test_read_handles_non_hash_yaml
    file_path = File.join(@temp_dir, "array-yaml.s.md")
    File.write(file_path, <<~MD)
      ---
      - item1
      - item2
      ---

      ## Finding
      Content
    MD

    result = @reader.read(file_path)

    refute result[:success]
    assert_includes result[:error], "expected Hash"
  end

  # ============================================================================
  # read_all tests
  # ============================================================================

  def test_read_all_returns_all_items
    create_feedback_file("all001", "First item")
    create_feedback_file("all002", "Second item")
    create_feedback_file("all003", "Third item")

    items = @reader.read_all(@temp_dir)

    assert_equal 3, items.length
    ids = items.map(&:id).sort
    assert_equal ["all001", "all002", "all003"], ids
  end

  def test_read_all_returns_empty_array_for_empty_directory
    items = @reader.read_all(@temp_dir)

    assert_equal [], items
  end

  def test_read_all_returns_empty_array_for_nonexistent_directory
    items = @reader.read_all("/nonexistent/directory")

    assert_equal [], items
  end

  def test_read_all_skips_malformed_files
    # Create valid file
    create_feedback_file("valid1", "Valid item")

    # Create malformed file
    File.write(File.join(@temp_dir, "malformed.s.md"), "No frontmatter here")

    # Create another valid file
    create_feedback_file("valid2", "Another valid item")

    items = @reader.read_all(@temp_dir)

    # Should get only the valid files
    assert_equal 2, items.length
    ids = items.map(&:id).sort
    assert_equal ["valid1", "valid2"], ids
  end

  def test_read_all_ignores_non_smd_files
    create_feedback_file("valid1", "Valid item")
    File.write(File.join(@temp_dir, "notes.md"), "Just notes")
    File.write(File.join(@temp_dir, "config.yml"), "config: value")

    items = @reader.read_all(@temp_dir)

    assert_equal 1, items.length
    assert_equal "valid1", items.first.id
  end

  # ============================================================================
  # read_by_status tests
  # ============================================================================

  def test_read_by_status_filters_correctly
    create_feedback_file("pend01", "Pending item", status: "pending")
    create_feedback_file("done01", "Done item", status: "done")
    create_feedback_file("pend02", "Another pending", status: "pending")
    create_feedback_file("skip01", "Skipped item", status: "skip")

    pending_items = @reader.read_by_status(@temp_dir, "pending")
    done_items = @reader.read_by_status(@temp_dir, "done")
    skip_items = @reader.read_by_status(@temp_dir, "skip")

    assert_equal 2, pending_items.length
    assert_equal 1, done_items.length
    assert_equal 1, skip_items.length

    pending_ids = pending_items.map(&:id).sort
    assert_equal ["pend01", "pend02"], pending_ids
  end

  def test_read_by_status_returns_empty_for_no_matches
    create_feedback_file("pend01", "Pending item", status: "pending")

    done_items = @reader.read_by_status(@temp_dir, "done")

    assert_equal [], done_items
  end

  def test_read_by_status_returns_empty_for_nonexistent_directory
    items = @reader.read_by_status("/nonexistent", "pending")

    assert_equal [], items
  end

  private

  # Helper to create a feedback file using the writer
  def create_feedback_file(id, title, **attrs)
    item = Ace::Review::Models::FeedbackItem.new(
      id: id,
      title: title,
      reviewer: attrs[:reviewer] || "test",
      status: attrs[:status] || "draft",
      priority: attrs[:priority] || "medium",
      files: attrs[:files] || [],
      finding: attrs[:finding] || "Test finding for #{title}"
    )
    @writer.write(item, @temp_dir)
  end
end
