# frozen_string_literal: true

require "test_helper"
require "ace/review"
require "ace/review/molecules/task_resolver"
require "ace/review/molecules/task_report_saver"
require "tmpdir"
require "fileutils"
require "open3"

class AutoSaveIntegrationTest < Minitest::Test
  def setup
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  # Test TaskPatternExtractor patterns (from ace-git)

  def test_extracts_task_id_from_standard_branch
    task_id = Ace::Git::Atoms::TaskPatternExtractor.extract_from_branch("121-feature-name")
    assert_equal "121", task_id
  end

  def test_extracts_subtask_id_from_branch
    task_id = Ace::Git::Atoms::TaskPatternExtractor.extract_from_branch("121.01-archive-prompts")
    assert_equal "121.01", task_id
  end

  def test_extracts_from_feature_branch_pattern
    patterns = ['^feature/(\d+)-']
    task_id = Ace::Git::Atoms::TaskPatternExtractor.extract_from_branch(
      "feature/123-add-login",
      patterns: patterns
    )
    assert_equal "123", task_id
  end

  def test_returns_nil_for_main_branch
    task_id = Ace::Git::Atoms::TaskPatternExtractor.extract_from_branch("main")
    assert_nil task_id
  end

  def test_returns_nil_for_detached_head
    task_id = Ace::Git::Atoms::TaskPatternExtractor.extract_from_branch("HEAD")
    assert_nil task_id
  end

  def test_returns_nil_for_non_matching_branch
    task_id = Ace::Git::Atoms::TaskPatternExtractor.extract_from_branch("feature-no-number")
    assert_nil task_id
  end

  def test_returns_nil_for_empty_branch
    task_id = Ace::Git::Atoms::TaskPatternExtractor.extract_from_branch("")
    assert_nil task_id
  end

  def test_returns_nil_for_nil_branch
    task_id = Ace::Git::Atoms::TaskPatternExtractor.extract_from_branch(nil)
    assert_nil task_id
  end

  # Test BranchReader integration (from ace-git)

  def test_branch_detection_integration
    # Mock ace-git BranchReader to return a task branch
    Ace::Git::Molecules::BranchReader.stub :current_branch, "126.03-auto-save-detection" do
      branch = Ace::Git::Molecules::BranchReader.current_branch
      assert_equal "126.03-auto-save-detection", branch

      task_id = Ace::Git::Atoms::TaskPatternExtractor.extract_from_branch(branch)
      assert_equal "126.03", task_id
    end
  end

  # Test TaskReportSaver

  def test_saves_report_to_task_directory
    # Create temp task directory structure
    task_dir = File.join(@tmpdir, "tasks", "126-feature")
    FileUtils.mkdir_p(task_dir)

    # Create a temp review file
    review_file = File.join(@tmpdir, "review.md")
    File.write(review_file, "# Review\nTest content")

    review_data = { model: "google:gemini-2.5-flash", preset: "code" }

    result = Ace::Review::Molecules::TaskReportSaver.save(task_dir, review_file, review_data)

    assert result[:success], "Should save successfully"
    assert result[:path], "Should return path"
    assert File.exist?(result[:path]), "Saved file should exist"
    assert_match %r{reviews/.+-google-gemini-2-5-flash-.+-review\.md$}, result[:path]
  end

  def test_creates_reviews_subdirectory
    # Create temp task directory without reviews/ subdirectory
    task_dir = File.join(@tmpdir, "tasks", "126-feature")
    FileUtils.mkdir_p(task_dir)

    review_file = File.join(@tmpdir, "review.md")
    File.write(review_file, "# Review\nTest content")

    review_data = { model: "test-model", preset: "test" }

    result = Ace::Review::Molecules::TaskReportSaver.save(task_dir, review_file, review_data)

    assert result[:success]
    assert Dir.exist?(File.join(task_dir, "reviews")), "Should create reviews/ subdirectory"
  end

  def test_returns_error_for_missing_task_directory
    result = Ace::Review::Molecules::TaskReportSaver.save(
      "/nonexistent/path",
      File.join(@tmpdir, "review.md"),
      {}
    )

    refute result[:success]
    assert_match(/not found/, result[:error])
  end

  def test_returns_error_for_missing_review_file
    task_dir = File.join(@tmpdir, "tasks", "126-feature")
    FileUtils.mkdir_p(task_dir)

    result = Ace::Review::Molecules::TaskReportSaver.save(
      task_dir,
      "/nonexistent/review.md",
      {}
    )

    refute result[:success]
    assert_match(/not found/, result[:error])
  end

  def test_generates_synthesis_filename
    review_data = { report_type: 'synthesis' }
    filename = Ace::Review::Molecules::TaskReportSaver.generate_filename(review_data)

    # Compact ID is 6 chars Base36 (0-9, a-z)
    assert_match(/[0-9a-z]{6}-synthesis\.md$/, filename)
  end

  def test_generates_model_review_filename
    review_data = { model: "claude:opus", preset: "code-pr" }
    filename = Ace::Review::Molecules::TaskReportSaver.generate_filename(review_data)

    # Compact ID is 6 chars Base36 (0-9, a-z)
    assert_match(/[0-9a-z]{6}-claude-opus-code-pr-review\.md$/, filename)
  end

  # Test end-to-end flow (mocked)

  def test_auto_save_flow_branch_to_task
    # Simulate the full flow:
    # 1. Get branch name
    # 2. Extract task ID
    # 3. Resolve task directory
    # 4. Save report

    branch_name = "126.03-auto-save-detection"
    task_id = Ace::Git::Atoms::TaskPatternExtractor.extract_from_branch(branch_name)
    assert_equal "126.03", task_id

    # In real flow, TaskResolver would find the task directory
    # For this test, we simulate it
    task_dir = File.join(@tmpdir, "tasks", "126-llm-enhance")
    FileUtils.mkdir_p(task_dir)

    review_file = File.join(@tmpdir, "review.md")
    File.write(review_file, "# Review content")

    result = Ace::Review::Molecules::TaskReportSaver.save(
      task_dir,
      review_file,
      { model: "test", preset: "code" }
    )

    assert result[:success], "Full flow should succeed"
    assert File.exist?(result[:path]), "Review should be saved"
  end
end
