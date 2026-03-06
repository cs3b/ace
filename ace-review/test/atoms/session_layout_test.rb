# frozen_string_literal: true

require "test_helper"

class SessionLayoutTest < AceReviewTest
  def self.use_shared_temp_dir?
    true
  end

  def setup
    super
    @session_dir = File.join(@test_dir, "review-test123")
    FileUtils.mkdir_p(@session_dir)
    @layout = Ace::Review::Atoms::SessionLayout.new(@session_dir)
  end

  def test_subject_dir
    assert_equal File.join(@session_dir, "_subject"), @layout.subject_dir
  end

  def test_prompts_dir
    assert_equal File.join(@session_dir, "_prompts"), @layout.prompts_dir
  end

  def test_reports_dir_without_reviewer
    assert_equal File.join(@session_dir, "_reports"), @layout.reports_dir
  end

  def test_reports_dir_with_reviewer
    path = @layout.reports_dir("architecture-fit")
    assert_equal File.join(@session_dir, "_reports", "architecture-fit"), path
  end

  def test_synthesis_dir
    assert_equal File.join(@session_dir, "_synthesis"), @layout.synthesis_dir
  end

  def test_user_context_path
    assert_equal File.join(@session_dir, "_subject", "user.context.md"), @layout.user_context_path
  end

  def test_user_prompt_path
    assert_equal File.join(@session_dir, "_subject", "user.prompt.md"), @layout.user_prompt_path
  end

  def test_system_context_path
    path = @layout.system_context_path("architecture-fit")
    assert_equal File.join(@session_dir, "_prompts", "architecture-fit.context.md"), path
  end

  def test_system_prompt_path
    path = @layout.system_prompt_path("architecture-fit")
    assert_equal File.join(@session_dir, "_prompts", "architecture-fit.prompt.md"), path
  end

  def test_report_path
    path = @layout.report_path("architecture-fit", "codex-spark-fast")
    assert_equal File.join(@session_dir, "_reports", "architecture-fit", "codex-spark-fast.md"), path
  end

  def test_flat_report_path
    path = @layout.flat_report_path("lint.md")
    assert_equal File.join(@session_dir, "_reports", "lint.md"), path
  end

  def test_synthesis_output_path
    assert_equal File.join(@session_dir, "_synthesis", "feedback-synthesis.json"), @layout.synthesis_output_path
  end

  def test_ensure_directories_creates_all_dirs
    @layout.ensure_directories!

    assert Dir.exist?(@layout.subject_dir)
    assert Dir.exist?(@layout.prompts_dir)
    assert Dir.exist?(@layout.reports_dir)
    assert Dir.exist?(@layout.synthesis_dir)
  end

  def test_organized_detection_with_subject_dir
    refute Ace::Review::Atoms::SessionLayout.organized?(@session_dir)

    FileUtils.mkdir_p(File.join(@session_dir, "_subject"))
    assert Ace::Review::Atoms::SessionLayout.organized?(@session_dir)
  end

  def test_system_prompt_deduplication_by_reviewer_name
    # Same reviewer name should produce same paths
    path1 = @layout.system_prompt_path("correctness")
    path2 = @layout.system_prompt_path("correctness")
    assert_equal path1, path2
  end

  def test_slugifies_special_characters_in_reviewer_name
    path = @layout.system_prompt_path("my:reviewer@v2")
    assert_match(/my-reviewer-v2\.prompt\.md$/, path)
  end
end
