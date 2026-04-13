# frozen_string_literal: true

require "test_helper"

class FeedbackManagerTest < AceReviewTest
  def self.use_shared_temp_dir?
    true
  end

  def setup
    super
    @temp_dir = @test_dir
    @manager = Ace::Review::Organisms::FeedbackManager.new
  end

  def teardown
    super
  end

  # ============================================================================
  # Extract and Save Tests
  # ============================================================================

  def test_extract_and_save_with_reports
    # Create mock report
    report_path = File.join(@temp_dir, "review-report.md")
    File.write(report_path, <<~MARKDOWN)
      # Review Report

      ## Finding 1
      Missing error handling in user controller.

      ## Finding 2
      SQL injection vulnerability in query builder.
    MARKDOWN

    # Create mock synthesizer that returns items
    mock_synthesizer = Minitest::Mock.new
    mock_synthesizer.expect(:synthesize, {
      success: true,
      items: [
        create_test_item(id: "abc123", title: "Missing error handling"),
        create_test_item(id: "def456", title: "SQL injection vulnerability")
      ],
      metadata: {total_findings: 2, consensus_findings: 0, reviewers_count: 1}
    }) do |**kwargs|
      kwargs[:report_paths] == [report_path] &&
        kwargs[:model].nil?
    end

    manager = Ace::Review::Organisms::FeedbackManager.new(synthesizer: mock_synthesizer)

    result = manager.extract_and_save(
      report_paths: [report_path],
      base_path: @temp_dir
    )

    assert result[:success], "Should succeed: #{result[:error]}"
    assert_equal 2, result[:items_count]
    assert_equal 2, result[:paths].length

    # Verify files were created
    result[:paths].each do |path|
      assert File.exist?(path), "File should exist: #{path}"
    end

    # Verify items were saved as draft status
    feedback_dir = File.join(@temp_dir, "feedback")
    items = Ace::Review::Molecules::FeedbackFileReader.new.read_all(feedback_dir)
    assert_equal 2, items.length
    items.each { |item| assert_equal "draft", item.status }

    mock_synthesizer.verify
  end

  def test_extract_and_save_with_empty_reports
    mock_synthesizer = Minitest::Mock.new
    mock_synthesizer.expect(:synthesize, {
      success: true,
      items: [],
      metadata: {total_findings: 0, consensus_findings: 0, reviewers_count: 1}
    }) do |**kwargs|
      kwargs[:report_paths] == ["/fake/path.md"]
    end

    manager = Ace::Review::Organisms::FeedbackManager.new(synthesizer: mock_synthesizer)

    result = manager.extract_and_save(
      report_paths: ["/fake/path.md"],
      base_path: @temp_dir
    )

    assert result[:success]
    assert_equal 0, result[:items_count]
    assert_empty result[:paths]

    mock_synthesizer.verify
  end

  def test_extract_and_save_with_extraction_failure
    mock_synthesizer = Minitest::Mock.new
    mock_synthesizer.expect(:synthesize, {
      success: false,
      error: "LLM synthesis failed"
    }) do |**kwargs|
      kwargs[:report_paths] == ["/fake/path.md"]
    end

    manager = Ace::Review::Organisms::FeedbackManager.new(synthesizer: mock_synthesizer)

    result = manager.extract_and_save(
      report_paths: ["/fake/path.md"],
      base_path: @temp_dir
    )

    refute result[:success]
    assert_equal "LLM synthesis failed", result[:error]

    mock_synthesizer.verify
  end

  def test_extract_and_save_with_model
    mock_synthesizer = Minitest::Mock.new
    mock_synthesizer.expect(:synthesize, {
      success: true,
      items: [create_test_item(id: "abc123", title: "Test finding")],
      metadata: {total_findings: 1, consensus_findings: 0, reviewers_count: 1}
    }) do |**kwargs|
      kwargs[:report_paths] == ["/fake/path.md"] &&
        kwargs[:model] == "openai:gpt-4"
    end

    manager = Ace::Review::Organisms::FeedbackManager.new(synthesizer: mock_synthesizer)

    result = manager.extract_and_save(
      report_paths: ["/fake/path.md"],
      base_path: @temp_dir,
      model: "openai:gpt-4"
    )

    assert result[:success]
    mock_synthesizer.verify
  end

  # ============================================================================
  # List Tests
  # ============================================================================

  def test_list_returns_all_items
    create_feedback_directory_with_items

    items = @manager.list(@temp_dir)

    assert_equal 3, items.length
    # Items should be sorted by ID
    assert_equal %w[abc111 abc222 abc333], items.map(&:id)
  end

  def test_list_filters_by_status
    create_feedback_directory_with_items

    draft_items = @manager.list(@temp_dir, status: "draft")
    pending_items = @manager.list(@temp_dir, status: "pending")

    assert_equal 2, draft_items.length
    assert_equal 1, pending_items.length
    draft_items.each { |item| assert_equal "draft", item.status }
    pending_items.each { |item| assert_equal "pending", item.status }
  end

  def test_list_filters_by_priority
    create_feedback_directory_with_items

    high_items = @manager.list(@temp_dir, priority: "high")
    medium_items = @manager.list(@temp_dir, priority: "medium")

    assert_equal 1, high_items.length
    assert_equal 2, medium_items.length
  end

  def test_list_filters_by_status_and_priority
    create_feedback_directory_with_items

    items = @manager.list(@temp_dir, status: "draft", priority: "medium")

    assert_equal 1, items.length
    assert_equal "draft", items.first.status
    assert_equal "medium", items.first.priority
  end

  def test_list_returns_empty_for_nonexistent_directory
    items = @manager.list("/nonexistent/path")

    assert_empty items
  end

  # ============================================================================
  # Find Tests
  # ============================================================================

  def test_find_returns_item_by_id
    create_feedback_directory_with_items

    item = @manager.find(@temp_dir, "abc222")

    refute_nil item
    assert_equal "abc222", item.id
    assert_equal "Second finding", item.title
  end

  def test_find_returns_nil_for_nonexistent_id
    create_feedback_directory_with_items

    item = @manager.find(@temp_dir, "xyz999")

    assert_nil item
  end

  def test_find_returns_nil_for_nonexistent_directory
    item = @manager.find("/nonexistent/path", "abc123")

    assert_nil item
  end

  # ============================================================================
  # Stats Tests
  # ============================================================================

  def test_stats_counts_by_status
    create_feedback_directory_with_items
    # Create some archived items
    create_archived_items

    stats = @manager.stats(@temp_dir)

    assert_equal 2, stats[:draft]
    assert_equal 1, stats[:pending]
    assert_equal 1, stats[:done]
    assert_equal 1, stats[:skip]
    assert_equal 0, stats[:invalid]
    assert_equal 5, stats[:total]
  end

  def test_stats_returns_zeros_for_empty_directory
    # Create empty feedback directory
    FileUtils.mkdir_p(File.join(@temp_dir, "feedback"))

    stats = @manager.stats(@temp_dir)

    assert_equal 0, stats[:draft]
    assert_equal 0, stats[:pending]
    assert_equal 0, stats[:invalid]
    assert_equal 0, stats[:skip]
    assert_equal 0, stats[:done]
    assert_equal 0, stats[:total]
  end

  # ============================================================================
  # Verify Tests
  # ============================================================================

  def test_verify_valid_transitions_draft_to_pending
    create_feedback_directory_with_items

    result = @manager.verify(@temp_dir, "abc111", valid: true, research: "Confirmed issue exists")

    assert result[:success], "Should succeed: #{result[:error]}"
    assert_equal "pending", result[:item].status
    assert_equal "Confirmed issue exists", result[:item].research

    # Verify file was updated but not archived (pending is not terminal)
    feedback_dir = File.join(@temp_dir, "feedback")
    files = Dir.glob(File.join(feedback_dir, "abc111-*.s.md"))
    assert_equal 1, files.length
  end

  def test_verify_invalid_transitions_draft_to_invalid_and_archives
    create_feedback_directory_with_items

    result = @manager.verify(@temp_dir, "abc111", valid: false, research: "False positive")

    assert result[:success]
    assert_equal "invalid", result[:item].status
    assert_equal "False positive", result[:item].research

    # Verify file was archived
    archive_dir = File.join(@temp_dir, "feedback", "_archived")
    archived_files = Dir.glob(File.join(archive_dir, "abc111-*.s.md"))
    assert_equal 1, archived_files.length
  end

  def test_verify_fails_for_nonexistent_item
    create_feedback_directory_with_items

    result = @manager.verify(@temp_dir, "xyz999", valid: true)

    refute result[:success]
    assert_match(/not found/, result[:error])
  end

  def test_verify_fails_for_invalid_transition
    create_feedback_directory_with_items

    # abc333 is already "pending", cannot verify again
    result = @manager.verify(@temp_dir, "abc333", valid: true)

    refute result[:success]
    assert_match(/Invalid transition from 'pending' to 'pending'/, result[:error])
  end

  def test_verify_skip_from_draft_archives_item
    create_feedback_directory_with_items

    result = @manager.verify(@temp_dir, "abc111", skip: true, research: "Out of scope")

    assert result[:success]
    assert_equal "skip", result[:item].status
    assert_equal "Out of scope", result[:item].research

    # Verify file was archived
    archive_dir = File.join(@temp_dir, "feedback", "_archived")
    archived_files = Dir.glob(File.join(archive_dir, "abc111-*.s.md"))
    assert_equal 1, archived_files.length
  end

  def test_verify_skip_from_pending_archives_item
    create_feedback_directory_with_items

    # abc333 is "pending"
    result = @manager.verify(@temp_dir, "abc333", skip: true, research: "Won't fix")

    assert result[:success]
    assert_equal "skip", result[:item].status

    # Verify file was archived
    archive_dir = File.join(@temp_dir, "feedback", "_archived")
    archived_files = Dir.glob(File.join(archive_dir, "abc333-*.s.md"))
    assert_equal 1, archived_files.length
  end

  def test_verify_rejects_both_valid_and_skip
    create_feedback_directory_with_items

    result = @manager.verify(@temp_dir, "abc111", valid: true, skip: true)

    refute result[:success]
    assert_match(/Cannot specify both valid: and skip:/, result[:error])
  end

  def test_verify_rejects_both_invalid_and_skip
    create_feedback_directory_with_items

    result = @manager.verify(@temp_dir, "abc111", valid: false, skip: true)

    refute result[:success]
    assert_match(/Cannot specify both valid: and skip:/, result[:error])
  end

  def test_verify_requires_valid_or_skip_mode
    create_feedback_directory_with_items

    result = @manager.verify(@temp_dir, "abc111")

    refute result[:success]
    assert_match(/Must specify either valid: or skip:/, result[:error])
  end

  # ============================================================================
  # Skip Tests
  # ============================================================================

  def test_skip_from_draft_archives_item
    create_feedback_directory_with_items

    result = @manager.skip(@temp_dir, "abc111", reason: "Out of scope")

    assert result[:success]
    assert_equal "skip", result[:item].status
    assert_equal "Out of scope", result[:item].research

    # Verify file was archived
    archive_dir = File.join(@temp_dir, "feedback", "_archived")
    archived_files = Dir.glob(File.join(archive_dir, "abc111-*.s.md"))
    assert_equal 1, archived_files.length
  end

  def test_skip_from_pending_archives_item
    create_feedback_directory_with_items

    # abc333 is "pending"
    result = @manager.skip(@temp_dir, "abc333", reason: "Won't fix")

    assert result[:success]
    assert_equal "skip", result[:item].status

    # Verify file was archived
    archive_dir = File.join(@temp_dir, "feedback", "_archived")
    archived_files = Dir.glob(File.join(archive_dir, "abc333-*.s.md"))
    assert_equal 1, archived_files.length
  end

  def test_skip_fails_for_done_item
    create_feedback_directory_with_items
    create_archived_items

    # Try to skip a done item (from archive)
    # Note: skip only looks in active directory, so this should fail with "not found"
    result = @manager.skip(@temp_dir, "done01")

    refute result[:success]
    assert_match(/not found/, result[:error])
  end

  # ============================================================================
  # Resolve Tests
  # ============================================================================

  def test_resolve_transitions_pending_to_done_and_archives
    create_feedback_directory_with_items

    # abc333 is "pending"
    result = @manager.resolve(@temp_dir, "abc333", resolution: "Fixed in commit abc123")

    assert result[:success]
    assert_equal "done", result[:item].status
    assert_equal "Fixed in commit abc123", result[:item].resolution

    # Verify file was archived
    archive_dir = File.join(@temp_dir, "feedback", "_archived")
    archived_files = Dir.glob(File.join(archive_dir, "abc333-*.s.md"))
    assert_equal 1, archived_files.length
  end

  def test_resolve_fails_from_draft
    create_feedback_directory_with_items

    # abc111 is "draft", cannot resolve directly
    result = @manager.resolve(@temp_dir, "abc111", resolution: "Fixed")

    refute result[:success]
    assert_match(/Invalid transition from 'draft' to 'done'/, result[:error])
  end

  def test_resolve_fails_for_nonexistent_item
    create_feedback_directory_with_items

    result = @manager.resolve(@temp_dir, "xyz999", resolution: "Fixed")

    refute result[:success]
    assert_match(/not found/, result[:error])
  end

  # ============================================================================
  # State Machine Tests
  # ============================================================================

  def test_full_workflow_draft_to_pending_to_done
    create_feedback_directory_with_items

    # Step 1: Verify draft -> pending
    verify_result = @manager.verify(@temp_dir, "abc111", valid: true, research: "Verified")
    assert verify_result[:success]
    assert_equal "pending", verify_result[:item].status

    # Step 2: Resolve pending -> done
    resolve_result = @manager.resolve(@temp_dir, "abc111", resolution: "Fixed it")
    assert resolve_result[:success]
    assert_equal "done", resolve_result[:item].status

    # Verify item is now archived
    archive_dir = File.join(@temp_dir, "feedback", "_archived")
    archived_files = Dir.glob(File.join(archive_dir, "abc111-*.s.md"))
    assert_equal 1, archived_files.length

    # Verify active directory no longer has this item
    feedback_dir = File.join(@temp_dir, "feedback")
    active_files = Dir.glob(File.join(feedback_dir, "abc111-*.s.md"))
    assert_empty active_files
  end

  def test_invalid_transition_done_to_pending
    # Create a done item in archive
    create_archived_items

    # Try to access via find (which only looks in active dir)
    item = @manager.find(@temp_dir, "done01")
    assert_nil item, "Done items should not be in active directory"
  end

  # ============================================================================
  # Error Handling Tests
  # ============================================================================

  def test_handles_write_failure_gracefully
    # Create a read-only directory
    feedback_dir = File.join(@temp_dir, "feedback")
    FileUtils.mkdir_p(feedback_dir)

    # Create mock file writer that fails
    mock_writer = Minitest::Mock.new
    mock_writer.expect(:write, {success: false, error: "Permission denied"}) do |item, dir|
      item.is_a?(Ace::Review::Models::FeedbackItem) && dir == feedback_dir
    end

    mock_synthesizer = Minitest::Mock.new
    mock_synthesizer.expect(:synthesize, {
      success: true,
      items: [create_test_item(id: "abc123", title: "Test")],
      metadata: {total_findings: 1, consensus_findings: 0, reviewers_count: 1}
    }) do |**kwargs|
      kwargs[:report_paths] == ["/fake/path.md"]
    end

    manager = Ace::Review::Organisms::FeedbackManager.new(
      synthesizer: mock_synthesizer,
      file_writer: mock_writer
    )

    result = manager.extract_and_save(
      report_paths: ["/fake/path.md"],
      base_path: @temp_dir
    )

    refute result[:success]
    assert_match(/Permission denied/, result[:error])

    mock_synthesizer.verify
    mock_writer.verify
  end

  def test_partial_write_success_reports_warnings
    # Create feedback directory
    feedback_dir = File.join(@temp_dir, "feedback")
    FileUtils.mkdir_p(feedback_dir)

    # Create real writer for first, mock writer that fails for second
    item1 = create_test_item(id: "abc111", title: "First finding")
    item2 = create_test_item(id: "abc222", title: "Second finding")

    # Need a custom approach - use real writer but track calls
    original_write = Ace::Review::Molecules::FeedbackFileWriter.instance_method(:write)

    custom_writer = Class.new(Ace::Review::Molecules::FeedbackFileWriter) do
      define_method(:write) do |item, dir|
        # Fail on second call
        if item.id == "abc222"
          {success: false, error: "Disk full"}
        else
          original_write.bind_call(self, item, dir)
        end
      end
    end.new

    mock_synthesizer = Minitest::Mock.new
    mock_synthesizer.expect(:synthesize, {
      success: true,
      items: [item1, item2],
      metadata: {total_findings: 2, consensus_findings: 0, reviewers_count: 1}
    }) do |**kwargs|
      kwargs[:report_paths] == ["/fake/path.md"]
    end

    manager = Ace::Review::Organisms::FeedbackManager.new(
      synthesizer: mock_synthesizer,
      file_writer: custom_writer
    )

    result = manager.extract_and_save(
      report_paths: ["/fake/path.md"],
      base_path: @temp_dir
    )

    assert result[:success], "Should succeed with partial writes"
    assert_equal 1, result[:items_count]
    assert result[:warnings]
    assert_match(/Disk full/, result[:warnings].first)

    mock_synthesizer.verify
  end

  # ============================================================================
  # Helper Methods
  # ============================================================================

  private

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

  def create_feedback_directory_with_items
    feedback_dir = File.join(@temp_dir, "feedback")
    FileUtils.mkdir_p(feedback_dir)

    writer = Ace::Review::Molecules::FeedbackFileWriter.new

    # Create items with different statuses and priorities
    items = [
      create_test_item(id: "abc111", title: "First finding", status: "draft", priority: "high"),
      create_test_item(id: "abc222", title: "Second finding", status: "draft", priority: "medium"),
      create_test_item(id: "abc333", title: "Third finding", status: "pending", priority: "medium")
    ]

    items.each { |item| writer.write(item, feedback_dir) }
  end

  def create_archived_items
    archive_dir = File.join(@temp_dir, "feedback", "_archived")
    FileUtils.mkdir_p(archive_dir)

    writer = Ace::Review::Molecules::FeedbackFileWriter.new

    items = [
      create_test_item(id: "done01", title: "Done item", status: "done", priority: "low"),
      create_test_item(id: "skip01", title: "Skipped item", status: "skip", priority: "low")
    ]

    items.each { |item| writer.write(item, archive_dir) }
  end
end
