# frozen_string_literal: true

require "test_helper"

class FeedbackVerifyCommandTest < AceReviewTest
  def setup
    super
    @temp_dir = Dir.mktmpdir("feedback-verify-test")
    @feedback_dir = File.join(@temp_dir, "feedback")
    FileUtils.mkdir_p(@feedback_dir)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
    super
  end

  # ============================================================================
  # Valid Transition Tests
  # ============================================================================

  def test_verify_valid_marks_item_as_pending
    create_draft_item("abc111")

    output = capture_cli_output { run_verify_command("abc111", valid: true) }

    assert_match(/abc111 marked as valid/, output)

    # Verify item status was updated
    item = find_item("abc111")
    assert_equal "pending", item.status
  end

  def test_verify_valid_with_research_adds_notes
    create_draft_item("abc111")

    output = capture_cli_output do
      run_verify_command("abc111", valid: true, research: "Confirmed vulnerability exists")
    end

    assert_match(/abc111 marked as valid/, output)
    assert_match(/Research:/, output)

    item = find_item("abc111")
    assert_equal "Confirmed vulnerability exists", item.research
  end

  # ============================================================================
  # Invalid Transition Tests
  # ============================================================================

  def test_verify_skip_marks_item_as_skip_and_archives
    create_draft_item("abc111")

    output = capture_cli_output { run_verify_command("abc111", skip: true) }

    assert_match(/abc111 marked as skipped/, output)

    # Verify item was archived
    archive_dir = File.join(@feedback_dir, "_archived")
    files = Dir.glob(File.join(archive_dir, "abc111-*.s.md"))
    assert_equal 1, files.length

    # Verify active directory no longer has item
    active_files = Dir.glob(File.join(@feedback_dir, "abc111-*.s.md"))
    assert_empty active_files
  end

  def test_verify_skip_from_pending_archives_item
    create_pending_item("abc222")

    output = capture_cli_output { run_verify_command("abc222", skip: true) }

    assert_match(/abc222 marked as skipped/, output)

    # Verify item was archived
    archive_dir = File.join(@feedback_dir, "_archived")
    files = Dir.glob(File.join(archive_dir, "abc222-*.s.md"))
    assert_equal 1, files.length

    item = find_item_in_archive("abc222")
    assert_equal "skip", item.status
  end

  def test_verify_skip_with_research_adds_notes
    create_draft_item("abc111")

    capture_cli_output do
      run_verify_command("abc111", skip: true, research: "Design: using polling for simplicity")
    end

    # Read from archive
    archive_dir = File.join(@feedback_dir, "_archived")
    files = Dir.glob(File.join(archive_dir, "abc111-*.s.md"))
    reader = Ace::Review::Molecules::FeedbackFileReader.new
    result = reader.read(files.first)

    assert result[:success]
    assert_equal "Design: using polling for simplicity", result[:feedback_item].research
  end

  def test_verify_invalid_marks_item_as_invalid_and_archives
    create_draft_item("abc111")

    output = capture_cli_output { run_verify_command("abc111", invalid: true) }

    assert_match(/abc111 marked as invalid/, output)

    # Verify item was archived
    archive_dir = File.join(@feedback_dir, "_archived")
    files = Dir.glob(File.join(archive_dir, "abc111-*.s.md"))
    assert_equal 1, files.length

    # Verify active directory no longer has item
    active_files = Dir.glob(File.join(@feedback_dir, "abc111-*.s.md"))
    assert_empty active_files
  end

  def test_verify_invalid_with_research_adds_notes
    create_draft_item("abc111")

    capture_cli_output do
      run_verify_command("abc111", invalid: true, research: "False positive - not reachable")
    end

    # Read from archive
    archive_dir = File.join(@feedback_dir, "_archived")
    files = Dir.glob(File.join(archive_dir, "abc111-*.s.md"))
    reader = Ace::Review::Molecules::FeedbackFileReader.new
    result = reader.read(files.first)

    assert result[:success]
    assert_equal "False positive - not reachable", result[:feedback_item].research
  end

  # ============================================================================
  # Validation Tests
  # ============================================================================

  def test_verify_requires_mode_flag
    create_draft_item("abc111")

    error = assert_raises(Ace::Support::Cli::Error) do
      run_verify_command("abc111")
    end

    assert_match(/Must specify exactly one of: --valid, --invalid, --skip/, error.message)
  end

  def test_verify_rejects_multiple_modes
    create_draft_item("abc111")

    error = assert_raises(Ace::Support::Cli::Error) do
      run_verify_command("abc111", valid: true, invalid: true)
    end

    assert_match(/Cannot specify multiple modes/, error.message)
  end

  def test_verify_rejects_valid_and_skip_together
    create_draft_item("abc111")

    error = assert_raises(Ace::Support::Cli::Error) do
      run_verify_command("abc111", valid: true, skip: true)
    end

    assert_match(/Cannot specify multiple modes/, error.message)
  end

  def test_verify_rejects_invalid_and_skip_together
    create_draft_item("abc111")

    error = assert_raises(Ace::Support::Cli::Error) do
      run_verify_command("abc111", invalid: true, skip: true)
    end

    assert_match(/Cannot specify multiple modes/, error.message)
  end

  def test_verify_fails_for_nonexistent_item
    error = assert_raises(Ace::Support::Cli::Error) do
      run_verify_command("xyz999", valid: true)
    end

    assert_match(/not found/, error.message)
  end

  def test_verify_fails_for_pending_item
    create_pending_item("abc222")

    error = assert_raises(Ace::Support::Cli::Error) do
      run_verify_command("abc222", valid: true)
    end

    assert_match(/Invalid transition from 'pending' to 'pending'/, error.message)
  end

  # ============================================================================
  # Partial ID Matching Tests
  # ============================================================================

  def test_verify_supports_partial_id_matching
    create_draft_item("abc111")

    output = capture_cli_output { run_verify_command("abc1", valid: true) }

    assert_match(/abc111 marked as valid/, output)
  end

  def test_verify_errors_on_ambiguous_partial_id
    create_draft_item("abc111")
    create_draft_item("abc222")

    error = assert_raises(Ace::Support::Cli::Error) do
      run_verify_command("abc", valid: true)
    end

    assert_match(/Multiple items match/, error.message)
  end

  # ============================================================================
  # Helper Methods
  # ============================================================================

  private

  def run_verify_command(id, **options)
    cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::Verify.new
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

  def find_item(id)
    manager = Ace::Review::Organisms::FeedbackManager.new
    manager.find(@temp_dir, id)
  end

  def find_item_in_archive(id)
    archive_dir = File.join(@feedback_dir, "_archived")
    files = Dir.glob(File.join(archive_dir, "#{id}-*.s.md"))
    return nil if files.empty?

    reader = Ace::Review::Molecules::FeedbackFileReader.new
    result = reader.read(files.first)
    result[:success] ? result[:feedback_item] : nil
  end
end
