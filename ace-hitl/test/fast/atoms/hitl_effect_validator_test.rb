# frozen_string_literal: true

require "test_helper"
require "ace/hitl/atoms/hitl_effect_validator"

class HitlEffectValidatorTest < AceHitlTestCase
  def validate(**kwargs)
    Ace::Hitl::Atoms::HitlEffectValidator.validate!(**kwargs)
  end

  # -- match: length bound --------------------------------------------------

  def test_match_over_200_chars_fails
    error = assert_raises(Ace::Hitl::Atoms::HitlEffectValidator::ValidationError) do
      validate(match: "a" * 201, effect_args: ["x"])
    end
    assert_match(/exceeds 200 characters/, error.message)
  end

  def test_match_exactly_200_chars_passes
    validate(match: "a" * 200, effect_args: ["x"])
  end

  # -- match: compilation ---------------------------------------------------

  def test_match_invalid_regex_fails
    error = assert_raises(Ace::Hitl::Atoms::HitlEffectValidator::ValidationError) do
      validate(match: "[unclosed", effect_args: ["x"])
    end
    assert_match(/does not compile/, error.message)
  end

  def test_match_valid_regex_passes
    validate(match: "\\A[0-9]{6}\\Z", effect_args: ["x"])
  end

  # -- effect argv: element presence ---------------------------------------

  def test_effect_flag_without_any_arg_fails
    error = assert_raises(Ace::Hitl::Atoms::HitlEffectValidator::ValidationError) do
      validate(effect_cwd: "/tmp")
    end
    assert_match(/at least one --effect-arg is required/, error.message)
  end

  def test_effect_arg_alone_passes
    validate(effect_args: ["/bin/false"])
  end

  # -- effect argv: element count ------------------------------------------

  def test_effect_args_over_16_elements_fail
    error = assert_raises(Ace::Hitl::Atoms::HitlEffectValidator::ValidationError) do
      validate(effect_args: Array.new(17) { |i| "arg#{i}" })
    end
    assert_match(/too many --effect-arg values \(17\); max 16/, error.message)
  end

  def test_effect_args_exactly_16_elements_pass
    validate(effect_args: Array.new(16) { |i| "arg#{i}" })
  end

  # -- effect argv: element length ------------------------------------------

  def test_effect_arg_over_512_chars_fails
    error = assert_raises(Ace::Hitl::Atoms::HitlEffectValidator::ValidationError) do
      validate(effect_args: ["x" * 513])
    end
    assert_match(/#1 exceeds 512 characters \(got 513\)/, error.message)
  end

  def test_effect_arg_exactly_512_chars_passes
    validate(effect_args: ["x" * 512])
  end

  def test_empty_effect_arg_fails
    error = assert_raises(Ace::Hitl::Atoms::HitlEffectValidator::ValidationError) do
      validate(effect_args: [""])
    end
    assert_match(/#1 is empty/, error.message)
  end

  def test_whitespace_only_effect_arg_fails_like_lab_strip_check
    error = assert_raises(Ace::Hitl::Atoms::HitlEffectValidator::ValidationError) do
      validate(effect_args: ["   "])
    end
    assert_match(/#1 is empty/, error.message)
  end

  def test_padded_effect_arg_passes
    validate(effect_args: ["  /bin/false  "])
  end

  def test_effect_arg_bounds_apply_to_stripped_value
    validate(effect_args: ["#{"x" * 512}  "])

    error = assert_raises(Ace::Hitl::Atoms::HitlEffectValidator::ValidationError) do
      validate(effect_args: ["  #{"x" * 513}  "])
    end
    assert_match(/#1 exceeds 512 characters \(got 513\)/, error.message)
  end

  # -- cwd: absolute and existing -------------------------------------------

  def test_relative_cwd_fails
    error = assert_raises(Ace::Hitl::Atoms::HitlEffectValidator::ValidationError) do
      validate(effect_args: ["x"], effect_cwd: "relative/dir")
    end
    assert_match(/must be an absolute path/, error.message)
  end

  def test_nonexistent_absolute_cwd_fails
    error = assert_raises(Ace::Hitl::Atoms::HitlEffectValidator::ValidationError) do
      validate(effect_args: ["x"], effect_cwd: "/nonexistent-ace-hitl-test-cwd")
    end
    assert_match(/does not exist/, error.message)
  end

  def test_existing_absolute_cwd_passes
    validate(effect_args: ["x"], effect_cwd: "/tmp")
  end

  # -- timeout: range --------------------------------------------------------

  def test_timeout_below_1_fails
    error = assert_raises(Ace::Hitl::Atoms::HitlEffectValidator::ValidationError) do
      validate(effect_args: ["x"], effect_timeout: "0")
    end
    assert_match(/must be between 1 and 600 \(got 0\)/, error.message)
  end

  def test_timeout_over_600_fails
    error = assert_raises(Ace::Hitl::Atoms::HitlEffectValidator::ValidationError) do
      validate(effect_args: ["x"], effect_timeout: "601")
    end
    assert_match(/must be between 1 and 600 \(got 601\)/, error.message)
  end

  def test_timeout_non_integer_fails
    error = assert_raises(Ace::Hitl::Atoms::HitlEffectValidator::ValidationError) do
      validate(effect_args: ["x"], effect_timeout: "soon")
    end
    assert_match(/must be an integer/, error.message)
  end

  def test_timeout_bounds_pass
    validate(effect_args: ["x"], effect_timeout: "1")
    validate(effect_args: ["x"], effect_timeout: "600")
  end

  # -- no effect flags at all ------------------------------------------------

  def test_no_effect_flags_passes
    validate
  end
end
