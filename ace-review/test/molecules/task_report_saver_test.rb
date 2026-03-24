# frozen_string_literal: true

require "test_helper"
require "ace/review/molecules/task_report_saver"
require "fileutils"
require "tmpdir"

class TaskReportSaverTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @task_dir = File.join(@temp_dir, "task-114")
    @session_dir = File.join(@temp_dir, "session")

    # Create directories
    FileUtils.mkdir_p(@task_dir)
    FileUtils.mkdir_p(@session_dir)

    # Create mock review file in session directory
    @review_file = File.join(@session_dir, "review-report-test.md")
    File.write(@review_file, "# Test Review\nThis is a test review.")
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
  end

  def test_save_creates_reviews_directory
    review_data = {preset: "pr", model: "google:gemini-2.5-flash"}

    result = Ace::Review::Molecules::TaskReportSaver.save(@task_dir, @review_file, review_data)

    assert result[:success], "Expected save to succeed"
    assert Dir.exist?(File.join(@task_dir, "reviews")), "Expected reviews/ directory to be created"
  end

  def test_save_copies_review_file
    review_data = {preset: "pr", model: "google:gemini-2.5-flash"}

    result = Ace::Review::Molecules::TaskReportSaver.save(@task_dir, @review_file, review_data)

    assert result[:success], "Expected save to succeed"
    assert File.exist?(result[:path]), "Expected review file to exist at #{result[:path]}"

    # Verify content was copied
    content = File.read(result[:path])
    assert_includes content, "Test Review"
  end

  def test_generate_filename_with_provider_prefix
    review_data = {preset: "pr", model: "google:gemini-2.5-flash"}

    filename = Ace::Review::Molecules::TaskReportSaver.generate_filename(review_data)

    # Should match pattern: {compact_id}-google-gemini-2-5-flash-pr-review.md
    # Compact ID is 6 chars Base36 (0-9, a-z)
    assert_match(/^[0-9a-z]{6}-google-gemini-2-5-flash-pr-review\.md$/, filename)
  end

  def test_generate_filename_with_model_name
    review_data = {preset: "security", model: "gpt-4"}

    filename = Ace::Review::Molecules::TaskReportSaver.generate_filename(review_data)

    # Should match pattern: {compact_id}-gpt-4-security-review.md
    # Compact ID is 6 chars Base36 (0-9, a-z)
    assert_match(/^[0-9a-z]{6}-gpt-4-security-review\.md$/, filename)
  end

  def test_generate_filename_unique_for_same_provider_models
    # This tests the fix for multi-model runs with same provider
    review_data_flash = {preset: "pr", model: "google:gemini-2.5-flash"}
    review_data_pro = {preset: "pr", model: "google:gemini-2.5-pro"}

    filename_flash = Ace::Review::Molecules::TaskReportSaver.generate_filename(review_data_flash)
    filename_pro = Ace::Review::Molecules::TaskReportSaver.generate_filename(review_data_pro)

    # Remove compact ID prefix to compare model portions
    # Compact ID is 6 chars Base36 (0-9, a-z)
    flash_suffix = filename_flash.sub(/^[0-9a-z]{6}-/, "")
    pro_suffix = filename_pro.sub(/^[0-9a-z]{6}-/, "")

    # Filenames should be different (different model slugs)
    refute_equal flash_suffix, pro_suffix, "Same-provider models should produce different filenames"
    assert_includes flash_suffix, "gemini-2-5-flash"
    assert_includes pro_suffix, "gemini-2-5-pro"
  end

  def test_generate_filename_sanitizes_preset
    review_data = {preset: "my custom/preset!", model: "claude-3"}

    filename = Ace::Review::Molecules::TaskReportSaver.generate_filename(review_data)

    # Preset should be sanitized
    assert_match(/my-custom-preset/, filename)
  end

  def test_extract_provider_from_prefixed_model
    provider = Ace::Review::Molecules::TaskReportSaver.extract_provider("google:gemini-2.5-flash")
    assert_equal "google", provider

    provider = Ace::Review::Molecules::TaskReportSaver.extract_provider("openai:gpt-4")
    assert_equal "openai", provider
  end

  def test_extract_provider_from_model_name
    provider = Ace::Review::Molecules::TaskReportSaver.extract_provider("gpt-4")
    assert_equal "gpt", provider

    provider = Ace::Review::Molecules::TaskReportSaver.extract_provider("claude-3-opus")
    assert_equal "claude", provider
  end

  def test_save_returns_error_for_missing_task_dir
    review_data = {preset: "pr", model: "google:gemini-2.5-flash"}
    non_existent_dir = File.join(@temp_dir, "nonexistent")

    result = Ace::Review::Molecules::TaskReportSaver.save(non_existent_dir, @review_file, review_data)

    refute result[:success], "Expected save to fail"
    assert_includes result[:error], "Task directory not found"
  end

  def test_save_returns_error_for_missing_review_file
    review_data = {preset: "pr", model: "google:gemini-2.5-flash"}
    non_existent_file = File.join(@session_dir, "nonexistent.md")

    result = Ace::Review::Molecules::TaskReportSaver.save(@task_dir, non_existent_file, review_data)

    refute result[:success], "Expected save to fail"
    assert_includes result[:error], "Review file not found"
  end

  # ============================================================================
  # Feedback Methods Tests (Task 227.07)
  # ============================================================================

  def test_feedback_path_returns_correct_path
    task_path = "/project/.ace-taskflow/v.0.9.0/tasks/227-feature"

    feedback_path = Ace::Review::Molecules::TaskReportSaver.feedback_path(task_path)

    assert_equal "/project/.ace-taskflow/v.0.9.0/tasks/227-feature/feedback", feedback_path
  end

  def test_feedback_archive_path_returns_correct_path
    task_path = "/project/.ace-taskflow/v.0.9.0/tasks/227-feature"

    archive_path = Ace::Review::Molecules::TaskReportSaver.feedback_archive_path(task_path)

    assert_equal "/project/.ace-taskflow/v.0.9.0/tasks/227-feature/feedback/_archived", archive_path
  end

  def test_save_feedback_creates_feedback_directory
    # Create a feedback file
    feedback_file = File.join(@session_dir, "abc123-sql-injection.s.md")
    File.write(feedback_file, "# SQL Injection\nDescription of the issue")

    result = Ace::Review::Molecules::TaskReportSaver.save_feedback(@task_dir, feedback_file)

    assert result[:success], "Expected save_feedback to succeed: #{result[:error]}"
    assert Dir.exist?(File.join(@task_dir, "feedback")), "Expected feedback/ directory to be created"
  end

  def test_save_feedback_copies_file_to_correct_location
    # Create a feedback file
    feedback_file = File.join(@session_dir, "abc123-sql-injection.s.md")
    File.write(feedback_file, "# SQL Injection\nDescription of the issue")

    result = Ace::Review::Molecules::TaskReportSaver.save_feedback(@task_dir, feedback_file)

    assert result[:success], "Expected save_feedback to succeed: #{result[:error]}"
    assert File.exist?(result[:path]), "Expected feedback file to exist at #{result[:path]}"

    # Verify the path is in the feedback directory
    assert_match(/feedback\/abc123-sql-injection\.s\.md$/, result[:path])

    # Verify content was copied
    content = File.read(result[:path])
    assert_includes content, "SQL Injection"
  end

  def test_save_feedback_preserves_original_filename
    # Create a feedback file with specific ID and slug
    feedback_file = File.join(@session_dir, "xyz789-n-plus-one-query.s.md")
    File.write(feedback_file, "# N+1 Query\nPerformance issue")

    result = Ace::Review::Molecules::TaskReportSaver.save_feedback(@task_dir, feedback_file)

    assert result[:success]
    assert_equal "xyz789-n-plus-one-query.s.md", File.basename(result[:path])
  end

  def test_save_feedback_returns_error_for_missing_task_dir
    feedback_file = File.join(@session_dir, "abc123-issue.s.md")
    File.write(feedback_file, "# Issue")
    non_existent_dir = File.join(@temp_dir, "nonexistent")

    result = Ace::Review::Molecules::TaskReportSaver.save_feedback(non_existent_dir, feedback_file)

    refute result[:success], "Expected save_feedback to fail"
    assert_includes result[:error], "Task directory not found"
  end

  def test_save_feedback_returns_error_for_missing_feedback_file
    non_existent_file = File.join(@session_dir, "nonexistent.s.md")

    result = Ace::Review::Molecules::TaskReportSaver.save_feedback(@task_dir, non_existent_file)

    refute result[:success], "Expected save_feedback to fail"
    assert_includes result[:error], "Feedback file not found"
  end

  def test_archive_feedback_moves_to_archived_directory
    # Create feedback directory with a file
    feedback_dir = File.join(@task_dir, "feedback")
    FileUtils.mkdir_p(feedback_dir)

    feedback_file = File.join(feedback_dir, "abc123-resolved-issue.s.md")
    File.write(feedback_file, "# Resolved Issue\nThis was fixed")

    result = Ace::Review::Molecules::TaskReportSaver.archive_feedback(@task_dir, feedback_file)

    assert result[:success], "Expected archive_feedback to succeed: #{result[:error]}"
    assert Dir.exist?(File.join(feedback_dir, "_archived")), "Expected _archived/ directory to be created"

    # Verify file was moved
    refute File.exist?(feedback_file), "Original file should be removed"
    assert File.exist?(result[:path]), "Archived file should exist at #{result[:path]}"
    assert_match(/_archived\/abc123-resolved-issue\.s\.md$/, result[:path])
  end

  def test_archive_feedback_creates_archived_directory_if_needed
    # Create feedback directory without _archived subdirectory
    feedback_dir = File.join(@task_dir, "feedback")
    FileUtils.mkdir_p(feedback_dir)

    feedback_file = File.join(feedback_dir, "abc123-issue.s.md")
    File.write(feedback_file, "# Issue")

    archive_dir = File.join(feedback_dir, "_archived")
    refute Dir.exist?(archive_dir), "_archived/ should not exist before archive"

    result = Ace::Review::Molecules::TaskReportSaver.archive_feedback(@task_dir, feedback_file)

    assert result[:success]
    assert Dir.exist?(archive_dir), "_archived/ should be created"
  end

  def test_archive_feedback_returns_error_for_missing_task_dir
    non_existent_dir = File.join(@temp_dir, "nonexistent")

    result = Ace::Review::Molecules::TaskReportSaver.archive_feedback(
      non_existent_dir,
      "/some/file.s.md"
    )

    refute result[:success]
    assert_includes result[:error], "Task directory not found"
  end

  def test_archive_feedback_returns_error_for_missing_feedback_file
    result = Ace::Review::Molecules::TaskReportSaver.archive_feedback(
      @task_dir,
      File.join(@task_dir, "feedback", "nonexistent.s.md")
    )

    refute result[:success]
    assert_includes result[:error], "Feedback file not found"
  end

  def test_save_feedback_with_metadata
    # Test that metadata parameter is accepted (for future extension)
    feedback_file = File.join(@session_dir, "abc123-issue.s.md")
    File.write(feedback_file, "# Issue")

    result = Ace::Review::Molecules::TaskReportSaver.save_feedback(
      @task_dir,
      feedback_file,
      {priority: "high", category: "security"}
    )

    assert result[:success], "Should accept metadata parameter"
  end
end
