# frozen_string_literal: true

require "test_helper"

class FeedbackShowCommandTest < AceReviewTest
  def self.use_shared_temp_dir?
    true
  end

  def setup
    super
    @temp_dir = @test_dir
    @feedback_dir = File.join(@temp_dir, "feedback")
    FileUtils.mkdir_p(@feedback_dir)
  end

  def teardown
    super
  end

  # ============================================================================
  # Display Tests
  # ============================================================================

  def test_show_displays_item_details
    create_test_item_with_all_fields

    output = capture_cli_output { run_show_command("abc123") }

    assert_match(/Feedback: abc123/, output)
    assert_match(/Title:\s+Full details item/, output)
    assert_match(/Status:.+draft/, output)
    assert_match(/Priority:\s+high/, output)
    assert_match(/Reviewer:\s+google:gemini-2.5-flash/, output)
  end

  def test_show_displays_finding_section
    create_test_item_with_all_fields

    output = capture_cli_output { run_show_command("abc123") }

    assert_match(/--- Finding ---/, output)
    assert_match(/This is the finding text/, output)
  end

  def test_show_displays_context_section
    create_test_item_with_all_fields

    output = capture_cli_output { run_show_command("abc123") }

    assert_match(/--- Context ---/, output)
    assert_match(/Additional context here/, output)
  end

  def test_show_displays_research_section_when_present
    create_test_item_with_research

    output = capture_cli_output { run_show_command("abc222") }

    assert_match(/--- Research ---/, output)
    assert_match(/Verified through testing/, output)
  end

  def test_show_displays_resolution_section_when_present
    create_resolved_item

    output = capture_cli_output { run_show_command("done01") }

    assert_match(/--- Resolution ---/, output)
    assert_match(/Fixed in commit/, output)
  end

  def test_show_displays_file_references
    create_test_item_with_all_fields

    output = capture_cli_output { run_show_command("abc123") }

    assert_match(/Files:/, output)
    assert_match(/test\.rb:10-20/, output)
  end

  # ============================================================================
  # Partial ID Matching Tests
  # ============================================================================

  def test_show_finds_item_by_partial_id
    create_test_item_with_all_fields

    output = capture_cli_output { run_show_command("abc") }

    assert_match(/Feedback: abc123/, output)
  end

  def test_show_requires_minimum_3_characters
    create_test_item_with_all_fields

    error = assert_raises(Ace::Support::Cli::Error) do
      run_show_command("ab")
    end

    assert_match(/at least 3 characters/, error.message)
  end

  def test_show_errors_on_ambiguous_partial_id
    create_multiple_items_with_similar_ids

    error = assert_raises(Ace::Support::Cli::Error) do
      run_show_command("abc")
    end

    assert_match(/Multiple items match/, error.message)
    assert_match(/abc111/, error.message)
    assert_match(/abc222/, error.message)
  end

  def test_show_finds_specific_item_with_longer_partial
    create_multiple_items_with_similar_ids

    output = capture_cli_output { run_show_command("abc111") }

    assert_match(/Feedback: abc111/, output)
    assert_match(/First finding/, output)
  end

  # ============================================================================
  # Error Handling Tests
  # ============================================================================

  def test_show_errors_when_item_not_found
    error = assert_raises(Ace::Support::Cli::Error) do
      run_show_command("xyz999")
    end

    assert_match(/not found/, error.message)
  end

  # ============================================================================
  # Archived Items Tests
  # ============================================================================

  def test_show_finds_archived_items
    create_archived_item

    output = capture_cli_output { run_show_command("done01") }

    assert_match(/Feedback: done01/, output)
    assert_match(/Archived item/, output)
  end

  # ============================================================================
  # Helper Methods
  # ============================================================================

  private

  def run_show_command(id, **options)
    cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::Show.new
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

  def create_test_item(id:, title:, status: "draft", priority: "medium", **extras)
    attrs = {
      id: id,
      title: title,
      files: ["test.rb:10-20"],
      reviewer: "google:gemini-2.5-flash",
      status: status,
      priority: priority,
      finding: "Test finding for #{title}",
      created: Time.now.utc.iso8601,
      updated: Time.now.utc.iso8601
    }.merge(extras)

    Ace::Review::Models::FeedbackItem.new(attrs)
  end

  def create_test_item_with_all_fields
    item = create_test_item(
      id: "abc123",
      title: "Full details item",
      status: "draft",
      priority: "high",
      finding: "This is the finding text with details.",
      context: "Additional context here."
    )

    writer = Ace::Review::Molecules::FeedbackFileWriter.new
    writer.write(item, @feedback_dir)
  end

  def create_test_item_with_research
    item = create_test_item(
      id: "abc222",
      title: "Item with research",
      status: "pending",
      priority: "medium",
      research: "Verified through testing."
    )

    writer = Ace::Review::Molecules::FeedbackFileWriter.new
    writer.write(item, @feedback_dir)
  end

  def create_resolved_item
    archive_dir = File.join(@feedback_dir, "_archived")
    FileUtils.mkdir_p(archive_dir)

    item = create_test_item(
      id: "done01",
      title: "Resolved item",
      status: "done",
      priority: "medium",
      resolution: "Fixed in commit abc123."
    )

    writer = Ace::Review::Molecules::FeedbackFileWriter.new
    writer.write(item, archive_dir)
  end

  def create_multiple_items_with_similar_ids
    writer = Ace::Review::Molecules::FeedbackFileWriter.new

    items = [
      create_test_item(id: "abc111", title: "First finding"),
      create_test_item(id: "abc222", title: "Second finding")
    ]

    items.each { |item| writer.write(item, @feedback_dir) }
  end

  def create_archived_item
    archive_dir = File.join(@feedback_dir, "_archived")
    FileUtils.mkdir_p(archive_dir)

    item = create_test_item(
      id: "done01",
      title: "Archived item",
      status: "done"
    )

    writer = Ace::Review::Molecules::FeedbackFileWriter.new
    writer.write(item, archive_dir)
  end
end
