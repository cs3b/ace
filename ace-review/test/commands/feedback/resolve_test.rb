# frozen_string_literal: true

require "test_helper"

class FeedbackResolveCommandTest < AceReviewTest
  def setup
    super
    @temp_dir = Dir.mktmpdir("feedback-resolve-test")
    @feedback_dir = File.join(@temp_dir, "feedback")
    FileUtils.mkdir_p(@feedback_dir)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
    super
  end

  # ============================================================================
  # Resolve From Pending Tests
  # ============================================================================

  def test_resolve_marks_pending_item_as_done_and_archives
    create_pending_item("abc111")

    output = capture_cli_output do
      run_resolve_command("abc111", resolution: "Fixed in commit def456")
    end

    assert_match(/abc111 resolved and archived/, output)
    assert_match(/Resolution:/, output)

    # Verify item was archived
    archive_dir = File.join(@feedback_dir, "_archived")
    files = Dir.glob(File.join(archive_dir, "abc111-*.s.md"))
    assert_equal 1, files.length

    # Verify active directory no longer has item
    active_files = Dir.glob(File.join(@feedback_dir, "abc111-*.s.md"))
    assert_empty active_files
  end

  def test_resolve_saves_resolution_text
    create_pending_item("abc111")

    capture_cli_output do
      run_resolve_command("abc111", resolution: "Added input validation in UserController")
    end

    # Read from archive and verify resolution
    archive_dir = File.join(@feedback_dir, "_archived")
    files = Dir.glob(File.join(archive_dir, "abc111-*.s.md"))
    reader = Ace::Review::Molecules::FeedbackFileReader.new
    result = reader.read(files.first)

    assert result[:success]
    assert_equal "done", result[:feedback_item].status
    assert_equal "Added input validation in UserController", result[:feedback_item].resolution
  end

  # ============================================================================
  # Validation Tests
  # ============================================================================

  def test_resolve_requires_resolution_text
    create_pending_item("abc111")

    error = assert_raises(Ace::Support::Cli::Error) do
      run_resolve_command("abc111", resolution: nil)
    end

    assert_match(/Resolution is required/, error.message)
  end

  def test_resolve_rejects_empty_resolution
    create_pending_item("abc111")

    error = assert_raises(Ace::Support::Cli::Error) do
      run_resolve_command("abc111", resolution: "   ")
    end

    assert_match(/Resolution is required/, error.message)
  end

  def test_resolve_fails_for_nonexistent_item
    error = assert_raises(Ace::Support::Cli::Error) do
      run_resolve_command("xyz999", resolution: "Fixed")
    end

    assert_match(/not found/, error.message)
  end

  def test_resolve_fails_from_draft
    create_draft_item("abc111")

    error = assert_raises(Ace::Support::Cli::Error) do
      run_resolve_command("abc111", resolution: "Fixed")
    end

    assert_match(/Invalid transition from 'draft' to 'done'/, error.message)
  end

  def test_resolve_fails_from_skip
    create_skipped_item("skip01")

    error = assert_raises(Ace::Support::Cli::Error) do
      run_resolve_command("skip01", resolution: "Fixed")
    end

    # Skip items are in archive, not accessible
    assert_match(/not found/, error.message)
  end

  # ============================================================================
  # Partial ID Matching Tests
  # ============================================================================

  def test_resolve_supports_partial_id_matching
    create_pending_item("abc111")

    output = capture_cli_output do
      run_resolve_command("abc1", resolution: "Fixed")
    end

    assert_match(/abc111 resolved/, output)
  end

  def test_resolve_errors_on_ambiguous_partial_id
    create_pending_item("abc111")
    create_pending_item("abc222")

    error = assert_raises(Ace::Support::Cli::Error) do
      run_resolve_command("abc", resolution: "Fixed")
    end

    assert_match(/Multiple items match/, error.message)
  end

  # ============================================================================
  # Full Workflow Tests
  # ============================================================================

  def test_full_workflow_verify_then_resolve
    create_draft_item("abc111")

    # Step 1: Verify as valid
    verify_cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::Verify.new
    capture_cli_output { verify_cmd.call(id: "abc111", valid: true, session: @temp_dir) }

    # Step 2: Resolve
    output = capture_cli_output do
      run_resolve_command("abc111", resolution: "Fixed by adding validation")
    end

    assert_match(/abc111 resolved/, output)

    # Verify final state
    archive_dir = File.join(@feedback_dir, "_archived")
    files = Dir.glob(File.join(archive_dir, "abc111-*.s.md"))
    reader = Ace::Review::Molecules::FeedbackFileReader.new
    result = reader.read(files.first)

    assert_equal "done", result[:feedback_item].status
    assert_equal "Fixed by adding validation", result[:feedback_item].resolution
  end

  # ============================================================================
  # Helper Methods
  # ============================================================================

  private

  def run_resolve_command(id, **options)
    cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::Resolve.new
    cmd.call(id: id, session: @temp_dir, **options)
  end

  def capture_cli_output
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end

  def create_draft_item(id)
    item = Ace::Review::Models::FeedbackItem.new(
      id: id,
      title: "Draft item #{id}",
      files: ["test.rb:10-20"],
      reviewer: "google:gemini-2.5-flash",
      status: "draft",
      priority: "medium",
      finding: "Test finding for #{id}",
      created: Time.now.utc.iso8601,
      updated: Time.now.utc.iso8601
    )

    writer = Ace::Review::Molecules::FeedbackFileWriter.new
    writer.write(item, @feedback_dir)
  end

  def create_pending_item(id)
    item = Ace::Review::Models::FeedbackItem.new(
      id: id,
      title: "Pending item #{id}",
      files: ["test.rb:10-20"],
      reviewer: "google:gemini-2.5-flash",
      status: "pending",
      priority: "medium",
      finding: "Test finding for #{id}",
      created: Time.now.utc.iso8601,
      updated: Time.now.utc.iso8601
    )

    writer = Ace::Review::Molecules::FeedbackFileWriter.new
    writer.write(item, @feedback_dir)
  end

  def create_skipped_item(id)
    archive_dir = File.join(@feedback_dir, "_archived")
    FileUtils.mkdir_p(archive_dir)

    item = Ace::Review::Models::FeedbackItem.new(
      id: id,
      title: "Skipped item #{id}",
      files: ["test.rb:10-20"],
      reviewer: "google:gemini-2.5-flash",
      status: "skip",
      priority: "medium",
      finding: "Test finding for #{id}",
      research: "Out of scope",
      created: Time.now.utc.iso8601,
      updated: Time.now.utc.iso8601
    )

    writer = Ace::Review::Molecules::FeedbackFileWriter.new
    writer.write(item, archive_dir)
  end
end
