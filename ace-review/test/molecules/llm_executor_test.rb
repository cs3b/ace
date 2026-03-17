# frozen_string_literal: true

require "test_helper"

class LlmExecutorTest < AceReviewTest
  def setup
    super
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
