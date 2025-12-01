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
    review_data = { preset: "pr", model: "google:gemini-2.5-flash" }

    result = Ace::Review::Molecules::TaskReportSaver.save(@task_dir, @review_file, review_data)

    assert result[:success], "Expected save to succeed"
    assert Dir.exist?(File.join(@task_dir, "reviews")), "Expected reviews/ directory to be created"
  end

  def test_save_copies_review_file
    review_data = { preset: "pr", model: "google:gemini-2.5-flash" }

    result = Ace::Review::Molecules::TaskReportSaver.save(@task_dir, @review_file, review_data)

    assert result[:success], "Expected save to succeed"
    assert File.exist?(result[:path]), "Expected review file to exist at #{result[:path]}"

    # Verify content was copied
    content = File.read(result[:path])
    assert_includes content, "Test Review"
  end

  def test_generate_filename_with_provider_prefix
    review_data = { preset: "pr", model: "google:gemini-2.5-flash" }

    filename = Ace::Review::Molecules::TaskReportSaver.generate_filename(review_data)

    # Should match pattern: YYYYMMDD-HHMMSS-google-pr-review.md
    assert_match(/^\d{8}-\d{6}-google-pr-review\.md$/, filename)
  end

  def test_generate_filename_with_model_name
    review_data = { preset: "security", model: "gpt-4" }

    filename = Ace::Review::Molecules::TaskReportSaver.generate_filename(review_data)

    # Should match pattern: YYYYMMDD-HHMMSS-gpt-security-review.md
    assert_match(/^\d{8}-\d{6}-gpt-security-review\.md$/, filename)
  end

  def test_generate_filename_sanitizes_preset
    review_data = { preset: "my custom/preset!", model: "claude-3" }

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
    review_data = { preset: "pr", model: "google:gemini-2.5-flash" }
    non_existent_dir = File.join(@temp_dir, "nonexistent")

    result = Ace::Review::Molecules::TaskReportSaver.save(non_existent_dir, @review_file, review_data)

    refute result[:success], "Expected save to fail"
    assert_includes result[:error], "Task directory not found"
  end

  def test_save_returns_error_for_missing_review_file
    review_data = { preset: "pr", model: "google:gemini-2.5-flash" }
    non_existent_file = File.join(@session_dir, "nonexistent.md")

    result = Ace::Review::Molecules::TaskReportSaver.save(@task_dir, non_existent_file, review_data)

    refute result[:success], "Expected save to fail"
    assert_includes result[:error], "Review file not found"
  end
end
