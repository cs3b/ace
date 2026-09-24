# frozen_string_literal: true

require "test_helper"
require "ace/review/atoms/prompt_budget"

class PromptBudgetTest < AceReviewTest
  def test_counts_both_prompts_and_refuses_oversize_packet
    result = Ace::Review::Atoms::PromptBudget.check(
      system_prompt: "s" * 40,
      user_prompt: "u" * 40,
      models: [],
      config: {"input_max_tokens" => 19, "system_max_tokens" => 10}
    )

    refute result[:success]
    assert_equal 13, result[:system_tokens]
    assert_equal 26, result[:total_tokens]
    assert_match(/complete prompt/, result[:errors].join(" "))
  end

  def test_rejects_unicode_heavy_packet_under_ascii_character_heuristic
    result = Ace::Review::Atoms::PromptBudget.check(
      system_prompt: "review", user_prompt: "海" * 50_000, models: []
    )
    refute result[:success]
    assert_operator result[:total_tokens], :>, 128_000
  end

  def test_refuses_packet_that_exceeds_a_reviewers_context
    limit = Ace::Review::Atoms::ContextLimitResolver.resolve("codex:gpt-5.6-terra")
    result = Ace::Review::Atoms::PromptBudget.check(
      system_prompt: "s",
      user_prompt: "u" * ((limit - Ace::Review::Atoms::PromptBudget::OUTPUT_RESERVE + 1) * 4),
      models: ["codex:gpt-5.6-terra"],
      config: {"input_max_tokens" => 128_000, "system_max_tokens" => 30_000}
    )

    refute result[:success]
    assert_match(/input allowance/, result[:errors].join(" "))
  end

  def test_an_ineligible_preferred_model_does_not_block_an_eligible_substitute
    short = Struct.new(:context_limit).new(8_200)
    long = Struct.new(:context_limit).new(200_000)
    resolver = ->(model) { (model == "short") ? short : long }
    Ace::Review::Atoms::ContextLimitResolver.stub(:resolve_details, resolver) do
      result = Ace::Review::Atoms::PromptBudget.check(system_prompt: "s",
        user_prompt: "u" * 400, models: %w[short long])
      assert result[:success], result[:errors].join("; ")
      assert_equal ["long"], result[:eligible_models]
      assert_equal 8, result[:ineligible_models]["short"]
      assert_equal 30_000, result[:context_limit]
    end
  end

  def test_reserves_the_models_configured_output_limit
    limits = Struct.new(:context_limit, :output_limit).new(50_000, 20_000)
    Ace::Review::Atoms::ContextLimitResolver.stub(:resolve_details, limits) do
      result = Ace::Review::Atoms::PromptBudget.check(system_prompt: "s",
        user_prompt: "u" * 88_000, models: ["configured"])
      assert result[:success], result[:errors].join("; ")
      assert_equal ["configured"], result[:eligible_models]

      too_large = Ace::Review::Atoms::PromptBudget.check(system_prompt: "s",
        user_prompt: "u" * 104_000, models: ["configured"])
      refute too_large[:success]
      assert_equal 30_000, too_large[:ineligible_models]["configured"]
    end
  end

  def test_project_context_in_user_prompt_has_its_own_limit
    diff = "diff --git a/a b/a\n+changed\n"
    result = Ace::Review::Atoms::PromptBudget.check(
      system_prompt: "instructions", user_prompt: diff + ("context " * 18_000),
      subject: diff, models: [], config: {"context_max_tokens" => 30_000}
    )
    refute result[:success]
    assert_match(/non-diff review context/, result[:errors].join("; "))
    assert_operator result[:context_tokens], :>, 30_000
  end

  def test_instruction_tokens_cannot_hide_excess_non_diff_context
    diff = "d" * 400
    user_prompt = diff + ("i" * 48_000) + ("c" * 56_000)
    instruction_tokens = Ace::Review::Atoms::PromptBudget.send(:conservative_estimate, "i" * 48_000)
    result = Ace::Review::Atoms::PromptBudget.check(system_prompt: "trusted",
      user_prompt: user_prompt, subject: diff, instruction_tokens: instruction_tokens,
      models: [], config: {"context_max_tokens" => 30_000})
    refute result[:success]
    assert_match(/non-diff review context/, result[:errors].join("; "))
    assert_operator result[:context_tokens], :>, 30_000
    assert_operator result[:instruction_tokens], :<, 30_000
  end

  def test_rejects_invalid_limit
    assert_raises(ArgumentError) do
      Ace::Review::Atoms::PromptBudget.check(system_prompt: "s", user_prompt: "u", models: [],
        config: {"input_max_tokens" => "100"})
    end
  end

  def test_hard_cap_cannot_be_raised_by_configuration
    assert_raises(ArgumentError) do
      Ace::Review::Atoms::PromptBudget.check(system_prompt: "s", user_prompt: "u", models: [],
        config: {"input_max_tokens" => 128_001})
    end
    assert_raises(ArgumentError) do
      Ace::Review::Atoms::PromptBudget.check(system_prompt: "s", user_prompt: "u", models: [],
        config: {"system_max_tokens" => 30_001})
    end
  end
end
