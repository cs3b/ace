# frozen_string_literal: true

require "test_helper"
require "json"

class FeedbackListCommandTest < AceReviewTest
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

  def test_list_filters_by_priority_range_medium_plus
    create_test_items_all_priorities

    output = capture_cli_output { run_list_command(priority: "medium+") }

    assert_match(/crit01/, output)  # critical matches medium+
    assert_match(/high01/, output)  # high matches medium+
    assert_match(/med001/, output)  # medium matches medium+
    refute_match(/low001/, output)  # low does not match medium+
  end

  def test_list_filters_by_priority_range_high_plus
    create_test_items_all_priorities

    output = capture_cli_output { run_list_command(priority: "high+") }

    assert_match(/crit01/, output)  # critical matches high+
    assert_match(/high01/, output)  # high matches high+
    refute_match(/med001/, output)  # medium does not match high+
    refute_match(/low001/, output)  # low does not match high+
  end

  def test_list_filters_by_priority_range_critical_plus
    create_test_items_all_priorities

    output = capture_cli_output { run_list_command(priority: "critical+") }

    assert_match(/crit01/, output)  # critical matches critical+
    refute_match(/high01/, output)  # high does not match critical+
    refute_match(/med001/, output)  # medium does not match critical+
    refute_match(/low001/, output)  # low does not match critical+
  end

  def test_list_filters_by_priority_range_low_plus
    create_test_items_all_priorities

    output = capture_cli_output { run_list_command(priority: "low+") }

    # low+ matches all priorities
    assert_match(/crit01/, output)
    assert_match(/high01/, output)
    assert_match(/med001/, output)
    assert_match(/low001/, output)
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
    assert_raises(Ace::Support::Cli::Error) do
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

  def test_list_shows_archived_hint_in_summary
    create_test_items
    create_archived_items

    output = capture_cli_output { run_list_command }

    assert_match(/Total: 2 item\(s\) \(2 archived\)/, output)
  end

  def test_list_no_archived_hint_when_viewing_archived
    create_test_items
    create_archived_items

    output = capture_cli_output { run_list_command(archived: true) }

    # Should show total without archived hint since we're viewing all
    assert_match(/Total: 4 item\(s\)$/, output)
    refute_match(/archived\)/, output)
  end

  def test_list_shows_archived_message_when_all_archived
    # Only create archived items, no active items
    create_archived_items

    output = capture_cli_output { run_list_command }

    assert_match(/No active feedback items\. 2 archived item\(s\) exist\./, output)
    assert_match(/Use --archived to include them\./, output)
  end

  # ============================================================================
  # Sorting Tests
  # ============================================================================

  def test_list_sorts_by_status_then_id
    create_items_with_mixed_statuses

    output = capture_cli_output { run_list_command }

    # Extract IDs from output in order
    lines = output.lines.select { |l| l.match?(/^[a-z0-9]+\s+(draft|pending|done|skip|invalid)/) }
    ids = lines.map { |l| l.split.first }

    # Expected order: draft first, then pending, then done, skip, invalid
    # Within same status, sorted by ID
    assert_equal %w[drf001 drf002 pnd001 pnd002 don001 skp001 inv001], ids
  end

  # ============================================================================
  # --session all Tests
  # ============================================================================

  def test_list_session_all_aggregates_from_multiple_sessions
    create_multi_session_structure

    output = capture_cli_output do
      cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::List.new
      # Stub find_all_sessions to return our test sessions
      cmd.define_singleton_method(:find_all_sessions) do
        [@session1_dir, @session2_dir]
      end
      cmd.instance_variable_set(:@session1_dir, @session1_dir)
      cmd.instance_variable_set(:@session2_dir, @session2_dir)
      cmd.call(session: "all")
    end

    # Should show SESSION column
    assert_match(/SESSION\s+ID\s+STATUS\s+PRIORITY\s+TITLE/, output)
    # Should show items from both sessions
    assert_match(/sess01/, output)
    assert_match(/sess02/, output)
    assert_match(/review-abc123/, output)
    assert_match(/review-def456/, output)
  end

  def test_list_session_all_shows_empty_when_no_sessions
    # Don't create any sessions
    output = capture_cli_output do
      cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::List.new
      cmd.define_singleton_method(:find_all_sessions) { [] }
      cmd.call(session: "all")
    end

    assert_match(/No sessions found/, output)
  end

  def test_list_session_all_includes_session_column_in_output
    create_multi_session_structure

    output = capture_cli_output do
      cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::List.new
      cmd.define_singleton_method(:find_all_sessions) do
        [@session1_dir, @session2_dir]
      end
      cmd.instance_variable_set(:@session1_dir, @session1_dir)
      cmd.instance_variable_set(:@session2_dir, @session2_dir)
      cmd.call(session: "all")
    end

    # Header should have SESSION column
    assert_match(/^SESSION\s+ID/, output)
    # Separator line should be wider
    assert output.include?("-" * 72)
  end

  def test_list_session_all_filters_by_status
    create_multi_session_structure

    output = capture_cli_output do
      cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::List.new
      cmd.define_singleton_method(:find_all_sessions) do
        [@session1_dir, @session2_dir]
      end
      cmd.instance_variable_set(:@session1_dir, @session1_dir)
      cmd.instance_variable_set(:@session2_dir, @session2_dir)
      cmd.call(session: "all", status: "pending")
    end

    # sess02 is pending, sess01 is draft
    assert_match(/sess02/, output)
    refute_match(/sess01/, output)
  end

  def test_list_session_all_includes_archived_when_requested
    create_multi_session_structure_with_archived

    output = capture_cli_output do
      cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::List.new
      cmd.define_singleton_method(:find_all_sessions) do
        [@session1_dir, @session2_dir]
      end
      cmd.instance_variable_set(:@session1_dir, @session1_dir)
      cmd.instance_variable_set(:@session2_dir, @session2_dir)
      cmd.call(session: "all", archived: true)
    end

    # Should include archived items
    assert_match(/arch01/, output)
  end

  def test_list_session_all_filters_archived_by_priority_range
    create_multi_session_structure_with_archived_priorities

    output = capture_cli_output do
      cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::List.new
      cmd.define_singleton_method(:find_all_sessions) do
        [@session1_dir, @session2_dir]
      end
      cmd.instance_variable_set(:@session1_dir, @session1_dir)
      cmd.instance_variable_set(:@session2_dir, @session2_dir)
      cmd.call(session: "all", archived: true, priority: "high+")
    end

    # Should include high+ priority archived items
    assert_match(/archhi/, output)  # high priority archived
    refute_match(/archlo/, output)  # low priority archived should not match
  end

  def test_list_session_all_json_includes_session_field
    create_multi_session_structure

    output = capture_cli_output do
      cmd = Ace::Review::CLI::Commands::FeedbackSubcommands::List.new
      cmd.define_singleton_method(:find_all_sessions) do
        [@session1_dir, @session2_dir]
      end
      cmd.instance_variable_set(:@session1_dir, @session1_dir)
      cmd.instance_variable_set(:@session2_dir, @session2_dir)
      cmd.call(session: "all", format: "json")
    end

    json = JSON.parse(output)
    assert json.all? { |item| item.key?("session") }
    sessions = json.map { |item| item["session"] }.uniq.sort
    assert_includes sessions, "review-abc123"
    assert_includes sessions, "review-def456"
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

  def create_test_items_all_priorities
    writer = Ace::Review::Molecules::FeedbackFileWriter.new

    items = [
      create_test_item(id: "crit01", title: "Critical item", status: "draft", priority: "critical"),
      create_test_item(id: "high01", title: "High item", status: "draft", priority: "high"),
      create_test_item(id: "med001", title: "Medium item", status: "draft", priority: "medium"),
      create_test_item(id: "low001", title: "Low item", status: "draft", priority: "low")
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

  def create_items_with_mixed_statuses
    writer = Ace::Review::Molecules::FeedbackFileWriter.new

    # Create items in random order to verify sorting
    items = [
      create_test_item(id: "pnd002", title: "Pending 2", status: "pending"),
      create_test_item(id: "inv001", title: "Invalid 1", status: "invalid"),
      create_test_item(id: "drf001", title: "Draft 1", status: "draft"),
      create_test_item(id: "skp001", title: "Skip 1", status: "skip"),
      create_test_item(id: "don001", title: "Done 1", status: "done"),
      create_test_item(id: "pnd001", title: "Pending 1", status: "pending"),
      create_test_item(id: "drf002", title: "Draft 2", status: "draft")
    ]

    items.each { |item| writer.write(item, @feedback_dir) }
  end

  def create_multi_session_structure
    # Create two session directories
    @session1_dir = File.join(@temp_dir, "sessions", "review-abc123")
    @session2_dir = File.join(@temp_dir, "sessions", "review-def456")

    session1_feedback = File.join(@session1_dir, "feedback")
    session2_feedback = File.join(@session2_dir, "feedback")

    FileUtils.mkdir_p(session1_feedback)
    FileUtils.mkdir_p(session2_feedback)

    writer = Ace::Review::Molecules::FeedbackFileWriter.new

    # Items in session 1
    item1 = create_test_item(id: "sess01", title: "Session 1 item", status: "draft")
    writer.write(item1, session1_feedback)

    # Items in session 2
    item2 = create_test_item(id: "sess02", title: "Session 2 item", status: "pending")
    writer.write(item2, session2_feedback)
  end

  def create_multi_session_structure_with_archived
    create_multi_session_structure

    # Add archived item to session 1
    archive_dir = File.join(@session1_dir, "feedback", "_archived")
    FileUtils.mkdir_p(archive_dir)

    writer = Ace::Review::Molecules::FeedbackFileWriter.new
    archived_item = create_test_item(id: "arch01", title: "Archived item", status: "done")
    writer.write(archived_item, archive_dir)
  end

  def create_multi_session_structure_with_archived_priorities
    create_multi_session_structure

    # Add archived items with different priorities to session 1
    archive_dir = File.join(@session1_dir, "feedback", "_archived")
    FileUtils.mkdir_p(archive_dir)

    writer = Ace::Review::Molecules::FeedbackFileWriter.new

    archived_high = create_test_item(id: "archhi", title: "High priority archived", status: "done", priority: "high")
    archived_low = create_test_item(id: "archlo", title: "Low priority archived", status: "done", priority: "low")

    writer.write(archived_high, archive_dir)
    writer.write(archived_low, archive_dir)
  end
end
