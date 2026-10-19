# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module Atoms
      class RolePresetSchemaTest < AceCoworkerTestCase
        def valid_preset
          {
            "name" => "worker",
            "instructions" => "wfi://coworker/worker",
            "start_prompt" => "Drive {{assignment}} as {{role}}.",
            "reporting" => {"channel" => "hitl"},
            "errors" => {"on_failure" => "report"}
          }
        end

        def test_valid_preset_passes
          assert_empty RolePresetSchema.errors(valid_preset)
        end

        def test_nil_and_non_mapping_presets_are_rejected
          assert_equal ["preset is empty"], RolePresetSchema.errors(nil)
          assert_equal ["preset is empty"], RolePresetSchema.errors("")
          assert_equal 1, RolePresetSchema.errors(["x"]).size
          assert_includes RolePresetSchema.errors(["x"]), "preset must be a mapping, got Array"
        end

        def test_missing_required_fields_are_field_specific
          preset = valid_preset
          %w[name instructions start_prompt].each do |field|
            broken = preset.reject { |key, _| key == field }
            errors = RolePresetSchema.errors(broken)
            assert_equal ["missing required field '#{field}'"], errors
          end
        end

        def test_blank_required_fields_are_rejected
          preset = valid_preset.merge("name" => "  ")
          assert_includes RolePresetSchema.errors(preset), "missing required field 'name'"
        end

        def test_invalid_reporting_channel_is_rejected
          preset = valid_preset.merge("reporting" => {"channel" => "email"})
          assert_includes RolePresetSchema.errors(preset),
            "reporting.channel 'email' is not one of: hitl"
        end

        def test_invalid_on_failure_is_rejected
          preset = valid_preset.merge("errors" => {"on_failure" => "ignore"})
          assert_includes RolePresetSchema.errors(preset),
            "errors.on_failure 'ignore' is not one of: report, stop"
        end

        def test_non_mapping_nested_sections_are_rejected
          assert_includes RolePresetSchema.errors(valid_preset.merge("reporting" => "hitl")),
            "'reporting' must be a mapping, got String"
          assert_includes RolePresetSchema.errors(valid_preset.merge("errors" => "stop")),
            "'errors' must be a mapping, got String"
        end

        def test_empty_description_is_rejected_when_present
          preset = valid_preset.merge("description" => "  ")
          assert_includes RolePresetSchema.errors(preset), "'description' must be a non-empty string"
        end

        def test_normalize_exposes_preset_fields
          normalized = RolePresetSchema.normalize(valid_preset.merge("description" => "Worker role"))
          assert_equal "worker", normalized["name"]
          assert_equal "Worker role", normalized["description"]
          assert_equal "wfi://coworker/worker", normalized["instructions"]
          assert_equal "hitl", normalized["reporting"]
          assert_equal "report", normalized["errors"]
        end
      end
    end
  end
end
