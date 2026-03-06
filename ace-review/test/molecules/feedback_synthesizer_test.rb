# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "json"

class FeedbackSynthesizerTest < AceReviewTest
  # Opt into shared temp directory for performance
  def self.use_shared_temp_dir?
    true
  end

  def setup
    super
    @temp_dir = @test_dir
    @session_dir = File.join(@temp_dir, "session")
    FileUtils.mkdir_p(@session_dir)

    # Create mock LLM executor
    @mock_executor = MockLlmExecutor.new
    @synthesizer = Ace::Review::Molecules::FeedbackSynthesizer.new(llm_executor: @mock_executor)
  end

  def teardown
    super
  end

  # ============================================================================
  # Single Report Tests
  # ============================================================================

  def test_synthesize_single_report
    report_path = create_report_file("review-report-gemini-2.5-flash.md", sample_report_content)

    @mock_executor.set_response(single_report_response)

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    assert result[:success], "Expected synthesis to succeed: #{result[:error]}"
    assert_equal 2, result[:items].length
    assert_equal 2, result[:metadata][:total_findings]
  end

  def test_synthesize_extracts_reviewer_from_filename
    report_path = create_report_file("review-report-gemini-2.5-flash.md", sample_report_content)

    @mock_executor.set_response(single_report_response)

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    assert result[:success]
    # Single report items should have one reviewer
    item = result[:items].first
    assert_equal ["google:gemini-2.5-flash"], item.reviewers
    refute item.consensus  # Single reviewer = no consensus
  end

  # ============================================================================
  # Multi-Report Synthesis Tests
  # ============================================================================

  def test_synthesize_multiple_reports
    report1 = create_report_file("review-report-gemini-2.5-flash.md", sample_report_content)
    report2 = create_report_file("review-report-claude-3.5-sonnet.md", sample_report_content)
    report3 = create_report_file("review-report-gpt-4.md", sample_report_content)

    @mock_executor.set_response(multi_report_response)

    result = @synthesizer.synthesize(
      report_paths: [report1, report2, report3],
      session_dir: @session_dir
    )

    assert result[:success], "Expected synthesis to succeed: #{result[:error]}"
    assert_equal 2, result[:items].length
    assert_equal 3, result[:metadata][:reviewers_count]
  end

  def test_synthesize_tracks_multiple_reviewers
    report1 = create_report_file("review-report-gemini.md", sample_report_content)
    report2 = create_report_file("review-report-claude.md", sample_report_content)
    report3 = create_report_file("review-report-gpt.md", sample_report_content)

    @mock_executor.set_response(multi_report_response)

    result = @synthesizer.synthesize(
      report_paths: [report1, report2, report3],
      session_dir: @session_dir
    )

    assert result[:success]

    # Check the SQL injection finding has multiple reviewers
    sql_item = result[:items].find { |i| i.title.include?("SQL injection") }
    refute_nil sql_item
    assert_equal 3, sql_item.reviewers.length
    assert sql_item.consensus  # 3 reviewers = consensus
  end

  def test_synthesize_marks_consensus_correctly
    report1 = create_report_file("review-report-r1.md", sample_report_content)
    report2 = create_report_file("review-report-r2.md", sample_report_content)
    report3 = create_report_file("review-report-r3.md", sample_report_content)

    @mock_executor.set_response(multi_report_response)

    result = @synthesizer.synthesize(
      report_paths: [report1, report2, report3],
      session_dir: @session_dir
    )

    assert result[:success]

    # SQL injection: 3 reviewers -> consensus
    sql_item = result[:items].find { |i| i.title.include?("SQL injection") }
    assert sql_item.consensus

    # Error handling: 2 reviewers -> no consensus
    error_item = result[:items].find { |i| i.title.include?("error handling") }
    refute error_item.consensus
  end

  def test_synthesize_merges_files_from_all_reviewers
    report1 = create_report_file("review-report-r1.md", sample_report_content)
    report2 = create_report_file("review-report-r2.md", sample_report_content)

    @mock_executor.set_response(merged_files_response)

    result = @synthesizer.synthesize(
      report_paths: [report1, report2],
      session_dir: @session_dir
    )

    assert result[:success]

    item = result[:items].first
    # Should have both file references from merged finding
    assert_equal 2, item.files.length
    assert_includes item.files, "src/db/query.rb:42-55"
    assert_includes item.files, "src/db/query.rb:60-70"
  end

  # ============================================================================
  # Error Handling Tests
  # ============================================================================

  def test_synthesize_fails_with_no_report_paths
    result = @synthesizer.synthesize(
      report_paths: nil,
      session_dir: @session_dir
    )

    refute result[:success]
    assert_includes result[:error], "No report paths provided"
  end

  def test_synthesize_fails_with_empty_report_paths
    result = @synthesizer.synthesize(
      report_paths: [],
      session_dir: @session_dir
    )

    refute result[:success]
    assert_includes result[:error], "No report paths provided"
  end

  def test_synthesize_handles_missing_report_file
    result = @synthesizer.synthesize(
      report_paths: ["/nonexistent/report.md"],
      session_dir: @session_dir
    )

    refute result[:success]
    assert_includes result[:error], "No valid reports found"
  end

  def test_synthesize_handles_llm_failure
    report_path = create_report_file("report.md", sample_report_content)

    @mock_executor.set_error("LLM service unavailable")

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    refute result[:success]
    assert_includes result[:error], "LLM synthesis failed"
  end

  def test_synthesize_handles_invalid_json_response
    report_path = create_report_file("report.md", sample_report_content)

    @mock_executor.set_response("This is not valid JSON")

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    refute result[:success]
    assert_includes result[:error], "Invalid JSON"
  end

  def test_synthesize_handles_json_with_markdown_fences
    report_path = create_report_file("report.md", sample_report_content)

    response_with_fences = "```json\n#{single_report_response}\n```"
    @mock_executor.set_response(response_with_fences)

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    assert result[:success], "Should handle JSON with markdown fences: #{result[:error]}"
    assert_equal 2, result[:items].length
  end

  def test_synthesize_handles_text_before_json_fence
    # This is the Claude Opus pattern: conversational text before the JSON code fence
    report_path = create_report_file("report.md", sample_report_content)

    response_with_text_before = <<~RESPONSE
      Based on my analysis of the code review reports, I have identified the following findings:

      ```json
      #{single_report_response}
      ```

      These findings represent the key issues identified in the review.
    RESPONSE
    @mock_executor.set_response(response_with_text_before)

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    assert result[:success], "Should handle text before JSON fence: #{result[:error]}"
    assert_equal 2, result[:items].length
  end

  def test_synthesize_handles_empty_findings_array
    report_path = create_report_file("report.md", sample_report_content)

    @mock_executor.set_response('{"findings": []}')

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    assert result[:success]
    assert_empty result[:items]
  end

  def test_synthesize_skips_findings_without_title
    report_path = create_report_file("report.md", sample_report_content)

    response = {
      findings: [
        { title: "", finding: "Some finding" },
        { title: "Valid title", finding: "Another finding" }
      ]
    }.to_json

    @mock_executor.set_response(response)

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    assert result[:success]
    assert_equal 1, result[:items].length
    assert_equal "Valid title", result[:items].first.title
  end

  # ============================================================================
  # Reviewer Extraction Tests
  # ============================================================================

  def test_reviewer_extraction_gemini_model
    report_path = create_report_file("review-report-gemini-2.5-flash.md", sample_report_content)
    @mock_executor.set_response(single_finding_response_with_reviewer("gemini-2.5-flash"))

    result = @synthesizer.synthesize(report_paths: [report_path], session_dir: @session_dir)

    assert_includes result[:items].first.reviewers, "google:gemini-2.5-flash"
  end

  def test_reviewer_extraction_gpt_model
    report_path = create_report_file("review-report-gpt-4.md", sample_report_content)
    @mock_executor.set_response(single_finding_response_with_reviewer("gpt-4"))

    result = @synthesizer.synthesize(report_paths: [report_path], session_dir: @session_dir)

    assert_includes result[:items].first.reviewers, "openai:gpt-4"
  end

  def test_reviewer_extraction_claude_model
    report_path = create_report_file("review-report-claude-3.5-sonnet.md", sample_report_content)
    @mock_executor.set_response(single_finding_response_with_reviewer("claude-3.5-sonnet"))

    result = @synthesizer.synthesize(report_paths: [report_path], session_dir: @session_dir)

    assert_includes result[:items].first.reviewers, "anthropic:claude-3.5-sonnet"
  end

  def test_reviewer_extraction_dev_feedback
    report_path = create_report_file("review-dev-feedback.md", sample_report_content)
    @mock_executor.set_response(single_finding_response_with_reviewer("developer"))

    result = @synthesizer.synthesize(report_paths: [report_path], session_dir: @session_dir)

    assert_includes result[:items].first.reviewers, "developer"
  end

  def test_read_reports_prefers_run_key_over_reviewer_name
    require "ace/review/models/reviewer"
    report1 = create_report_file("review-report-gemini-2.5-flash.md", sample_report_content)
    report2 = create_report_file("review-report-gemini-2.5-flash-2.md", sample_report_content)

    reviewer1 = Ace::Review::Models::Reviewer.new(name: "correctness", model: "google:gemini-2.5-flash", weight: 1.0)
    reviewer2 = Ace::Review::Models::Reviewer.new(name: "correctness", model: "google:gemini-2.5-flash", weight: 0.5)

    reports = @synthesizer.send(:read_reports, [
      { path: report1, reviewer: reviewer1, run_key: "correctness:google-gemini:1" },
      { path: report2, reviewer: reviewer2, run_key: "correctness:google-gemini:2" }
    ])

    assert_equal 2, reports.length
    assert_equal "correctness:google-gemini:1", reports[0][:reviewer]
    assert_equal "correctness:google-gemini:2", reports[1][:reviewer]
  end

  def test_reviewer_weight_map_uses_run_key_identity
    require "ace/review/models/reviewer"
    report1 = create_report_file("review-report-gemini-2.5-flash.md", sample_report_content)
    report2 = create_report_file("review-report-gemini-2.5-flash-2.md", sample_report_content)

    reviewer1 = Ace::Review::Models::Reviewer.new(name: "correctness", model: "google:gemini-2.5-flash", weight: 1.0)
    reviewer2 = Ace::Review::Models::Reviewer.new(name: "correctness", model: "google:gemini-2.5-flash", weight: 0.5)

    reports = @synthesizer.send(:read_reports, [
      { path: report1, reviewer: reviewer1, run_key: "correctness:google-gemini:1" },
      { path: report2, reviewer: reviewer2, run_key: "correctness:google-gemini:2" }
    ])

    weights = @synthesizer.send(:build_reviewer_weight_map, reports)

    assert_equal 2, weights.length
    assert_equal 1.0, weights["correctness:google-gemini:1"]
    assert_equal 0.5, weights["correctness:google-gemini:2"]
  end

  def test_full_reviewer_weight_map_prefers_run_key_identity
    require "ace/review/models/reviewer"
    reviewer1 = Ace::Review::Models::Reviewer.new(name: "correctness", model: "google:gemini-2.5-flash", weight: 1.0)
    reviewer2 = Ace::Review::Models::Reviewer.new(name: "correctness", model: "google:gemini-2.5-flash", weight: 0.5)

    descriptors = [
      { path: "/tmp/report-1.md", reviewer: reviewer1, run_key: "correctness:google-gemini:1" },
      { path: "/tmp/report-2.md", reviewer: reviewer2, run_key: "correctness:google-gemini:2" }
    ]

    weights = @synthesizer.send(:build_full_reviewer_weight_map, descriptors)

    assert_equal 2, weights.length
    assert_equal 1.0, weights["correctness:google-gemini:1"]
    assert_equal 0.5, weights["correctness:google-gemini:2"]
  end

  # ============================================================================
  # Priority Tests
  # ============================================================================

  def test_synthesize_normalizes_priority_values
    report_path = create_report_file("report.md", sample_report_content)

    response = {
      findings: [
        { title: "Critical issue", finding: "test", priority: "CRITICAL" },
        { title: "High issue", finding: "test", priority: "High" },
        { title: "Medium issue", finding: "test", priority: "medium" },
        { title: "Low issue", finding: "test", priority: "LOW" }
      ]
    }.to_json

    @mock_executor.set_response(response)

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    assert result[:success]
    priorities = result[:items].map(&:priority)
    assert_equal %w[critical high medium low], priorities
  end

  def test_synthesize_defaults_invalid_priority_to_medium
    report_path = create_report_file("report.md", sample_report_content)

    response = {
      findings: [
        { title: "Unknown priority", finding: "test", priority: "urgent" },
        { title: "Missing priority", finding: "test" }
      ]
    }.to_json

    @mock_executor.set_response(response)

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    assert result[:success]
    assert result[:items].all? { |item| item.priority == "medium" }
  end

  # ============================================================================
  # Unique ID Tests
  # ============================================================================

  def test_synthesize_generates_unique_ids_for_all_items
    report_path = create_report_file("report.md", sample_report_content)

    # Create response with many findings to test uniqueness
    response = {
      findings: (1..20).map do |i|
        {
          title: "Finding #{i}",
          finding: "Description for finding #{i}",
          priority: "medium"
        }
      end
    }.to_json

    @mock_executor.set_response(response)

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    assert result[:success], "Expected synthesis to succeed: #{result[:error]}"
    assert_equal 20, result[:items].length

    # All IDs should be unique
    ids = result[:items].map(&:id)
    assert_equal ids.length, ids.uniq.length,
      "All feedback items should have unique IDs"
  end

  def test_synthesize_generates_sequential_ids
    report_path = create_report_file("report.md", sample_report_content)

    response = {
      findings: (1..5).map do |i|
        {
          title: "Finding #{i}",
          finding: "Description #{i}",
          priority: "medium"
        }
      end
    }.to_json

    @mock_executor.set_response(response)

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    assert result[:success]
    ids = result[:items].map(&:id)

    # IDs should be in ascending order (sequential generation)
    ids.each_cons(2) do |prev_id, curr_id|
      assert prev_id < curr_id,
        "IDs should be strictly increasing: #{prev_id} < #{curr_id}"
    end
  end

  # ============================================================================
  # Session Directory Tests
  # ============================================================================

  def test_synthesize_creates_session_dir_if_needed
    nonexistent_session = File.join(@temp_dir, "new_session")
    report_path = create_report_file("report.md", sample_report_content)

    @mock_executor.set_response(single_report_response)

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: nonexistent_session
    )

    assert result[:success]
    assert Dir.exist?(nonexistent_session)
  end

  def test_synthesize_creates_temp_session_if_not_provided
    report_path = create_report_file("report.md", sample_report_content)

    @mock_executor.set_response(single_report_response)

    result = @synthesizer.synthesize(
      report_paths: [report_path]
      # session_dir not provided
    )

    assert result[:success]
  end

  # ============================================================================
  # Hash Descriptor Input Tests (path: + reviewer: metadata)
  # ============================================================================

  def test_synthesize_accepts_hash_descriptor_with_reviewer_object
    require "ace/review/models/reviewer"
    report_path = create_report_file("review-unknown.md", sample_report_content)
    reviewer = Ace::Review::Models::Reviewer.new(name: "code-fit", model: "google:gemini-2.5-pro", weight: 1.0)

    @mock_executor.set_response(single_report_response)

    result = @synthesizer.synthesize(
      report_paths: [{ path: report_path, reviewer: reviewer }],
      session_dir: @session_dir
    )

    assert result[:success], "Expected synthesis to succeed: #{result[:error]}"
    assert_equal 2, result[:items].length
  end

  def test_synthesize_hash_descriptor_uses_reviewer_name_not_filename
    require "ace/review/models/reviewer"
    # filename would infer "gemini" model, but reviewer name should win
    report_path = create_report_file("review-gemini-something.md", sample_report_content)
    reviewer = Ace::Review::Models::Reviewer.new(name: "custom-reviewer", model: "anthropic:claude-3-5-sonnet", weight: 1.0)

    @mock_executor.set_response(single_finding_response_with_reviewer("custom-reviewer"))

    result = @synthesizer.synthesize(
      report_paths: [{ path: report_path, reviewer: reviewer }],
      session_dir: @session_dir
    )

    assert result[:success]
    assert_equal 1, result[:items].length
    # The reviewer label should be the reviewer's name, not inferred from filename
    assert_equal ["custom-reviewer"], result[:items].first.reviewers
  end

  def test_synthesize_mixed_string_and_hash_descriptors
    require "ace/review/models/reviewer"
    string_path = create_report_file("review-report-gemini-2.5-flash.md", sample_report_content)
    hash_path = create_report_file("review-unknown-model.md", sample_report_content)
    reviewer = Ace::Review::Models::Reviewer.new(name: "code-shine", model: "anthropic:claude-3-5-sonnet", weight: 0.8)

    @mock_executor.set_response(multi_report_response)

    result = @synthesizer.synthesize(
      report_paths: [string_path, { path: hash_path, reviewer: reviewer }],
      session_dir: @session_dir
    )

    assert result[:success]
    assert_equal 2, result[:metadata][:reviewers_count]
  end

  def test_synthesize_hash_descriptor_with_string_reviewer
    report_path = create_report_file("review-unknown.md", sample_report_content)

    @mock_executor.set_response(single_report_response)

    result = @synthesizer.synthesize(
      report_paths: [{ path: report_path, reviewer: "my-custom-reviewer" }],
      session_dir: @session_dir
    )

    assert result[:success]
    assert_equal 2, result[:items].length
  end

  def test_synthesize_hash_descriptor_skips_missing_file
    @mock_executor.set_response(single_report_response)

    result = @synthesizer.synthesize(
      report_paths: [{ path: "/nonexistent/path.md", reviewer: "r1" }],
      session_dir: @session_dir
    )

    assert_equal false, result[:success]
    assert_match(/No valid reports/, result[:error])
  end

  # ============================================================================
  # Weight-Aware Confidence and Consensus Tests
  # ============================================================================

  def test_synthesize_full_agreement_produces_confidence_1
    require "ace/review/models/reviewer"
    r1 = Ace::Review::Models::Reviewer.new(name: "r1", model: "google:gemini-2.5-pro", weight: 1.0)
    r2 = Ace::Review::Models::Reviewer.new(name: "r2", model: "anthropic:claude-3-5-sonnet", weight: 1.0)

    p1 = create_report_file("review-r1.md", sample_report_content)
    p2 = create_report_file("review-r2.md", sample_report_content)

    # Both reviewers agree on the finding
    @mock_executor.set_response(two_reviewer_full_agreement_response("r1", "r2"))

    result = @synthesizer.synthesize(
      report_paths: [
        { path: p1, reviewer: r1 },
        { path: p2, reviewer: r2 }
      ],
      session_dir: @session_dir
    )

    assert result[:success], result[:error]
    item = result[:items].first
    assert_in_delta 1.0, item.confidence, 0.001
    assert item.consensus, "Confidence 1.0 should trigger consensus at default 0.6 threshold"
  end

  def test_synthesize_partial_agreement_produces_fractional_confidence
    require "ace/review/models/reviewer"
    r1 = Ace::Review::Models::Reviewer.new(name: "r1", model: "google:gemini-2.5-pro", weight: 1.0)
    r2 = Ace::Review::Models::Reviewer.new(name: "r2", model: "anthropic:claude-3-5-sonnet", weight: 1.0)

    p1 = create_report_file("review-r1-partial.md", sample_report_content)
    p2 = create_report_file("review-r2-partial.md", sample_report_content)

    # Only r1 agrees with the finding (0.5 weight / 1.0 total)
    @mock_executor.set_response(single_finding_response_with_reviewer("r1"))

    result = @synthesizer.synthesize(
      report_paths: [
        { path: p1, reviewer: r1 },
        { path: p2, reviewer: r2 }
      ],
      session_dir: @session_dir
    )

    assert result[:success], result[:error]
    item = result[:items].first
    assert_in_delta 0.5, item.confidence, 0.001
    refute item.consensus, "Confidence 0.5 should be below default 0.6 threshold"
  end

  def test_synthesize_single_reviewer_with_weight_produces_confidence_1
    require "ace/review/models/reviewer"
    reviewer = Ace::Review::Models::Reviewer.new(name: "solo", model: "google:gemini-2.5-pro", weight: 1.0)
    p1 = create_report_file("review-solo-w.md", sample_report_content)

    @mock_executor.set_response(single_finding_response_with_reviewer("solo"))

    result = @synthesizer.synthesize(
      report_paths: [{ path: p1, reviewer: reviewer }],
      session_dir: @session_dir
    )

    assert result[:success], result[:error]
    item = result[:items].first
    assert_in_delta 1.0, item.confidence, 0.001
  end

  def test_synthesize_no_metadata_produces_nil_confidence
    report_path = create_report_file("review-report-gemini-2.5-flash.md", sample_report_content)

    @mock_executor.set_response(single_report_response)

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    assert result[:success], result[:error]
    result[:items].each do |item|
      assert_nil item.confidence, "Legacy path should produce nil confidence"
    end
  end

  def test_synthesize_no_metadata_uses_count_based_consensus
    p1 = create_report_file("review-r1-legacy.md", sample_report_content)
    p2 = create_report_file("review-r2-legacy.md", sample_report_content)
    p3 = create_report_file("review-r3-legacy.md", sample_report_content)

    # Three reviewers agree — count-based consensus (CONSENSUS_THRESHOLD = 3)
    response = {
      findings: [{
        title: "SQL injection",
        files: ["src/db.rb"],
        reviewers: ["r1", "r2", "r3"],
        consensus: false,
        priority: "critical",
        finding: "SQL injection found"
      }]
    }.to_json

    @mock_executor.set_response(response)

    result = @synthesizer.synthesize(
      report_paths: [p1, p2, p3],
      session_dir: @session_dir
    )

    assert result[:success], result[:error]
    assert result[:items].first.consensus, "3+ reviewers should trigger count-based consensus"
    assert_nil result[:items].first.confidence
  end

  # ============================================================================
  # Critical/Focus Metadata Ordering Tests
  # ============================================================================

  def test_synthesize_surfaces_critical_findings_first_when_metadata_available
    require "ace/review/models/reviewer"
    critical_reviewer = Ace::Review::Models::Reviewer.new(
      name: "security",
      model: "google:gemini-2.5-pro",
      critical: true,
      focus: "security"
    )
    normal_reviewer = Ace::Review::Models::Reviewer.new(
      name: "quality",
      model: "anthropic:claude-3-5-sonnet",
      critical: false,
      focus: "quality"
    )

    p1 = create_report_file("review-security.md", sample_report_content)
    p2 = create_report_file("review-quality.md", sample_report_content)

    @mock_executor.set_response({
      findings: [
        {
          title: "Improve naming",
          reviewers: ["quality"],
          priority: "critical",
          finding: "Naming can be clearer."
        },
        {
          title: "Patch auth bypass",
          reviewers: ["security"],
          priority: "high",
          finding: "Authentication bypass detected."
        }
      ]
    }.to_json)

    result = @synthesizer.synthesize(
      report_paths: [
        { path: p1, reviewer: critical_reviewer },
        { path: p2, reviewer: normal_reviewer }
      ],
      session_dir: @session_dir
    )

    assert result[:success], result[:error]
    assert_equal "Patch auth bypass", result[:items][0].title
    assert_equal true, result[:items][0].critical_source
    assert_equal "security", result[:items][0].focus
    assert_equal false, result[:items][1].critical_source
  end

  def test_synthesize_groups_noncritical_findings_by_focus_and_puts_nil_focus_last
    require "ace/review/models/reviewer"
    quality = Ace::Review::Models::Reviewer.new(name: "quality", model: "google:gemini-2.5-pro", focus: "quality")
    security = Ace::Review::Models::Reviewer.new(name: "security", model: "anthropic:claude-3-5-sonnet", focus: "security")
    unfocused = Ace::Review::Models::Reviewer.new(name: "plain", model: "openai:gpt-4")

    p1 = create_report_file("review-quality.md", sample_report_content)
    p2 = create_report_file("review-security.md", sample_report_content)
    p3 = create_report_file("review-plain.md", sample_report_content)

    @mock_executor.set_response({
      findings: [
        { title: "Z nil focus", reviewers: ["plain"], priority: "medium", finding: "No focus metadata." },
        { title: "A security", reviewers: ["security"], priority: "medium", finding: "Security concern." },
        { title: "B quality", reviewers: ["quality"], priority: "medium", finding: "Quality concern." }
      ]
    }.to_json)

    result = @synthesizer.synthesize(
      report_paths: [
        { path: p1, reviewer: quality },
        { path: p2, reviewer: security },
        { path: p3, reviewer: unfocused }
      ],
      session_dir: @session_dir
    )

    assert result[:success], result[:error]
    assert_equal ["B quality", "A security", "Z nil focus"], result[:items].map(&:title)
    assert_equal [false, false, false], result[:items].map(&:critical_source)
    assert_equal ["quality", "security", nil], result[:items].map(&:focus)
  end

  def test_synthesize_missing_reviewer_report_reduces_confidence
    # When a configured reviewer's report file is absent, their weight should
    # still count in the denominator, reducing confidence for the finding.
    require "ace/review/models/reviewer"
    r1 = Ace::Review::Models::Reviewer.new(name: "heavy", model: "google:gemini-2.5-pro", weight: 0.8)
    r2 = Ace::Review::Models::Reviewer.new(name: "light", model: "anthropic:claude-3-5-sonnet", weight: 0.2)

    # Only r2 returns a report; r1's file does not exist
    p2 = create_report_file("review-missing-r2.md", sample_report_content)
    missing_path = File.join(@temp_dir, "review-missing-r1.md")  # not created

    @mock_executor.set_response(single_finding_response_with_reviewer("light"))

    result = @synthesizer.synthesize(
      report_paths: [
        { path: missing_path, reviewer: r1 },
        { path: p2, reviewer: r2 }
      ],
      session_dir: @session_dir
    )

    assert result[:success], result[:error]
    item = result[:items].first
    # r2 agrees (weight 0.2), total configured weight = 1.0 → confidence = 0.2
    assert_in_delta 0.2, item.confidence, 0.001
    refute item.consensus, "Confidence 0.2 should be below default 0.6 threshold"
  end

  def test_synthesize_respects_non_default_consensus_threshold
    require "ace/review/models/reviewer"
    r1 = Ace::Review::Models::Reviewer.new(name: "r1", model: "google:gemini-2.5-pro", weight: 1.0)
    r2 = Ace::Review::Models::Reviewer.new(name: "r2", model: "anthropic:claude-3-5-sonnet", weight: 1.0)

    p1 = create_report_file("review-thresh-r1.md", sample_report_content)
    p2 = create_report_file("review-thresh-r2.md", sample_report_content)

    # Only r1 finds the issue → confidence 0.5
    @mock_executor.set_response(single_finding_response_with_reviewer("r1"))

    # Stub threshold to 0.4 so confidence 0.5 triggers consensus
    @synthesizer.stub(:consensus_threshold, 0.4) do
      result = @synthesizer.synthesize(
        report_paths: [
          { path: p1, reviewer: r1 },
          { path: p2, reviewer: r2 }
        ],
        session_dir: @session_dir
      )

      assert result[:success], result[:error]
      item = result[:items].first
      assert_in_delta 0.5, item.confidence, 0.001
      assert item.consensus, "Confidence 0.5 should exceed lowered threshold 0.4"
    end
  end

  def test_synthesize_reloads_consensus_threshold_each_call
    require "ace/review/models/reviewer"
    r1 = Ace::Review::Models::Reviewer.new(name: "r1", model: "google:gemini-2.5-pro", weight: 1.0)
    r2 = Ace::Review::Models::Reviewer.new(name: "r2", model: "anthropic:claude-3-5-sonnet", weight: 1.0)

    p1 = create_report_file("review-dynamic-r1.md", sample_report_content)
    p2 = create_report_file("review-dynamic-r2.md", sample_report_content)

    @mock_executor.set_response(single_finding_response_with_reviewer("r1"))

    threshold = 0.4
    Ace::Review.stub :get, ->(section, key) {
      if section == "feedback" && key == "consensus_threshold"
        threshold
      elsif section == "feedback" && key == "synthesis_model"
        "test-synthesis-model"
      else
        nil
      end
    } do
      first = @synthesizer.synthesize(
        report_paths: [
          { path: p1, reviewer: r1 },
          { path: p2, reviewer: r2 }
        ],
        session_dir: @session_dir
      )
      assert first[:success], first[:error]
      assert first[:items].first.consensus, "Confidence 0.5 should pass threshold 0.4"

      threshold = 0.9
      second = @synthesizer.synthesize(
        report_paths: [
          { path: p1, reviewer: r1 },
          { path: p2, reviewer: r2 }
        ],
        session_dir: @session_dir
      )
      assert second[:success], second[:error]
      refute second[:items].first.consensus, "Confidence 0.5 should fail threshold 0.9"
    end
  end

  def test_synthesize_keeps_original_order_when_reviewer_metadata_absent
    report_path = create_report_file("review-report-gemini-2.5-flash.md", sample_report_content)

    @mock_executor.set_response({
      findings: [
        { title: "Second", priority: "low", finding: "second finding" },
        { title: "First", priority: "critical", finding: "first finding" }
      ]
    }.to_json)

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    assert result[:success], result[:error]
    assert_equal ["Second", "First"], result[:items].map(&:title)
    assert_equal [false, false], result[:items].map(&:critical_source)
    assert_equal [nil, nil], result[:items].map(&:focus)
  end

  private

  # Helper to create a report file
  def create_report_file(name, content)
    path = File.join(@temp_dir, name)
    File.write(path, content)
    path
  end

  # Sample report content
  def sample_report_content
    <<~MARKDOWN
      # Code Review Report

      ## Security Issues

      ### SQL Injection Vulnerability
      File: src/db/query.rb, lines 42-55

      The query builder uses string interpolation without sanitization.

      ### Missing Authentication
      File: src/api/users.rb:28

      The endpoint lacks authentication checks.
    MARKDOWN
  end

  # Sample LLM response for single report
  def single_report_response
    {
      findings: [
        {
          title: "Fix SQL injection vulnerability",
          files: ["src/db/query.rb:42-55"],
          priority: "critical",
          finding: "The query builder uses string interpolation without sanitization.",
          context: "Security vulnerability"
        },
        {
          title: "Add error handling to user endpoint",
          files: ["src/api/users.rb:28"],
          priority: "high",
          finding: "Missing error handling.",
          context: "Code quality"
        }
      ]
    }.to_json
  end

  # Sample LLM response for multi-report synthesis
  def multi_report_response
    {
      findings: [
        {
          title: "Fix SQL injection vulnerability",
          files: ["src/db/query.rb:42-55"],
          reviewers: ["google:gemini-2.5-flash", "anthropic:claude-3.5-sonnet", "openai:gpt-4"],
          consensus: true,
          priority: "critical",
          finding: "The query builder uses string interpolation without sanitization.",
          context: "All three reviewers identified this critical security issue."
        },
        {
          title: "Add error handling to user endpoint",
          files: ["src/api/users.rb:28"],
          reviewers: ["google:gemini-2.5-flash", "anthropic:claude-3.5-sonnet"],
          consensus: false,
          priority: "high",
          finding: "Missing error handling.",
          context: "Two reviewers identified this issue."
        }
      ]
    }.to_json
  end

  # Sample response with merged files
  def merged_files_response
    {
      findings: [
        {
          title: "Fix SQL injection vulnerability",
          files: ["src/db/query.rb:42-55", "src/db/query.rb:60-70"],
          reviewers: ["r1", "r2"],
          consensus: false,
          priority: "critical",
          finding: "SQL injection in multiple locations.",
          context: "Merged from both reviewers."
        }
      ]
    }.to_json
  end

  # Single finding response with specific reviewer
  def single_finding_response_with_reviewer(reviewer)
    {
      findings: [
        {
          title: "Fix SQL injection vulnerability",
          files: ["src/db/query.rb:42-55"],
          reviewers: [reviewer],
          priority: "critical",
          finding: "The query builder uses string interpolation without sanitization.",
          context: "Security vulnerability"
        }
      ]
    }.to_json
  end

  def two_reviewer_full_agreement_response(r1, r2)
    {
      findings: [
        {
          title: "Fix SQL injection vulnerability",
          files: ["src/db/query.rb:42-55"],
          reviewers: [r1, r2],
          priority: "critical",
          finding: "The query builder uses string interpolation without sanitization.",
          context: "Security vulnerability"
        }
      ]
    }.to_json
  end

  # Mock LLM executor for testing
  class MockLlmExecutor
    attr_reader :call_count

    def initialize
      @response = nil
      @error = nil
      @call_count = 0
    end

    def set_response(response)
      @response = response
      @error = nil
    end

    def set_error(error)
      @error = error
      @response = nil
    end

    def execute(system_prompt:, user_prompt:, model:, session_dir:, output_file: nil)
      @call_count += 1

      if @error
        { success: false, error: @error }
      else
        { success: true, response: @response }
      end
    end
  end

  # ============================================================================
  # JSON Repair Tests
  # ============================================================================

  def test_repair_truncated_json_closes_braces
    truncated = '{"findings": [{"title": "Bug", "finding": "desc", "reviewers": ["r1"]'
    repaired = @synthesizer.send(:repair_truncated_json, truncated)

    parsed = JSON.parse(repaired)
    assert_equal 1, parsed["findings"].size
    assert_equal "Bug", parsed["findings"].first["title"]
  end

  def test_repair_truncated_json_no_op_for_valid_json
    valid = '{"findings": []}'
    result = @synthesizer.send(:repair_truncated_json, valid)
    assert_equal valid, result
  end

  def test_repair_truncated_json_strips_trailing_partial_string
    truncated = '{"findings": [{"title": "Bug", "finding": "desc"}, {"title": "Incompl'
    repaired = @synthesizer.send(:repair_truncated_json, truncated)

    parsed = JSON.parse(repaired)
    assert_equal 1, parsed["findings"].size
  end

  def test_strip_trailing_commas_in_arrays
    json_with_trailing = '{"findings": [{"title": "Bug", "finding": "desc"},]}'
    result = @synthesizer.send(:strip_trailing_commas, json_with_trailing)
    parsed = JSON.parse(result)
    assert_equal 1, parsed["findings"].size
  end

  def test_strip_trailing_commas_in_objects
    json_with_trailing = '{"key": "value", "other": "val",}'
    result = @synthesizer.send(:strip_trailing_commas, json_with_trailing)
    parsed = JSON.parse(result)
    assert_equal "value", parsed["key"]
  end

  def test_extract_json_handles_trailing_commas
    json_with_trailing = '{"findings": [{"title": "Issue", "finding": "problem", "reviewers": ["r1"], "priority": "high",},]}'
    result = @synthesizer.send(:extract_json_from_response, json_with_trailing)
    parsed = JSON.parse(result)
    assert_equal 1, parsed["findings"].size
    assert_equal "Issue", parsed["findings"].first["title"]
  end

  def test_extract_json_from_response_repairs_truncated
    truncated = '{"findings": [{"title": "Issue", "finding": "problem", "reviewers": ["r1"], "priority": "high"'
    result = @synthesizer.send(:extract_json_from_response, truncated)

    parsed = JSON.parse(result)
    assert parsed.key?("findings")
  end
end
