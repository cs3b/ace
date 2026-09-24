# frozen_string_literal: true

require "test_helper"

class LlmExecutorTest < AceReviewTest
  def setup
    super
    install_project_llm_provider_fixtures("claude", "codex")
    @executor = Ace::Review::Molecules::LlmExecutor.new
  end

  # ============================================================================
  # Prompt Size Warning Tests
  # ============================================================================

  def test_warns_when_prompt_exceeds_threshold
    # Create prompts that exceed 800K tokens (~3.2M chars at 4 chars/token)
    large_system = "x" * 2_000_000
    large_user = "y" * 1_400_000

    warning_output = capture_stderr do
      @executor.send(:warn_if_prompt_large, large_system, large_user, "claude:opus")
    end

    assert_match(/Warning: Prompt size/, warning_output)
    assert_match(/tokens/, warning_output)
    assert_match(/claude:opus/, warning_output)
  end

  def test_no_warning_for_small_prompts
    small_system = "System prompt"
    small_user = "User prompt"

    warning_output = capture_stderr do
      @executor.send(:warn_if_prompt_large, small_system, small_user, "claude:opus")
    end

    assert_empty warning_output
  end

  def test_no_warning_at_exactly_threshold
    # 800K tokens * 4 chars = 3.2M chars
    threshold_chars = 800_000 * 4
    exact_threshold_prompt = "x" * threshold_chars

    warning_output = capture_stderr do
      @executor.send(:warn_if_prompt_large, exact_threshold_prompt, "", "claude:opus")
    end

    assert_empty warning_output, "Should not warn at exactly the threshold"
  end

  def test_warns_just_above_threshold
    # 800K tokens * 4 chars + 4 = just over threshold
    threshold_chars = (800_000 * 4) + 4
    over_threshold_prompt = "x" * threshold_chars

    warning_output = capture_stderr do
      @executor.send(:warn_if_prompt_large, over_threshold_prompt, "", "claude:opus")
    end

    assert_match(/Warning: Prompt size/, warning_output)
  end

  def test_handles_nil_prompts
    warning_output = capture_stderr do
      @executor.send(:warn_if_prompt_large, nil, nil, "claude:opus")
    end

    assert_empty warning_output
  end

  def test_warning_includes_formatted_token_count
    # Create prompt that estimates to ~900K tokens
    large_prompt = "x" * 3_600_000  # 3.6M chars / 4 = 900K tokens

    warning_output = capture_stderr do
      @executor.send(:warn_if_prompt_large, large_prompt, "", "test-model")
    end

    # Should include comma-formatted number (e.g., "900,000")
    assert_match(/900,000/, warning_output)
  end

  def test_warning_shows_resolved_concrete_model_for_alias_target
    large_prompt = "x" * 3_600_000

    warning_output = capture_stderr do
      @executor.send(:warn_if_prompt_large, large_prompt, "", "codex:gpt:high@ro")
    end

    assert_match(/codex:gpt:high@ro -> codex:gpt-5\.6-terra/, warning_output)
    assert_match(/context limit \(200,000 tokens\)/, warning_output)
  end

  def test_execute_forwards_timeout_to_query_interface
    captured_kwargs = nil
    query_stub = lambda do |_model, _prompt, **kwargs|
      captured_kwargs = kwargs
      {text: "ok", metadata: {finish_reason: "stop"}, execution: {status: "succeeded"}, usage: {}}
    end

    Ace::LLM::QueryInterface.stub(:query, query_stub) do
      result = @executor.execute(
        system_prompt: "system",
        user_prompt: "user",
        model: "claude:opus@ro",
        session_dir: @test_dir,
        timeout: 900
      )

      assert result[:success]
    end

    assert_equal 900, captured_kwargs[:timeout]
  end

  def test_empty_model_output_is_not_a_completed_review
    Ace::LLM::QueryInterface.stub(:query, {text: "  ", execution: {provider: "pi", model: "zai/glm-5.3"}}) do
      result = @executor.execute(system_prompt: "system", user_prompt: "user",
        model: "pi:glm5:max@ro", session_dir: @test_dir)

      refute result[:success]
      assert_match(/empty report/, result[:error])
      assert_equal "zai/glm-5.3", result[:execution][:model]
    end
  end

  def test_truncated_model_output_is_not_a_completed_review
    response = {text: "Partial finding", metadata: {finish_reason: "length"},
                execution: {provider: "pi", model: "zai/glm-5.3"}}
    Ace::LLM::QueryInterface.stub(:query, response) do
      result = @executor.execute(system_prompt: "system", user_prompt: "user",
        model: "pi:glm5:max@ro", session_dir: @test_dir)

      refute result[:success]
      assert_match(/incomplete/, result[:error])
      assert_equal "length", result[:metadata][:finish_reason]
    end
  end

  def test_nonempty_report_without_terminal_receipt_is_not_completed
    response = {text: "Plausible but partial review", metadata: {},
                execution: {provider: "pi", model: "zai/glm-5.3", status: "succeeded"}}
    Ace::LLM::QueryInterface.stub(:query, response) do
      result = @executor.execute(system_prompt: "system", user_prompt: "user",
        model: "pi:glm5:max@ro", session_dir: @test_dir)
      refute result[:success]
      assert_match(/incomplete/, result[:error])
    end
  end

  def test_unknown_terminal_reason_is_not_a_completed_review
    response = {text: "Partial finding", metadata: {finish_reason: "aborted"},
                execution: {provider: "pi", model: "zai/glm-5.3"}}
    Ace::LLM::QueryInterface.stub(:query, response) do
      result = @executor.execute(system_prompt: "system", user_prompt: "user",
        model: "pi:glm5:max@ro", session_dir: @test_dir)
      refute result[:success]
      assert_match(/aborted/, result[:error])
    end
  end

  def test_string_keyed_truncation_and_incomplete_execution_are_rejected
    [{metadata: {"finish_reason" => "length"}, execution: {status: "succeeded"}},
      {metadata: {}, execution: {"status" => "incomplete"}}].each do |fields|
      response = {text: "Partial finding"}.merge(fields)
      Ace::LLM::QueryInterface.stub(:query, response) do
        result = @executor.execute(system_prompt: "system", user_prompt: "user",
          model: "pi:glm5:max@ro", session_dir: @test_dir)
        refute result[:success]
        assert_match(/incomplete/, result[:error])
      end
    end
  end

  private

  def capture_stderr
    old_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = old_stderr
  end
end
