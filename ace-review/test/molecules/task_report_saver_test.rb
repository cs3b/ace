# frozen_string_literal: true

require "test_helper"
require "ace/review/molecules/task_report_saver"
require "ace/taskflow"
require "ace/taskflow/organisms/release_manager"
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

    # Should match pattern: {compact_id}-google-gemini-2-5-flash-pr-review.md
    # Compact ID is 6 chars Base36 (0-9, a-z)
    assert_match(/^[0-9a-z]{6}-google-gemini-2-5-flash-pr-review\.md$/, filename)
  end

  def test_generate_filename_with_model_name
    review_data = { preset: "security", model: "gpt-4" }

    filename = Ace::Review::Molecules::TaskReportSaver.generate_filename(review_data)

    # Should match pattern: {compact_id}-gpt-4-security-review.md
    # Compact ID is 6 chars Base36 (0-9, a-z)
    assert_match(/^[0-9a-z]{6}-gpt-4-security-review\.md$/, filename)
  end

  def test_generate_filename_unique_for_same_provider_models
    # This tests the fix for multi-model runs with same provider
    review_data_flash = { preset: "pr", model: "google:gemini-2.5-flash" }
    review_data_pro = { preset: "pr", model: "google:gemini-2.5-pro" }

    filename_flash = Ace::Review::Molecules::TaskReportSaver.generate_filename(review_data_flash)
    filename_pro = Ace::Review::Molecules::TaskReportSaver.generate_filename(review_data_pro)

    # Remove compact ID prefix to compare model portions
    # Compact ID is 6 chars Base36 (0-9, a-z)
    flash_suffix = filename_flash.sub(/^[0-9a-z]{6}-/, '')
    pro_suffix = filename_pro.sub(/^[0-9a-z]{6}-/, '')

    # Filenames should be different (different model slugs)
    refute_equal flash_suffix, pro_suffix, "Same-provider models should produce different filenames"
    assert_includes flash_suffix, "gemini-2-5-flash"
    assert_includes pro_suffix, "gemini-2-5-pro"
  end

  def test_generate_filename_sanitizes_preset
    review_data = { preset: "my custom/preset!", model: "claude-3" }

    filename = Ace::Review::Molecules::TaskReportSaver.generate_filename(review_data)

    # Preset should be sanitized
    assert_match(/my-custom-preset/, filename)
  end

  def test_generate_filename_for_synthesis_report
    review_data = { preset: "code-multi", model: "google:gemini-2.5-flash", report_type: 'synthesis' }

    filename = Ace::Review::Molecules::TaskReportSaver.generate_filename(review_data)

    # Should match pattern: {compact_id}-synthesis.md
    # Compact ID is 6 chars Base36 (0-9, a-z)
    assert_match(/^[0-9a-z]{6}-synthesis\.md$/, filename)
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

  # ============================================================================
  # save_to_release tests
  # ============================================================================

  def test_save_to_release_copies_file_to_release_reviews_dir
    review_data = { preset: "pr", model: "claude:opus" }

    # Create release directory structure
    release_dir = File.join(@temp_dir, "releases", "v1.0.0")
    release_file = File.join(release_dir, "release.yml")
    FileUtils.mkdir_p(release_dir)
    File.write(release_file, "name: v1.0.0\n")

    # Mock the release manager
    mock_release_manager = Minitest::Mock.new
    mock_release_manager.expect(:current_release, { path: release_file, name: "v1.0.0" })

    # Stub ReleaseManager.new to return our mock
    Ace::Taskflow::Organisms::ReleaseManager.stub :new, mock_release_manager do
      result = Ace::Review::Molecules::TaskReportSaver.save_to_release(@review_file, review_data)

      assert result[:success], "Expected save_to_release to succeed: #{result[:error]}"
      assert File.exist?(result[:path]), "Expected review file to exist at #{result[:path]}"
      assert_match(/releases\/v1.0.0\/reviews/, result[:path])

      # Verify content was copied
      content = File.read(result[:path])
      assert_includes content, "Test Review"
    end

    mock_release_manager.verify
  end

  def test_save_to_release_returns_error_for_missing_review_file
    review_data = { preset: "pr", model: "claude:opus" }
    non_existent_file = File.join(@session_dir, "nonexistent.md")

    result = Ace::Review::Molecules::TaskReportSaver.save_to_release(non_existent_file, review_data)

    refute result[:success], "Expected save_to_release to fail"
    assert_includes result[:error], "Review file not found"
  end

  def test_save_to_release_returns_error_when_no_current_release
    review_data = { preset: "pr", model: "claude:opus" }

    # Mock the release manager to return nil
    mock_release_manager = Minitest::Mock.new
    mock_release_manager.expect(:current_release, nil)

    Ace::Taskflow::Organisms::ReleaseManager.stub :new, mock_release_manager do
      result = Ace::Review::Molecules::TaskReportSaver.save_to_release(@review_file, review_data)

      refute result[:success], "Expected save_to_release to fail"
      assert_includes result[:error], "No current release found"
    end

    mock_release_manager.verify
  end

  def test_save_to_release_creates_reviews_subdirectory
    review_data = { preset: "pr", model: "claude:opus" }

    # Create release directory structure without reviews/ subdir
    release_dir = File.join(@temp_dir, "releases", "v2.0.0")
    release_file = File.join(release_dir, "release.yml")
    FileUtils.mkdir_p(release_dir)
    File.write(release_file, "name: v2.0.0\n")

    # Reviews dir should NOT exist yet
    reviews_dir = File.join(release_dir, "reviews")
    refute Dir.exist?(reviews_dir), "reviews/ should not exist before save"

    mock_release_manager = Minitest::Mock.new
    mock_release_manager.expect(:current_release, { path: release_file, name: "v2.0.0" })

    Ace::Taskflow::Organisms::ReleaseManager.stub :new, mock_release_manager do
      result = Ace::Review::Molecules::TaskReportSaver.save_to_release(@review_file, review_data)

      assert result[:success], "Expected save_to_release to succeed: #{result[:error]}"
      assert Dir.exist?(reviews_dir), "Expected reviews/ directory to be created"
    end

    mock_release_manager.verify
  end

  def test_save_to_release_handles_exception_gracefully
    review_data = { preset: "pr", model: "claude:opus" }

    # Mock the release manager to raise an exception
    mock_release_manager = Minitest::Mock.new
    def mock_release_manager.current_release
      raise "Simulated error"
    end

    Ace::Taskflow::Organisms::ReleaseManager.stub :new, mock_release_manager do
      result = Ace::Review::Molecules::TaskReportSaver.save_to_release(@review_file, review_data)

      refute result[:success], "Expected save_to_release to fail"
      assert_includes result[:error], "Failed to save to release"
    end
  end
end
