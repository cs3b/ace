# frozen_string_literal: true

require "test_helper"
require "json"

class FeedbackListCommandTest < AceReviewTest
  def setup
    super
    @temp_dir = Dir.mktmpdir("feedback-list-test")
    @feedback_dir = File.join(@temp_dir, "feedback")
    FileUtils.mkdir_p(@feedback_dir)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
    super
  end

  # ============================================================================
  # Table Output Tests
  # ============================================================================

  def test_list_displays_items_as_table
    create_test_items

    output = capture_cli_output { run_list_command }

    assert_match(/ID\s+STATUS\s+PRIORITY\s+TITLE/, output)
    assert_match(/abc111/, output)
    assert_match(/abc222/, output)
    assert_match(/draft/, output)
  end

  def test_list_displays_empty_message_when_no_items
    output = capture_cli_output { run_list_command }

    assert_match(/No feedback items found/, output)
  end

  def test_list_shows_total_count
    create_test_items

    output = capture_cli_output { run_list_command }

    assert_match(/Total: 2 item/, output)
  end

  # ============================================================================
  # Filter Tests
  # ============================================================================

  def test_list_filters_by_status
    create_test_items

    output = capture_cli_output { run_list_command(status: "draft") }

    assert_match(/abc111/, output)
    refute_match(/abc222/, output) # pending item
  end

  def test_list_filters_by_priority
    create_test_items

    output = capture_cli_output { run_list_command(priority: "high") }

    assert_match(/abc111/, output)
    refute_match(/abc222/, output) # medium priority
  end

  def test_list_filters_by_status_and_priority
    create_test_items_mixed

    output = capture_cli_output { run_list_command(status: "draft", priority: "high") }

    assert_match(/abc111/, output)
    refute_match(/abc222/, output)
    refute_match(/abc333/, output)
  end

  # ============================================================================
  # JSON Output Tests
  # ============================================================================

  def test_list_outputs_json_format
    create_test_items

    output = capture_cli_output { run_list_command(format: "json") }

    json = JSON.parse(output)
    assert_kind_of Array, json
    assert_equal 2, json.length
    assert json.any? { |item| item["id"] == "abc111" }
    assert json.any? { |item| item["id"] == "abc222" }
  end

  def test_list_json_output_includes_all_fields
    create_test_items

    output = capture_cli_output { run_list_command(format: "json") }

    json = JSON.parse(output)
    item = json.find { |i| i["id"] == "abc111" }

    assert_equal "abc111", item["id"]
    assert_equal "First finding", item["title"]
    assert_equal "draft", item["status"]
    assert_equal "high", item["priority"]
    assert_includes item.keys, "finding"
    assert_includes item.keys, "created"
  end

  # ============================================================================
  # Session Flag Tests
  # ============================================================================

  def test_list_with_session_flag_uses_session_path
    # Create a session directory structure
    session_dir = File.join(@temp_dir, "sessions", "review-abc123")
    session_feedback_dir = File.join(session_dir, "feedback")
    FileUtils.mkdir_p(session_feedback_dir)

    # Create feedback items in the session
    writer = Ace::Review::Molecules::FeedbackFileWriter.new
    item = create_test_item(id: "sess01", title: "Session item", status: "draft")
    writer.write(item, session_feedback_dir)

    output = capture_cli_output do
      cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::List.new
      cmd.call(session: session_dir)
    end

    assert_match(/sess01/, output)
    assert_match(/Session item/, output)
  end

  def test_list_with_session_flag_errors_on_nonexistent_path
    assert_raises(Ace::Core::CLI::Error) do
      cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::List.new
      cmd.call(session: "/nonexistent/session/path")
    end
  end

  # ============================================================================
  # Archived Items Tests
  # ============================================================================

  def test_list_excludes_archived_by_default
    create_test_items
    create_archived_items

    output = capture_cli_output { run_list_command }

    assert_match(/abc111/, output)
    refute_match(/done01/, output)
    refute_match(/skip01/, output)
  end

  def test_list_includes_archived_when_requested
    create_test_items
    create_archived_items

    output = capture_cli_output { run_list_command(archived: true) }

    assert_match(/abc111/, output)
    assert_match(/done01/, output)
    assert_match(/skip01/, output)
  end

  # ============================================================================
  # Helper Methods
  # ============================================================================

  private

  def run_list_command(**options)
    cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::List.new
    cmd.call(session: @temp_dir, **options)
  end

  def capture_cli_output
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end

  def create_test_item(id:, title:, status: "draft", priority: "medium")
    Ace::Review::Models::FeedbackItem.new(
      id: id,
      title: title,
      files: ["test.rb:10-20"],
      reviewer: "google:gemini-2.5-flash",
      status: status,
      priority: priority,
      finding: "Test finding for #{title}",
      created: Time.now.utc.iso8601,
      updated: Time.now.utc.iso8601
    )
  end

  def create_test_items
    writer = Ace::Review::Molecules::FeedbackFileWriter.new

    items = [
      create_test_item(id: "abc111", title: "First finding", status: "draft", priority: "high"),
      create_test_item(id: "abc222", title: "Second finding", status: "pending", priority: "medium")
    ]

    items.each { |item| writer.write(item, @feedback_dir) }
  end

  def create_test_items_mixed
    writer = Ace::Review::Molecules::FeedbackFileWriter.new

    items = [
      create_test_item(id: "abc111", title: "First", status: "draft", priority: "high"),
      create_test_item(id: "abc222", title: "Second", status: "draft", priority: "medium"),
      create_test_item(id: "abc333", title: "Third", status: "pending", priority: "high")
    ]

    items.each { |item| writer.write(item, @feedback_dir) }
  end

  def create_archived_items
    archive_dir = File.join(@feedback_dir, "_archived")
    FileUtils.mkdir_p(archive_dir)

    writer = Ace::Review::Molecules::FeedbackFileWriter.new

    items = [
      create_test_item(id: "done01", title: "Done item", status: "done", priority: "low"),
      create_test_item(id: "skip01", title: "Skipped item", status: "skip", priority: "low")
    ]

    items.each { |item| writer.write(item, archive_dir) }
  end
end
