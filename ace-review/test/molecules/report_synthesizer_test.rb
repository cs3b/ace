# frozen_string_literal: true

require "test_helper"

class ReportSynthesizerTest < AceReviewTest
  def setup
    super
    @synthesizer = Ace::Review::Molecules::ReportSynthesizer.new
    @session_dir = File.join(@test_dir, "session")
    FileUtils.mkdir_p(@session_dir)
  end

  def test_initialization
    assert_instance_of Ace::Review::Molecules::LlmExecutor, @synthesizer.llm_executor
  end

  def test_synthesize_requires_report_paths
    result = @synthesizer.synthesize(
      report_paths: nil,
      session_dir: @session_dir
    )

    refute result[:success]
    assert_equal "No report paths provided", result[:error]
  end

  def test_synthesize_requires_session_dir
    result = @synthesizer.synthesize(
      report_paths: ["report1.md"],
      session_dir: nil
    )

    refute result[:success]
    assert_equal "Session directory required", result[:error]
  end

  def test_synthesize_requires_at_least_two_reports
    # Create a single report
    report_path = File.join(@session_dir, "review-gemini.md")
    File.write(report_path, "# Review\n\nTest review content")

    result = @synthesizer.synthesize(
      report_paths: [report_path],
      session_dir: @session_dir
    )

    refute result[:success]
    assert_match(/requires at least 2 reports/, result[:error])
  end

  def test_read_reports_extracts_model_names_from_filenames
    # Create test reports with different filename patterns
    reports = {
      "review-report-gemini-2.5-flash.md" => "gemini-2.5-flash",
      "review-gpt-4.md" => "gpt-4",
      "review-report-claude-sonnet.md" => "claude-sonnet"
    }

    reports.each do |filename, expected_model|
      path = File.join(@session_dir, filename)
      File.write(path, "# Review from #{expected_model}")
    end

    # Access private method for testing
    report_data = @synthesizer.send(:read_reports, reports.keys.map { |f| File.join(@session_dir, f) })

    assert_equal 3, report_data.size
    reports.each_value do |expected_model|
      assert report_data.any? { |r| r[:model] == expected_model },
             "Expected to find model '#{expected_model}' in report data"
    end
  end

  def test_read_reports_handles_missing_files_gracefully
    existing_report = File.join(@session_dir, "review-gemini.md")
    missing_report = File.join(@session_dir, "review-missing.md")

    File.write(existing_report, "# Review")

    # Capture warnings (warn writes to STDERR)
    _stdout, stderr = capture_io do
      @reports = @synthesizer.send(:read_reports, [existing_report, missing_report])
    end

    # Should only read existing report
    assert_equal 1, @reports.size
    assert_equal "gemini", @reports.first[:model]

    # Should have warned about missing file
    assert_match(/Warning.*not found/, stderr)
  end

  def test_extract_model_from_filename_patterns
    test_cases = {
      "/path/review-report-gemini-2.5-flash.md" => "gemini-2.5-flash",
      "/path/review-gpt-4.md" => "gpt-4",
      "/path/review-report-claude-sonnet-4.md" => "claude-sonnet-4",
      "/path/review-google-gemini-pro.md" => "google-gemini-pro",
      "/path/some-other-file.md" => "some-other-file"
    }

    test_cases.each do |path, expected|
      actual = @synthesizer.send(:extract_model_from_filename, path)
      assert_equal expected, actual, "Failed for path: #{path}"
    end
  end

  def test_build_fallback_user_prompt
    reports = [
      { path: "report1.md", model: "gemini", content: "Review 1", size: 100 },
      { path: "report2.md", model: "gpt-4", content: "Review 2", size: 200 }
    ]

    prompt = @synthesizer.send(:build_fallback_user_prompt, reports)

    assert_includes prompt, "Synthesize these 2 review reports"
    assert_includes prompt, "## Report 1: gemini"
    assert_includes prompt, "## Report 2: gpt-4"
    assert_includes prompt, "Review 1"
    assert_includes prompt, "Review 2"
  end

  def test_build_user_context_content_generates_frontmatter
    reports = [
      { path: "/path/to/report1.md", model: "gemini", content: "Review 1", size: 100 },
      { path: "/path/to/report2.md", model: "gpt-4", content: "Review 2", size: 200 }
    ]

    content = @synthesizer.send(:build_user_context_content, reports)

    # Should have YAML frontmatter
    assert_match(/^---\n/, content)
    assert_includes content, "description: Synthesis user prompt with review reports"
    assert_includes content, "/path/to/report1.md"
    assert_includes content, "/path/to/report2.md"
    assert_includes content, "Synthesize these 2 review reports"
  end

  def test_format_size
    test_cases = {
      100 => "100 B",
      1500 => "1.5 KB",
      2_500_000 => "2.4 MB"
    }

    test_cases.each do |bytes, expected|
      actual = @synthesizer.send(:format_size, bytes)
      assert_equal expected, actual
    end
  end

  def test_extract_summary_from_synthesis_counts_sections
    synthesis_content = <<~MARKDOWN
      # Multi-Model Review Synthesis

      ## Overview
      Test overview

      ## Consensus Findings (All Models Agree)
      1. First consensus finding
      2. Second consensus finding

      ## Strong Recommendations (2+ Models)
      1. First strong recommendation
      2. Second strong recommendation
      3. Third strong recommendation

      ## Unique Insights
      ### From gemini:
      - Unique insight 1

      ### From gpt-4:
      - Unique insight 2

      ## Conflicting Views & Resolution
      ### Topic: Error handling
      Resolution here

      ## Prioritized Action Items
      1. Action 1
      2. Action 2
      3. Action 3
      4. Action 4
      5. Action 5
    MARKDOWN

    summary = @synthesizer.send(:extract_summary_from_synthesis, synthesis_content)

    assert_equal 2, summary[:consensus_findings]
    assert_equal 3, summary[:strong_recommendations]
    assert_equal 2, summary[:unique_insights]
    assert_equal 1, summary[:conflicts_resolved]
    assert_equal 5, summary[:total_action_items]
  end

  def test_resolve_prompt_path_finds_synthesis_prompt
    path = @synthesizer.send(:resolve_prompt_path, "synthesis-review-reports.system.md")

    # Path should be non-empty and end with the expected filename
    refute_empty path, "Should resolve to a path"
    assert_match(/synthesis-review-reports\.system\.md$/, path)

    # If file exists, verify content (may not exist in test temp directory)
    if File.exist?(path)
      content = File.read(path)
      assert_includes content, "Multi-Model Review Synthesis"
      assert_includes content, "Consensus Findings"
    end
  end

  def test_synthesize_with_mocked_llm
    # Create test reports
    report1 = File.join(@session_dir, "review-gemini.md")
    report2 = File.join(@session_dir, "review-gpt-4.md")

    File.write(report1, "# Review from Gemini\n\nFinding 1: Issue A")
    File.write(report2, "# Review from GPT-4\n\nFinding 1: Issue A\nFinding 2: Issue B")

    # Mock LLM executor to return a synthesis
    mock_synthesis = <<~MARKDOWN
      # Multi-Model Review Synthesis

      ## Overview
      - Models: gemini, gpt-4

      ## Consensus Findings (All Models Agree)
      1. Issue A (both models found this)

      ## Strong Recommendations (2+ Models)
      No additional strong recommendations

      ## Unique Insights
      ### From gpt-4:
      - Issue B (unique to GPT-4)

      ## Conflicting Views & Resolution
      No conflicts identified

      ## Prioritized Action Items
      1. Fix Issue A (high priority - consensus)
      2. Consider Issue B (medium priority)
    MARKDOWN

    # Stub the LLM executor
    @synthesizer.llm_executor.define_singleton_method(:execute) do |**_args|
      {
        success: true,
        response: mock_synthesis,
        metadata: { tokens: 1000 }
      }
    end

    result = @synthesizer.synthesize(
      report_paths: [report1, report2],
      session_dir: @session_dir
    )

    assert result[:success], "Synthesis should succeed"
    assert result[:output_file], "Should have output file"
    assert File.exist?(result[:output_file]), "Output file should exist"

    # Check summary
    assert_equal 1, result[:summary][:consensus_findings]
    assert_equal 0, result[:summary][:strong_recommendations]
    assert_equal 1, result[:summary][:unique_insights]
    assert_equal 2, result[:summary][:total_action_items]

    # Verify output content
    content = File.read(result[:output_file])
    assert_includes content, "Multi-Model Review Synthesis"
    assert_includes content, "Consensus Findings"
  end

  def test_synthesize_handles_llm_failure
    # Create test reports
    report1 = File.join(@session_dir, "review-gemini.md")
    report2 = File.join(@session_dir, "review-gpt-4.md")

    File.write(report1, "Review 1")
    File.write(report2, "Review 2")

    # Stub LLM executor to fail
    @synthesizer.llm_executor.define_singleton_method(:execute) do |**_args|
      {
        success: false,
        error: "LLM API error"
      }
    end

    result = @synthesizer.synthesize(
      report_paths: [report1, report2],
      session_dir: @session_dir
    )

    refute result[:success]
    assert_includes result[:error], "LLM API error"
  end
end
