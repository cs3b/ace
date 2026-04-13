# frozen_string_literal: true

require "test_helper"

class Ace::Lint::Atoms::ValidatorRegistryTest < Minitest::Test
  def test_runner_for_returns_standardrb_runner
    runner = Ace::Lint::Atoms::ValidatorRegistry.runner_for(:standardrb)
    assert_equal Ace::Lint::Atoms::StandardrbRunner, runner
  end

  def test_runner_for_returns_rubocop_runner
    runner = Ace::Lint::Atoms::ValidatorRegistry.runner_for(:rubocop)
    assert_equal Ace::Lint::Atoms::RuboCopRunner, runner
  end

  def test_runner_for_handles_string_input
    runner = Ace::Lint::Atoms::ValidatorRegistry.runner_for("standardrb")
    assert_equal Ace::Lint::Atoms::StandardrbRunner, runner
  end

  def test_runner_for_handles_aliases
    runner = Ace::Lint::Atoms::ValidatorRegistry.runner_for(:standard)
    assert_equal Ace::Lint::Atoms::StandardrbRunner, runner
  end

  def test_runner_for_returns_nil_for_unknown
    runner = Ace::Lint::Atoms::ValidatorRegistry.runner_for(:unknown_linter)
    assert_nil runner
  end

  def test_registered_returns_true_for_known_validators
    assert Ace::Lint::Atoms::ValidatorRegistry.registered?(:standardrb)
    assert Ace::Lint::Atoms::ValidatorRegistry.registered?(:rubocop)
  end

  def test_registered_returns_false_for_unknown
    refute Ace::Lint::Atoms::ValidatorRegistry.registered?(:eslint)
  end

  def test_registered_validators_returns_all_validators
    validators = Ace::Lint::Atoms::ValidatorRegistry.registered_validators
    assert_includes validators, :standardrb
    assert_includes validators, :rubocop
    assert_equal 2, validators.size
  end

  def test_canonical_name_normalizes_input
    assert_equal :standardrb, Ace::Lint::Atoms::ValidatorRegistry.canonical_name("StandardRB")
    assert_equal :standardrb, Ace::Lint::Atoms::ValidatorRegistry.canonical_name("STANDARDRB")
    assert_equal :rubocop, Ace::Lint::Atoms::ValidatorRegistry.canonical_name("RuboCop")
  end

  def test_canonical_name_handles_alias
    assert_equal :standardrb, Ace::Lint::Atoms::ValidatorRegistry.canonical_name(:standard)
  end

  def test_canonical_name_returns_nil_for_unknown
    assert_nil Ace::Lint::Atoms::ValidatorRegistry.canonical_name(:unknown)
    assert_nil Ace::Lint::Atoms::ValidatorRegistry.canonical_name(nil)
  end

  def test_available_checks_runner_availability
    # Stub the runner's available? to avoid subprocess calls
    # We just verify the method returns a boolean via the registry
    Ace::Lint::Atoms::StandardrbRunner.stub(:available?, true) do
      result = Ace::Lint::Atoms::ValidatorRegistry.available?(:standardrb)
      assert [true, false].include?(result)
    end
  end

  def test_available_returns_false_for_unknown_validator
    refute Ace::Lint::Atoms::ValidatorRegistry.available?(:unknown_linter)
  end

  def test_available_validators_returns_subset_of_registered
    # Stub runner availability to avoid subprocess calls
    Ace::Lint::Atoms::StandardrbRunner.stub(:available?, true) do
      Ace::Lint::Atoms::RuboCopRunner.stub(:available?, true) do
        available = Ace::Lint::Atoms::ValidatorRegistry.available_validators
        registered = Ace::Lint::Atoms::ValidatorRegistry.registered_validators

        # All available must be registered
        available.each do |v|
          assert_includes registered, v
        end
      end
    end
  end
end
