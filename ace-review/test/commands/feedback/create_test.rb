# frozen_string_literal: true

require "test_helper"

class FeedbackCreateCommandTest < AceReviewTest
  def setup
    super
    @temp_dir = Dir.mktmpdir("feedback-create-test")
    @session_dir = File.join(@temp_dir, "sessions", "review-abc123")
    FileUtils.mkdir_p(@session_dir)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
    super
  end

  # ============================================================================
  # Basic Functionality Tests
  # ============================================================================

  def test_create_finds_review_reports_and_creates_feedback
    create_test_review_reports

    # Mock the feedback manager to verify it's called correctly
    manager = Minitest::Mock.new
    manager.expect(:extract_and_save, {
      success: true,
      items_count: 2,
      paths: [
        File.join(@session_dir, "feedback", "abc123-first-issue.s.md"),
        File.join(@session_dir, "feedback", "abc124-second-issue.s.md")
      ],
      metadata: {consensus_findings: 1}
    }, [], report_paths: Array, base_path: String, model: nil, session_dir: String)

    output = capture_cli_output do
      Ace::Review::Organisms::FeedbackManager.stub(:new, manager) do
        cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::Create.new
        cmd.call(session: @session_dir)
      end
    end

    manager.verify
    assert_match(/Found \d+ review report/, output)
    assert_match(/Created 2 feedback item/, output)
  end

  def test_create_errors_when_session_not_found
    assert_raises(Ace::Support::Cli::Error) do
      cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::Create.new
      cmd.call(session: "/nonexistent/path")
    end
  end

  def test_create_errors_when_no_review_reports_found
    # Session dir exists but has no review reports
    assert_raises(Ace::Support::Cli::Error) do
      cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::Create.new
      cmd.call(session: @session_dir)
    end
  end

  # ============================================================================
  # File Discovery Tests
  # ============================================================================

  def test_create_finds_review_report_files
    create_test_review_reports

    cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::Create.new
    report_paths = cmd.send(:find_review_reports, @session_dir)

    assert_equal 2, report_paths.length
    assert report_paths.any? { |p| p.include?("review-report-gemini") }
    assert report_paths.any? { |p| p.include?("review-report-claude") }
  end

  def test_create_excludes_dev_feedback_from_reports
    create_test_review_reports
    # Create dev-feedback file (should be excluded)
    File.write(File.join(@session_dir, "review-dev-feedback.md"), "# Developer Feedback")

    cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::Create.new
    report_paths = cmd.send(:find_review_reports, @session_dir)

    # Should not include dev-feedback
    refute report_paths.any? { |p| p.include?("dev-feedback") }
  end

  def test_create_excludes_synthesis_files
    create_test_review_reports
    # Create synthesis file (should be excluded)
    File.write(File.join(@session_dir, "synthesis-report.md"), "# Synthesis")

    cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::Create.new
    report_paths = cmd.send(:find_review_reports, @session_dir)

    refute report_paths.any? { |p| p.include?("synthesis") }
  end

  # ============================================================================
  # Latest Session Tests
  # ============================================================================

  def test_create_finds_latest_session_when_none_specified
    # Create cache directory structure
    cache_dir = File.join(@temp_dir, ".cache", "ace-review", "sessions")
    FileUtils.mkdir_p(cache_dir)

    # Create two sessions with different modification times
    old_session = File.join(cache_dir, "review-old123")
    new_session = File.join(cache_dir, "review-new456")
    FileUtils.mkdir_p(old_session)
    sleep(0.1) # Ensure different mtime
    FileUtils.mkdir_p(new_session)

    # Create review reports in the newer session
    File.write(File.join(new_session, "review-report-test.md"), "# Test Review")

    # Stub ProjectRootFinder to return temp dir (simulates running from project root)
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub(:find_or_current, @temp_dir) do
      cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::Create.new
      latest = cmd.send(:find_latest_session)

      assert_equal new_session, latest
    end
  end

  def test_create_returns_nil_when_no_sessions_exist
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub(:find_or_current, @temp_dir) do
      cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::Create.new
      latest = cmd.send(:find_latest_session)

      assert_nil latest
    end
  end

  # ============================================================================
  # Model Option Tests
  # ============================================================================

  def test_create_passes_model_option_to_manager
    create_test_review_reports

    manager = Minitest::Mock.new
    manager.expect(:extract_and_save, {
      success: true,
      items_count: 1,
      paths: [],
      metadata: {}
    }) do |args|
      args[:model] == "google:gemini-2.5-flash"
    end

    capture_cli_output do
      Ace::Review::Organisms::FeedbackManager.stub(:new, manager) do
        cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::Create.new
        cmd.call(session: @session_dir, model: "google:gemini-2.5-flash")
      end
    end

    manager.verify
  end

  # ============================================================================
  # Helper Methods
  # ============================================================================

  private

  def capture_cli_output
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end

  def create_test_review_reports
    # Create test review report files
    File.write(
      File.join(@session_dir, "review-report-gemini-2.5-flash.md"),
      <<~MD
        # Code Review

        ## Critical Issues

        ### 1. SQL Injection vulnerability
        **Files:** src/handler.rb:42
        **Finding:** User input passed directly to query
      MD
    )

    File.write(
      File.join(@session_dir, "review-report-claude-sonnet.md"),
      <<~MD
        # Code Review

        ## High Priority

        ### 1. Missing error handling
        **Files:** src/service.rb:100
        **Finding:** No try-catch around network call
      MD
    )
  end
end
