# frozen_string_literal: true

require "test_helper"

class FeedbackSkipCommandTest < AceReviewTest
  def setup
    super
    @temp_dir = Dir.mktmpdir("feedback-skip-test")
    @feedback_dir = File.join(@temp_dir, "feedback")
    FileUtils.mkdir_p(@feedback_dir)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
    super
  end

  # ============================================================================
  # Deprecation Warning Tests
  # ============================================================================

  def test_skip_shows_deprecation_warning
    create_draft_item("abc111")

    output = capture_cli_output { run_skip_command("abc111") }

    assert_match(/DEPRECATED/, output)
    assert_match(/verify --skip/, output)
  end

  def test_skip_with_reason_shows_deprecation_warning
    create_draft_item("abc111")

    output = capture_cli_output do
      run_skip_command("abc111", reason: "Out of scope")
    end

    assert_match(/DEPRECATED/, output)
  end

  def test_skip_quiet_mode_suppresses_deprecation_warning
    create_draft_item("abc111")

    output = capture_cli_output do
      run_skip_command("abc111", quiet: true)
    end

    refute_match(/DEPRECATED/, output)
  end

  # ============================================================================
  # Backward Compatibility Tests
  # ============================================================================

  def test_skip_from_draft_archives_item
    create_draft_item("abc111")

    output = capture_cli_output { run_skip_command("abc111") }

    assert_match(/abc111 skipped and archived/, output)

    # Verify item was archived
    archive_dir = File.join(@feedback_dir, "_archived")
    files = Dir.glob(File.join(archive_dir, "abc111-*.s.md"))
    assert_equal 1, files.length

    # Verify active directory no longer has item
    active_files = Dir.glob(File.join(@feedback_dir, "abc111-*.s.md"))
    assert_empty active_files
  end

  def test_skip_with_reason_adds_notes
    create_draft_item("abc111")

    output = capture_cli_output do
      run_skip_command("abc111", reason: "Out of scope for this sprint")
    end

    assert_match(/abc111 skipped/, output)
    assert_match(/Research:/, output)

    # Read from archive and verify reason
    archive_dir = File.join(@feedback_dir, "_archived")
    files = Dir.glob(File.join(archive_dir, "abc111-*.s.md"))
    reader = Ace::Review::Molecules::FeedbackFileReader.new
    result = reader.read(files.first)

    assert result[:success]
    assert_equal "Out of scope for this sprint", result[:feedback_item].research
  end

  def test_skip_with_research_flag_adds_notes
    create_draft_item("abc111")

    output = capture_cli_output do
      run_skip_command("abc111", research: "Tracked in task 253")
    end

    assert_match(/abc111 skipped/, output)
    assert_match(/Research:/, output)

    # Read from archive and verify research
    archive_dir = File.join(@feedback_dir, "_archived")
    files = Dir.glob(File.join(archive_dir, "abc111-*.s.md"))
    reader = Ace::Review::Molecules::FeedbackFileReader.new
    result = reader.read(files.first)

    assert result[:success]
    assert_equal "Tracked in task 253", result[:feedback_item].research
  end

  def test_skip_research_flag_takes_precedence_over_reason
    create_draft_item("abc111")

    capture_cli_output do
      run_skip_command("abc111", reason: "Old reason", research: "New research")
    end

    # Read from archive and verify research flag was used
    archive_dir = File.join(@feedback_dir, "_archived")
    files = Dir.glob(File.join(archive_dir, "abc111-*.s.md"))
    reader = Ace::Review::Molecules::FeedbackFileReader.new
    result = reader.read(files.first)

    # Research flag should take precedence (reason is aliased to research)
    # In the implementation, we check research first, then reason
    assert_equal "New research", result[:feedback_item].research
  end

  # ============================================================================
  # Skip From Pending Tests
  # ============================================================================

  def test_skip_from_pending_archives_item
    create_pending_item("abc222")

    output = capture_cli_output { run_skip_command("abc222") }

    assert_match(/abc222 skipped and archived/, output)

    # Verify item was archived
    archive_dir = File.join(@feedback_dir, "_archived")
    files = Dir.glob(File.join(archive_dir, "abc222-*.s.md"))
    assert_equal 1, files.length
  end

  def test_skip_from_pending_with_reason
    create_pending_item("abc222")

    capture_cli_output do
      run_skip_command("abc222", reason: "Won't fix - technical debt accepted")
    end

    archive_dir = File.join(@feedback_dir, "_archived")
    files = Dir.glob(File.join(archive_dir, "abc222-*.s.md"))
    reader = Ace::Review::Molecules::FeedbackFileReader.new
    result = reader.read(files.first)

    assert_equal "skip", result[:feedback_item].status
    assert_equal "Won't fix - technical debt accepted", result[:feedback_item].research
  end

  # ============================================================================
  # Error Handling Tests
  # ============================================================================

  def test_skip_fails_for_nonexistent_item
    error = assert_raises(Ace::Support::Cli::Error) do
      run_skip_command("xyz999")
    end

    assert_match(/not found/, error.message)
  end

  def test_skip_fails_for_done_item
    # Done items are in archive, not accessible for skip
    create_done_item("done01")

    error = assert_raises(Ace::Support::Cli::Error) do
      run_skip_command("done01")
    end

    assert_match(/not found/, error.message)
  end

  # ============================================================================
  # Partial ID Matching Tests
  # ============================================================================

  def test_skip_supports_partial_id_matching
    create_draft_item("abc111")

    output = capture_cli_output { run_skip_command("abc1") }

    assert_match(/abc111 skipped/, output)
  end

  def test_skip_errors_on_ambiguous_partial_id
    create_draft_item("abc111")
    create_draft_item("abc222")

    error = assert_raises(Ace::Support::Cli::Error) do
      run_skip_command("abc")
    end

    assert_match(/Multiple items match/, error.message)
  end

  # ============================================================================
  # Helper Methods
  # ============================================================================

  private

  def run_skip_command(id, **options)
    cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::Skip.new
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

  def create_done_item(id)
    archive_dir = File.join(@feedback_dir, "_archived")
    FileUtils.mkdir_p(archive_dir)

    item = Ace::Review::Models::FeedbackItem.new(
      id: id,
      title: "Done item #{id}",
      files: ["test.rb:10-20"],
      reviewer: "google:gemini-2.5-flash",
      status: "done",
      priority: "medium",
      finding: "Test finding for #{id}",
      resolution: "Fixed",
      created: Time.now.utc.iso8601,
      updated: Time.now.utc.iso8601
    )

    writer = Ace::Review::Molecules::FeedbackFileWriter.new
    writer.write(item, archive_dir)
  end
end
