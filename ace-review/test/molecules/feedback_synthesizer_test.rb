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

    @mock_executor.set_responses([
      "This is not valid JSON",
      "Still not valid JSON"
    ])

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    refute result[:success]
    assert_includes result[:error], "Invalid JSON"
  end

  def test_synthesize_repairs_trailing_comma_json
    report_path = create_report_file("report.md", sample_report_content)

    response = <<~JSON
      {
        "findings": [
          {
            "title": "Fix SQL injection vulnerability",
            "finding": "The query builder uses string interpolation without sanitization.",
            "priority": "critical",
          }
        ]
      }
    JSON
    @mock_executor.set_response(response)

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    assert result[:success], "Expected deterministic JSON cleanup to succeed: #{result[:error]}"
    assert_equal 1, result[:items].length
    assert File.exist?(File.join(@session_dir, "feedback-synthesis.cleaned.json"))
  end

  def test_synthesize_repairs_truncated_json_with_second_pass
    report_path = create_report_file("report.md", sample_report_content)

    @mock_executor.set_responses([
      <<~BROKEN,
        {
          "findings": [
            {
              "title": "Fix SQL injection vulnerability",
              "finding": "The query builder uses string interpolation
      BROKEN
      single_report_response
    ])

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    assert result[:success], "Expected repair pass to succeed: #{result[:error]}"
    assert_equal 2, @mock_executor.call_count
    assert File.exist?(File.join(@session_dir, "feedback-synthesis.repair.raw.txt"))
    assert File.exist?(File.join(@session_dir, "feedback-synthesis.cleaned.json"))
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

  def test_synthesize_persists_raw_output_in_session_dir
    report_path = create_report_file("report.md", sample_report_content)

    @mock_executor.set_response(single_report_response)

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    assert result[:success]
    assert File.exist?(File.join(@session_dir, "feedback-synthesis.raw.txt"))
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

  # Mock LLM executor for testing
  class MockLlmExecutor
    attr_reader :call_count

    def initialize
      @responses = []
      @error = nil
      @call_count = 0
    end

    def set_response(response)
      @responses = [response]
      @error = nil
    end

    def set_responses(responses)
      @responses = responses.dup
      @error = nil
    end

    def set_error(error)
      @error = error
      @responses = []
    end

    def execute(system_prompt:, user_prompt:, model:, session_dir:, output_file: nil)
      @call_count += 1

      if @error
        { success: false, error: @error }
      else
        response = @responses.empty? ? nil : @responses.shift
        File.write(output_file, response.to_s) if output_file
        { success: true, response: response }
      end
    end
  end
end
