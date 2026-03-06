# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "ace/review/molecules/multi_model_executor"
require "ace/review/models/reviewer"

class MultiModelExecutorTest < AceReviewTest
  def setup
    super
    @temp_dir = Dir.mktmpdir
    @executor = Ace::Review::Molecules::MultiModelExecutor.new(max_concurrent: 2, llm_timeout: 5)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
    super
  end

  # ============================================================================
  # Legacy path (models: only, no reviewers:)
  # ============================================================================

  def test_execute_legacy_path_sets_nil_reviewer
    stub_llm_executor(@executor, success: true)

    result = @executor.execute(
      models: ["google:gemini-2.5-flash"],
      system_prompt: "sys",
      user_prompt: "usr",
      session_dir: @temp_dir
    )

    assert result[:success]
    assert_equal 1, result[:results].size
    model_result = result[:results]["google:gemini-2.5-flash"]
    assert model_result
    assert_nil model_result[:reviewer], "Legacy path should set reviewer to nil"
  end

  def test_execute_legacy_path_preserves_model_list
    stub_llm_executor(@executor, success: true)

    result = @executor.execute(
      models: ["google:gemini-2.5-flash", "anthropic:claude-3-5-sonnet"],
      system_prompt: "sys",
      user_prompt: "usr",
      session_dir: @temp_dir
    )

    assert result[:success]
    assert_equal 2, result[:results].size
    assert result[:results].key?("google:gemini-2.5-flash")
    assert result[:results].key?("anthropic:claude-3-5-sonnet")
  end

  # ============================================================================
  # Reviewer path (reviewers: provided)
  # ============================================================================

  def test_execute_with_reviewers_derives_models_from_reviewers
    stub_llm_executor(@executor, success: true)
    reviewers = [
      Ace::Review::Models::Reviewer.new(name: "code-fit", model: "google:gemini-2.5-pro", weight: 1.0),
      Ace::Review::Models::Reviewer.new(name: "code-valid", model: "anthropic:claude-3-5-sonnet", weight: 0.8)
    ]

    result = @executor.execute(
      models: [],
      reviewers: reviewers,
      system_prompt: "sys",
      user_prompt: "usr",
      session_dir: @temp_dir
    )

    assert result[:success]
    assert_equal 2, result[:results].size
    assert result[:results].key?(reviewer_run_key(reviewers[0]))
    assert result[:results].key?(reviewer_run_key(reviewers[1]))
  end

  def test_execute_with_reviewers_tags_results_with_reviewer_object
    stub_llm_executor(@executor, success: true)
    reviewer = Ace::Review::Models::Reviewer.new(name: "code-fit", model: "google:gemini-2.5-pro", weight: 1.0)

    result = @executor.execute(
      models: [],
      reviewers: [reviewer],
      system_prompt: "sys",
      user_prompt: "usr",
      session_dir: @temp_dir
    )

    model_result = result[:results][reviewer_run_key(reviewer)]
    assert model_result
    assert_equal reviewer, model_result[:reviewer]
  end

  def test_execute_with_reviewers_uses_reviewers_over_models_param
    stub_llm_executor(@executor, success: true)
    reviewer = Ace::Review::Models::Reviewer.new(name: "r1", model: "google:gemini-2.5-pro", weight: 1.0)

    result = @executor.execute(
      models: ["anthropic:claude-3-5-sonnet"],  # should be ignored
      reviewers: [reviewer],
      system_prompt: "sys",
      user_prompt: "usr",
      session_dir: @temp_dir
    )

    # Only the reviewer model should be executed
    assert_equal 1, result[:results].size
    assert result[:results].key?(reviewer_run_key(reviewer))
    refute result[:results].key?("anthropic:claude-3-5-sonnet")
  end

  def test_execute_with_duplicate_model_reviewers_returns_distinct_lanes
    stub_llm_executor(@executor, success: true)
    r1 = Ace::Review::Models::Reviewer.new(name: "first", model: "google:gemini-2.5-pro", weight: 1.0)
    r2 = Ace::Review::Models::Reviewer.new(name: "last", model: "google:gemini-2.5-pro", weight: 0.5)

    result = @executor.execute(
      models: [],
      reviewers: [r1, r2],
      system_prompt: "sys",
      user_prompt: "usr",
      session_dir: @temp_dir
    )

    assert_equal 2, result[:results].size
    first_result = result[:results][reviewer_run_key(r1)]
    last_result = result[:results][reviewer_run_key(r2)]
    assert first_result
    assert last_result
    assert_equal r1, first_result[:reviewer]
    assert_equal r2, last_result[:reviewer]
    expected_output_files = [r1, r2].map do |reviewer|
      run_key_slug = Ace::Review::Atoms::SlugGenerator.generate(reviewer_run_key(reviewer))
      File.join(@temp_dir, "review-#{run_key_slug}.md")
    end

    assert_equal expected_output_files.sort, result[:results].values.map { |entry| entry[:output_file] }.sort
  end

  def test_execute_with_duplicate_name_and_model_reviewers_uses_unique_run_keys
    stub_llm_executor(@executor, success: true)
    r1 = Ace::Review::Models::Reviewer.new(name: "correctness", model: "google:gemini-2.5-pro", weight: 1.0)
    r2 = Ace::Review::Models::Reviewer.new(name: "correctness", model: "google:gemini-2.5-pro", weight: 0.5)

    result = @executor.execute(
      models: [],
      reviewers: [r1, r2],
      system_prompt: "sys",
      user_prompt: "usr",
      session_dir: @temp_dir
    )

    assert_equal 2, result[:results].size
    run_keys = result[:results].keys
    assert_equal 2, run_keys.uniq.size
    assert run_keys.all? { |key| key.start_with?("correctness:google-gemini-2-5-pro:") }
  end

  def test_execute_with_empty_reviewers_falls_back_to_models
    stub_llm_executor(@executor, success: true)

    result = @executor.execute(
      models: ["google:gemini-2.5-flash"],
      reviewers: [],
      system_prompt: "sys",
      user_prompt: "usr",
      session_dir: @temp_dir
    )

    assert result[:success]
    assert result[:results].key?("google:gemini-2.5-flash")
    assert_nil result[:results]["google:gemini-2.5-flash"][:reviewer]
  end

  # ============================================================================
  # Summary metrics
  # ============================================================================

  def test_execute_summary_reflects_reviewer_derived_model_count
    stub_llm_executor(@executor, success: true)
    reviewers = [
      Ace::Review::Models::Reviewer.new(name: "r1", model: "google:gemini-2.5-pro", weight: 1.0),
      Ace::Review::Models::Reviewer.new(name: "r2", model: "anthropic:claude-3-5-sonnet", weight: 1.0)
    ]

    result = @executor.execute(
      models: [],
      reviewers: reviewers,
      system_prompt: "sys",
      user_prompt: "usr",
      session_dir: @temp_dir
    )

    assert_equal 2, result[:summary][:total_models]
    assert_equal 2, result[:summary][:success_count]
  end

  private

  # Stub the internal LlmExecutor to avoid real LLM calls
  def stub_llm_executor(executor, success:, error: nil)
    stub = Object.new
    stub.define_singleton_method(:execute) do |**kwargs|
      output_file = kwargs[:output_file]
      if success && output_file
        File.write(output_file, "# Review output")
      end

      if success
        { success: true, response: "review content", output_file: output_file }
      else
        { success: false, error: error || "stubbed error" }
      end
    end
    executor.instance_variable_set(:@llm_executor, stub)
  end

  def reviewer_run_key(reviewer)
    Ace::Review::Atoms::ReviewerRunKeyAllocator.allocate([reviewer]).first[:run_key]
  end
end
