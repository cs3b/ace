# frozen_string_literal: true

require 'test_helper'
require 'ace/review/atoms/preset_validator'

module Ace
  module Review
    module Atoms
      class PresetValidatorTest < AceReviewTest
        def setup
          super
          @validator = PresetValidator
          @preset_manager = Minitest::Mock.new
        end

        def test_check_circular_dependency_no_cycle
          result = @validator.check_circular_dependency('preset-a', [])
          assert result[:success]
        end

        def test_check_circular_dependency_detects_cycle
          result = @validator.check_circular_dependency('preset-a', ['preset-b', 'preset-a'])
          refute result[:success]
          assert_includes result[:error], 'Circular dependency detected'
          assert_includes result[:error], 'preset-b -> preset-a -> preset-a'
        end

        def test_check_circular_dependency_max_depth_exceeded
          chain = (1..10).map { |i| "preset-#{i}" }
          result = @validator.check_circular_dependency('preset-11', chain)
          refute result[:success]
          assert_includes result[:error], 'Maximum preset nesting depth (10) exceeded'
        end

        def test_preset_exists_returns_true_when_exists
          @preset_manager.expect(:preset_exists?, true, ['test-preset'])

          result = @validator.preset_exists?('test-preset', @preset_manager)
          assert result
          @preset_manager.verify
        end

        def test_preset_exists_returns_false_when_missing
          @preset_manager.expect(:preset_exists?, false, ['missing-preset'])

          result = @validator.preset_exists?('missing-preset', @preset_manager)
          refute result
          @preset_manager.verify
        end

        def test_validate_presets_all_valid
          @preset_manager.expect(:preset_exists?, true, ['preset-a'])
          @preset_manager.expect(:preset_exists?, true, ['preset-b'])

          result = @validator.validate_presets(['preset-a', 'preset-b'], @preset_manager)

          assert result[:success]
          assert_equal ['preset-a', 'preset-b'], result[:valid]
          assert_empty result[:missing]
          @preset_manager.verify
        end

        def test_validate_presets_some_missing
          @preset_manager.expect(:preset_exists?, true, ['preset-a'])
          @preset_manager.expect(:preset_exists?, false, ['missing-preset'])

          result = @validator.validate_presets(['preset-a', 'missing-preset'], @preset_manager)

          refute result[:success]
          assert_equal ['preset-a'], result[:valid]
          assert_equal ['missing-preset'], result[:missing]
          @preset_manager.verify
        end

        def test_extract_preset_references_from_string_keys
          preset_data = {
            "description" => "Test preset",
            "presets" => ["base", "code"]
          }

          refs = @validator.extract_preset_references(preset_data)
          assert_equal ["base", "code"], refs
        end

        def test_extract_preset_references_from_symbol_keys
          preset_data = {
            description: "Test preset",
            presets: ["base", "code"]
          }

          refs = @validator.extract_preset_references(preset_data)
          assert_equal ["base", "code"], refs
        end

        def test_extract_preset_references_single_preset_as_string
          preset_data = {
            "presets" => "base"
          }

          refs = @validator.extract_preset_references(preset_data)
          assert_equal ["base"], refs
        end

        def test_extract_preset_references_empty_when_no_presets_key
          preset_data = {
            "description" => "Test preset"
          }

          refs = @validator.extract_preset_references(preset_data)
          assert_empty refs
        end

        def test_extract_preset_references_empty_when_nil_data
          refs = @validator.extract_preset_references(nil)
          assert_empty refs
        end

        def test_extract_preset_references_converts_symbols_to_strings
          preset_data = {
            presets: [:base, :code]
          }

          refs = @validator.extract_preset_references(preset_data)
          assert_equal ["base", "code"], refs
          assert refs.all? { |ref| ref.is_a?(String) }
        end
      end
    end
  end
end
