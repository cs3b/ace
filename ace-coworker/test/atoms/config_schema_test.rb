# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"

module Ace
  module Coworker
    module Atoms
      class ConfigSchemaTest < AceCoworkerTestCase
        def valid
          {
            "role" => "worker",
            "instructions" => "roles/worker.md",
            "start_prompt" => "Drive it.",
            "task" => "8xg.t.sbz.2",
            "assignment" => "abc123",
            "overseer" => "overseer@lab"
          }
        end

        def test_valid_config_has_no_errors
          assert_empty ConfigSchema.errors(valid)
        end

        def test_each_missing_required_field_is_specific
          %w[role instructions task assignment overseer].each do |field|
            raw = valid.reject { |k, _| k == field }
            errors = ConfigSchema.errors(raw)
            assert_includes errors, "missing required field '#{field}'", field
          end
        end

        def test_missing_start_prompt_reports_start_prompt_field
          errors = ConfigSchema.errors(valid.reject { |k, _| k == "start_prompt" })
          assert_includes errors, "missing required field 'start_prompt' (or 'start_prompt_file')"
        end

        def test_start_prompt_file_is_accepted_as_alternative
          raw = valid.reject { |k, _| k == "start_prompt" }
          raw["start_prompt_file"] = "prompts/start.md"
          assert_empty ConfigSchema.errors(raw)
        end

        def test_start_prompt_and_file_are_mutually_exclusive
          raw = valid.merge("start_prompt_file" => "prompts/start.md")
          assert_includes ConfigSchema.errors(raw), "'start_prompt' and 'start_prompt_file' are mutually exclusive"
        end

        def test_nil_and_non_mapping_configs_error
          assert_equal ["config is empty"], ConfigSchema.errors(nil)
          assert_equal 1, ConfigSchema.errors("nope").size
        end

        def test_invalid_enums_error_specifically
          raw = valid.merge("reporting" => {"channel" => "smtp"})
          assert_includes ConfigSchema.errors(raw), "reporting.channel 'smtp' is not one of: hitl"

          raw = valid.merge("errors" => {"on_failure" => "explode"})
          assert_includes ConfigSchema.errors(raw), "errors.on_failure 'explode' is not one of: report, stop"
        end

        def test_normalize_applies_documented_defaults
          normalized = ConfigSchema.normalize(valid)
          assert_equal "hitl", normalized.dig("reporting", "channel")
          assert_equal "report", normalized.dig("errors", "on_failure")
          assert_equal "worker", normalized["role"]
        end

        def test_protocol_detection
          assert ConfigSchema.protocol?("wfi://task/work")
          assert ConfigSchema.protocol?("prompt://roles/worker")
          assert ConfigSchema.protocol?("tmpl://x")
          refute ConfigSchema.protocol?("roles/worker.md")
        end
      end
    end
  end
end
