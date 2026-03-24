# frozen_string_literal: true

require "test_helper"
require "ace/review/atoms/preset_validator"

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
          result = @validator.check_circular_dependency("preset-a", [])
          assert result[:success]
        end

        def test_check_circular_dependency_detects_cycle
          result = @validator.check_circular_dependency("preset-a", ["preset-b", "preset-a"])
          refute result[:success]
          assert_includes result[:error], "Circular dependency detected"
          assert_includes result[:error], "preset-b -> preset-a -> preset-a"
        end

        def test_check_circular_dependency_max_depth_exceeded
          chain = (1..10).map { |i| "preset-#{i}" }
          result = @validator.check_circular_dependency("preset-11", chain)
          refute result[:success]
          assert_includes result[:error], "Maximum preset nesting depth (10) exceeded"
        end

        def test_preset_exists_returns_true_when_exists
          @preset_manager.expect(:preset_exists?, true, ["test-preset"])

          result = @validator.preset_exists?("test-preset", @preset_manager)
          assert result
          @preset_manager.verify
        end

        def test_preset_exists_returns_false_when_missing
          @preset_manager.expect(:preset_exists?, false, ["missing-preset"])

          result = @validator.preset_exists?("missing-preset", @preset_manager)
          refute result
          @preset_manager.verify
        end

        def test_validate_presets_all_valid
          @preset_manager.expect(:preset_exists?, true, ["preset-a"])
          @preset_manager.expect(:preset_exists?, true, ["preset-b"])

          result = @validator.validate_presets(["preset-a", "preset-b"], @preset_manager)

          assert result[:success]
          assert_equal ["preset-a", "preset-b"], result[:valid]
          assert_empty result[:missing]
          @preset_manager.verify
        end

        def test_validate_presets_some_missing
          @preset_manager.expect(:preset_exists?, true, ["preset-a"])
          @preset_manager.expect(:preset_exists?, false, ["missing-preset"])

          result = @validator.validate_presets(["preset-a", "missing-preset"], @preset_manager)

          refute result[:success]
          assert_equal ["preset-a"], result[:valid]
          assert_equal ["missing-preset"], result[:missing]
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

        # Preset name validation tests
        def test_validate_preset_name_valid
          result = @validator.validate_preset_name("valid-preset")
          assert result[:success]
        end

        def test_validate_preset_name_nil
          result = @validator.validate_preset_name(nil)
          refute result[:success]
          assert_equal "Preset name cannot be nil or empty", result[:error]
        end

        def test_validate_preset_name_empty
          result = @validator.validate_preset_name("")
          refute result[:success]
          assert_equal "Preset name cannot be nil or empty", result[:error]
        end

        def test_validate_preset_name_path_traversal
          result = @validator.validate_preset_name("../etc/passwd")
          refute result[:success]
          assert_includes result[:error], "cannot contain path separators"
        end

        def test_validate_preset_name_forward_slash
          result = @validator.validate_preset_name("foo/bar")
          refute result[:success]
          assert_includes result[:error], "cannot contain path separators"
        end

        def test_validate_preset_name_backslash
          result = @validator.validate_preset_name('foo\\bar')
          refute result[:success]
          assert_includes result[:error], "cannot contain path separators"
        end

        def test_validate_preset_name_too_long
          long_name = "a" * 101
          result = @validator.validate_preset_name(long_name)
          refute result[:success]
          assert_includes result[:error], "too long"
        end

        # Error message format tests
        def test_circular_dependency_error_message_format
          result = @validator.check_circular_dependency("preset-c", ["preset-a", "preset-b", "preset-c"])
          refute result[:success]
          assert_match(/Circular dependency detected: preset-a -> preset-b -> preset-c -> preset-c/, result[:error])
        end

        def test_max_depth_error_message_format
          chain = (1..10).map { |i| "preset-#{i}" }
          result = @validator.check_circular_dependency("preset-11", chain)
          refute result[:success]
          assert_match(/Maximum preset nesting depth \(10\) exceeded/, result[:error])
          assert_includes result[:error], "preset-1"
        end

        def test_validate_presets_error_includes_missing_names
          @preset_manager.expect(:preset_exists?, true, ["exists"])
          @preset_manager.expect(:preset_exists?, false, ["missing1"])
          @preset_manager.expect(:preset_exists?, false, ["missing2"])

          result = @validator.validate_presets(["exists", "missing1", "missing2"], @preset_manager)

          refute result[:success]
          assert_equal ["missing1", "missing2"], result[:missing]
          @preset_manager.verify
        end
      end
    end
  end
end
