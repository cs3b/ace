# frozen_string_literal: true

require "test_helper"
require "fileutils"

class FeedbackDirectoryManagerTest < AceReviewTest
  def self.use_shared_temp_dir?
    true
  end

  def setup
    super
    @temp_dir = @test_dir
    @manager = Ace::Review::Molecules::FeedbackDirectoryManager.new
    @writer = Ace::Review::Molecules::FeedbackFileWriter.new
  end

  # ============================================================================
  # Path helper tests
  # ============================================================================

  def test_feedback_path_returns_correct_path
    path = @manager.feedback_path(@temp_dir)

    assert_equal File.join(@temp_dir, "feedback"), path
  end

  def test_archive_path_returns_correct_path
    path = @manager.archive_path(@temp_dir)

    assert_equal File.join(@temp_dir, "feedback", "_archived"), path
  end

  # ============================================================================
  # ensure_directory tests
  # ============================================================================

  def test_ensure_directory_creates_feedback_directory
    refute Dir.exist?(File.join(@temp_dir, "feedback"))

    result = @manager.ensure_directory(@temp_dir)

    assert_equal File.join(@temp_dir, "feedback"), result
    assert Dir.exist?(result)
  end

  def test_ensure_directory_is_idempotent
    @manager.ensure_directory(@temp_dir)
    result = @manager.ensure_directory(@temp_dir)

    assert Dir.exist?(result)
  end

  def test_ensure_directory_creates_nested_path
    nested_base = File.join(@temp_dir, "deep", "nested", "path")

    result = @manager.ensure_directory(nested_base)

    assert Dir.exist?(result)
    assert_equal File.join(nested_base, "feedback"), result
  end

  # ============================================================================
  # ensure_archive tests
  # ============================================================================

  def test_ensure_archive_creates_archive_directory
    refute Dir.exist?(File.join(@temp_dir, "feedback", "_archived"))

    result = @manager.ensure_archive(@temp_dir)

    assert_equal File.join(@temp_dir, "feedback", "_archived"), result
    assert Dir.exist?(result)
  end

  def test_ensure_archive_creates_feedback_directory_too
    refute Dir.exist?(File.join(@temp_dir, "feedback"))

    @manager.ensure_archive(@temp_dir)

    assert Dir.exist?(File.join(@temp_dir, "feedback"))
    assert Dir.exist?(File.join(@temp_dir, "feedback", "_archived"))
  end

  def test_ensure_archive_is_idempotent
    @manager.ensure_archive(@temp_dir)
    result = @manager.ensure_archive(@temp_dir)

    assert Dir.exist?(result)
  end

  # ============================================================================
  # exists? and archive_exists? tests
  # ============================================================================

  def test_exists_returns_false_when_not_created
    refute @manager.exists?(@temp_dir)
  end

  def test_exists_returns_true_when_created
    @manager.ensure_directory(@temp_dir)

    assert @manager.exists?(@temp_dir)
  end

  def test_archive_exists_returns_false_when_not_created
    @manager.ensure_directory(@temp_dir)

    refute @manager.archive_exists?(@temp_dir)
  end

  def test_archive_exists_returns_true_when_created
    @manager.ensure_archive(@temp_dir)

    assert @manager.archive_exists?(@temp_dir)
  end

  # ============================================================================
  # archive tests
  # ============================================================================

  def test_archive_moves_file_to_archived_directory
    # Setup: create feedback directory and file
    feedback_dir = @manager.ensure_directory(@temp_dir)
    create_feedback_file(feedback_dir, "arch01", "Test item to archive")
    original_path = File.join(feedback_dir, "arch01-test-item-to-archive.s.md")

    assert File.exist?(original_path)

    # Archive
    result = @manager.archive(original_path)

    assert result[:success], "Expected archive to succeed: #{result[:error]}"
    refute File.exist?(original_path), "Expected original file to be removed"
    assert File.exist?(result[:path]), "Expected archived file to exist"
    assert_includes result[:path], "_archived"
  end

  def test_archive_creates_archive_directory_if_needed
    feedback_dir = @manager.ensure_directory(@temp_dir)
    create_feedback_file(feedback_dir, "arch02", "Another test")
    original_path = File.join(feedback_dir, "arch02-another-test.s.md")

    refute Dir.exist?(File.join(feedback_dir, "_archived"))

    result = @manager.archive(original_path)

    assert result[:success]
    assert Dir.exist?(File.join(feedback_dir, "_archived"))
  end

  def test_archive_returns_correct_destination_path
    feedback_dir = @manager.ensure_directory(@temp_dir)
    create_feedback_file(feedback_dir, "arch03", "Path test")
    original_path = File.join(feedback_dir, "arch03-path-test.s.md")

    result = @manager.archive(original_path)

    expected_path = File.join(feedback_dir, "_archived", "arch03-path-test.s.md")
    assert_equal expected_path, result[:path]
  end

  def test_archive_fails_for_nonexistent_file
    result = @manager.archive("/nonexistent/file.s.md")

    refute result[:success]
    assert_includes result[:error], "file does not exist"
  end

  def test_archive_fails_for_nil_path
    result = @manager.archive(nil)

    refute result[:success]
    assert_includes result[:error], "file_path is required"
  end

  def test_archive_fails_for_empty_path
    result = @manager.archive("")

    refute result[:success]
    assert_includes result[:error], "file_path is required"
  end

  def test_archive_fails_for_wrong_extension
    # Create a non-.s.md file
    wrong_file = File.join(@temp_dir, "wrong.md")
    File.write(wrong_file, "content")

    result = @manager.archive(wrong_file)

    refute result[:success]
    assert_includes result[:error], ".s.md extension"
  end

  # ============================================================================
  # list_files tests
  # ============================================================================

  def test_list_files_returns_all_feedback_files
    feedback_dir = @manager.ensure_directory(@temp_dir)
    create_feedback_file(feedback_dir, "list01", "First")
    create_feedback_file(feedback_dir, "list02", "Second")
    create_feedback_file(feedback_dir, "list03", "Third")

    files = @manager.list_files(feedback_dir)

    assert_equal 3, files.length
    files.each { |f| assert f.end_with?(".s.md") }
  end

  def test_list_files_returns_sorted_paths
    feedback_dir = @manager.ensure_directory(@temp_dir)
    create_feedback_file(feedback_dir, "zzz001", "Last alphabetically")
    create_feedback_file(feedback_dir, "aaa001", "First alphabetically")
    create_feedback_file(feedback_dir, "mmm001", "Middle alphabetically")

    files = @manager.list_files(feedback_dir)

    # Should be sorted
    assert_equal files.sort, files
  end

  def test_list_files_excludes_archived_by_default
    feedback_dir = @manager.ensure_directory(@temp_dir)
    create_feedback_file(feedback_dir, "active1", "Active item")
    create_feedback_file(feedback_dir, "active2", "Another active")

    # Archive one file
    @manager.archive(File.join(feedback_dir, "active1-active-item.s.md"))

    files = @manager.list_files(feedback_dir)

    assert_equal 1, files.length
    assert files.first.include?("active2")
  end

  def test_list_files_includes_archived_when_requested
    feedback_dir = @manager.ensure_directory(@temp_dir)
    create_feedback_file(feedback_dir, "mixed1", "Active")
    create_feedback_file(feedback_dir, "mixed2", "To archive")

    # Archive one file
    @manager.archive(File.join(feedback_dir, "mixed2-to-archive.s.md"))

    files = @manager.list_files(feedback_dir, include_archived: true)

    assert_equal 2, files.length
  end

  def test_list_files_returns_empty_for_empty_directory
    feedback_dir = @manager.ensure_directory(@temp_dir)

    files = @manager.list_files(feedback_dir)

    assert_equal [], files
  end

  def test_list_files_returns_empty_for_nonexistent_directory
    files = @manager.list_files("/nonexistent/directory")

    assert_equal [], files
  end

  def test_list_files_ignores_non_smd_files
    feedback_dir = @manager.ensure_directory(@temp_dir)
    create_feedback_file(feedback_dir, "valid1", "Valid file")
    File.write(File.join(feedback_dir, "notes.md"), "notes")
    File.write(File.join(feedback_dir, "config.yml"), "config: value")
    File.write(File.join(feedback_dir, ".hidden.s.md"), "hidden")

    files = @manager.list_files(feedback_dir)

    # Should only include the valid .s.md file (not the hidden one due to glob)
    assert_equal 1, files.length
    assert files.first.include?("valid1")
  end

  # ============================================================================
  # count_files tests
  # ============================================================================

  def test_count_files_returns_correct_counts
    feedback_dir = @manager.ensure_directory(@temp_dir)
    create_feedback_file(feedback_dir, "cnt001", "Active 1")
    create_feedback_file(feedback_dir, "cnt002", "Active 2")
    create_feedback_file(feedback_dir, "cnt003", "To archive")

    # Archive one
    @manager.archive(File.join(feedback_dir, "cnt003-to-archive.s.md"))

    counts = @manager.count_files(feedback_dir)

    assert_equal 2, counts[:active]
    assert_equal 1, counts[:archived]
    assert_equal 3, counts[:total]
  end

  def test_count_files_returns_zeros_for_empty_directory
    feedback_dir = @manager.ensure_directory(@temp_dir)

    counts = @manager.count_files(feedback_dir)

    assert_equal({active: 0, archived: 0, total: 0}, counts)
  end

  def test_count_files_returns_zeros_for_nonexistent_directory
    counts = @manager.count_files("/nonexistent")

    assert_equal({active: 0, archived: 0, total: 0}, counts)
  end

  private

  # Helper to create a feedback file
  def create_feedback_file(directory, id, title)
    item = Ace::Review::Models::FeedbackItem.new(
      id: id,
      title: title,
      reviewer: "test",
      status: "draft",
      priority: "medium",
      finding: "Test finding"
    )
    @writer.write(item, directory)
  end
end
