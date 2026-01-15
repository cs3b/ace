# frozen_string_literal: true

require_relative "../test_helper"
require "ace/context/atoms/preset_validator"
require "ace/context/molecules/preset_manager"

class PresetValidatorTest < AceTestCase
  def setup
    @preset_manager = Ace::Context::Molecules::PresetManager.new
  end

  def test_check_circular_dependency_detects_circular_reference
    chain = ["preset_a", "preset_b", "preset_c"]
    result = Ace::Context::Atoms::PresetValidator.check_circular_dependency("preset_a", chain)

    assert_equal false, result[:success]
    assert_match(/Circular dependency detected/, result[:error])
  end

  def test_check_circular_dependency_allows_valid_chain
    chain = ["preset_a", "preset_b"]
    result = Ace::Context::Atoms::PresetValidator.check_circular_dependency("preset_c", chain)

    assert_equal true, result[:success]
  end

  def test_check_circular_dependency_enforces_max_depth
    chain = Array.new(10, "preset")
    result = Ace::Context::Atoms::PresetValidator.check_circular_dependency("another_preset", chain)

    assert_equal false, result[:success]
    assert_match(/Maximum preset nesting depth/, result[:error])
  end

  def test_extract_preset_references_from_config
    preset_data = {
      context: {
        'presets' => ['base', 'development']
      }
    }

    refs = Ace::Context::Atoms::PresetValidator.extract_preset_references(preset_data)

    assert_equal ['base', 'development'], refs
  end

  def test_extract_preset_references_returns_empty_for_no_presets
    preset_data = {
      context: {
        'files' => ['README.md']
      }
    }

    refs = Ace::Context::Atoms::PresetValidator.extract_preset_references(preset_data)

    assert_equal [], refs
  end

  def test_extract_preset_references_handles_nil
    refs = Ace::Context::Atoms::PresetValidator.extract_preset_references(nil)

    assert_equal [], refs
  end

  def test_validate_presets_identifies_valid_and_missing
    # This test requires actual preset files, so it's more of an integration test
    # For now, we'll skip it unless we set up fixture presets
    skip "Requires fixture preset setup"
  end
end
