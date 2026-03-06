# frozen_string_literal: true

require "test_helper"

module Ace
  module Review
    module Models
      class ReviewerTest < AceReviewTest
        def setup
          super
          @valid_config = {
            name: "code-fit",
            model: "google:gemini-2.5-pro",
            focus: "code_quality",
            system_prompt_additions: "Focus on SOLID principles.",
            file_patterns: {
              include: ["lib/**/*.rb", "src/**/*.ts"],
              exclude: ["**/*_test.rb", "**/*.spec.ts"]
            },
            weight: 1.0,
            critical: false
          }
        end

        # Initialization tests

        def test_initialization_with_all_attributes
          reviewer = Reviewer.new(@valid_config)

          assert_equal "code-fit", reviewer.name
          assert_equal "google:gemini-2.5-pro", reviewer.model
          assert_equal "code_quality", reviewer.focus
          assert_equal "Focus on SOLID principles.", reviewer.system_prompt_additions
          assert_equal "Focus on SOLID principles.", reviewer.prompt.dig("sections", "reviewer_notes", "content")
          assert_equal ["lib/**/*.rb", "src/**/*.ts"], reviewer.file_patterns["include"]
          assert_equal ["**/*_test.rb", "**/*.spec.ts"], reviewer.file_patterns["exclude"]
          assert_equal 1.0, reviewer.weight
          assert_equal false, reviewer.critical
        end

        def test_initialization_with_string_keys
          string_config = {
            "name" => "security",
            "model" => "openai:gpt-4o",
            "focus" => "security",
            "critical" => true
          }
          reviewer = Reviewer.new(string_config)

          assert_equal "security", reviewer.name
          assert_equal "openai:gpt-4o", reviewer.model
          assert_equal true, reviewer.critical
        end

        def test_initialization_with_minimal_config
          reviewer = Reviewer.new(model: "google:gemini-2.5-flash")

          assert_equal "google:gemini-2.5-flash", reviewer.model
          assert_nil reviewer.name
          assert_nil reviewer.focus
          assert_nil reviewer.system_prompt_additions
          assert_equal({}, reviewer.prompt)
          assert_equal Reviewer::DEFAULT_WEIGHT, reviewer.weight
          assert_equal false, reviewer.critical
        end

        def test_initialization_with_default_weight
          config = @valid_config.except(:weight)
          reviewer = Reviewer.new(config)

          assert_equal 1.0, reviewer.weight
        end

        def test_initialization_raises_without_model
          config = @valid_config.except(:model)

          error = assert_raises(ArgumentError) { Reviewer.new(config) }
          assert_includes error.message, "model is required"
        end

        def test_initialization_raises_with_empty_model
          config = @valid_config.merge(model: "")

          error = assert_raises(ArgumentError) { Reviewer.new(config) }
          assert_includes error.message, "model is required"
        end

        def test_initialization_raises_with_invalid_weight
          config = @valid_config.merge(weight: 1.5)
          error = assert_raises(ArgumentError) { Reviewer.new(config) }
          assert_includes error.message, "weight must be between 0 and 1"

          config = @valid_config.merge(weight: -0.1)
          error = assert_raises(ArgumentError) { Reviewer.new(config) }
          assert_includes error.message, "weight must be between 0 and 1"
        end

        def test_initialization_raises_for_llm_reviewer_without_prompt
          config = @valid_config.except(:system_prompt_additions).merge(reviewer_type: "llm")

          error = assert_raises(ArgumentError) { Reviewer.new(config) }
          assert_includes error.message, "must define a prompt"
        end

        # Factory method tests

        def test_from_model_string
          reviewer = Reviewer.from_model_string("google:gemini-2.5-flash")

          assert_equal "default", reviewer.name
          assert_equal "google:gemini-2.5-flash", reviewer.model
        end

        def test_from_model_string_with_custom_name
          reviewer = Reviewer.from_model_string("claude:sonnet", name: "custom-reviewer")

          assert_equal "custom-reviewer", reviewer.name
          assert_equal "claude:sonnet", reviewer.model
        end

        def test_from_models_array
          models = ["google:gemini-2.5-flash", "openai:gpt-4o"]
          reviewers = Reviewer.from_models_array(models)

          assert_equal 2, reviewers.length
          assert_equal "reviewer-1", reviewers[0].name
          assert_equal "google:gemini-2.5-flash", reviewers[0].model
          assert_equal "reviewer-2", reviewers[1].name
          assert_equal "openai:gpt-4o", reviewers[1].model
        end

        def test_from_preset_config_with_reviewers_array
          config = {
            "reviewers" => [
              { "name" => "quality", "providers" => ["llm:google:google:gemini-2.5-pro"], "focus" => "code_quality" },
              {
                "name" => "security",
                "providers" => ["llm:openai:openai:gpt-4o"],
                "focus" => "security",
                "critical" => true,
                "prompt" => { "base" => "prompt://base/system" }
              }
            ]
          }
          config["reviewers"][0]["prompt"] = { "base" => "prompt://base/system" }
          reviewers = Reviewer.from_preset_config(config)

          assert_equal 2, reviewers.length
          assert_equal "quality", reviewers[0].name
          assert_equal "google:gemini-2.5-pro", reviewers[0].model
          assert_equal "security", reviewers[1].name
          assert_equal true, reviewers[1].critical
        end

        def test_from_preset_config_with_legacy_models_array_raises
          config = { "models" => ["google:gemini-2.5-flash", "openai:gpt-4o"] }
          error = assert_raises(ArgumentError) { Reviewer.from_preset_config(config) }
          assert_match(/legacy top-level model\/models/i, error.message)
        end

        def test_from_preset_config_with_legacy_single_model_raises
          config = { "model" => "google:gemini-2.5-flash" }
          error = assert_raises(ArgumentError) { Reviewer.from_preset_config(config) }
          assert_match(/legacy top-level model\/models/i, error.message)
        end

        def test_from_preset_config_with_empty_config
          reviewers = Reviewer.from_preset_config({})
          assert_empty reviewers
        end

        def test_from_preset_config_prefers_reviewers_over_models
          config = {
            "reviewers" => [{
              "name" => "custom",
              "providers" => ["llm:custom:custom:model"],
              "prompt" => { "base" => "prompt://base/system" }
            }],
            "models" => ["google:gemini-2.5-flash"]
          }
          reviewers = Reviewer.from_preset_config(config)

          assert_equal 1, reviewers.length
          assert_equal "custom", reviewers[0].name
          assert_equal "custom:model", reviewers[0].model
        end

        def test_from_definition_expands_multiple_providers_into_lanes
          lanes = Reviewer.from_definition(
            {
              "name" => "code-fit",
              "focus" => "code_quality",
              "prompt" => { "base" => "prompt://base/system" },
              "providers" => [
                "llm:codex:codex:codex@rw",
                {
                  "provider" => "llm:claude:anthropic:claude-3-7-sonnet",
                  "timeout" => 180,
                  "sandbox" => "read-only"
                }
              ]
            },
            default_provider_options: { "timeout" => 300 }
          )

          assert_equal 2, lanes.length
          assert_equal "codex:codex@rw", lanes[0].model
          assert_equal "anthropic:claude-3-7-sonnet", lanes[1].model
          assert_equal 300, lanes[0].provider_options["timeout"]
          assert_equal 180, lanes[1].provider_options["timeout"]
          assert_equal "read-only", lanes[1].provider_options["sandbox"]
        end

        def test_from_definition_rejects_removed_provider_field
          error = assert_raises(ArgumentError) do
            Reviewer.from_definition(
              {
                "name" => "lint",
                "provider" => "tool:lint"
              }
            )
          end

          assert_match(/removed field 'provider'/i, error.message)
        end

        # Prompt normalization tests

        def test_normalizes_system_prompt_additions_into_prompt_sections
          reviewer = Reviewer.new(@valid_config)

          notes = reviewer.prompt.fetch("sections").fetch("reviewer_notes")
          assert_equal "Reviewer Notes", notes["title"]
          assert_equal "Additional reviewer-specific instructions", notes["description"]
          assert_equal "Focus on SOLID principles.", notes["content"]
        end

        def test_normalizes_into_existing_reviewer_notes_section
          reviewer = Reviewer.new(
            @valid_config.merge(
              prompt: {
                sections: {
                  reviewer_notes: {
                    content: "Existing note."
                  }
                }
              }
            )
          )

          assert_equal "Existing note.\n\nFocus on SOLID principles.",
                       reviewer.prompt.dig("sections", "reviewer_notes", "content")
        end

        # File pattern matching tests

        def test_has_file_patterns_with_include
          reviewer = Reviewer.new(@valid_config)
          assert reviewer.has_file_patterns?
        end

        def test_has_file_patterns_without_patterns
          config = @valid_config.except(:file_patterns)
          reviewer = Reviewer.new(config)
          refute reviewer.has_file_patterns?
        end

        def test_has_file_patterns_with_empty_arrays
          config = @valid_config.merge(file_patterns: { include: [], exclude: [] })
          reviewer = Reviewer.new(config)
          refute reviewer.has_file_patterns?
        end

        def test_matches_file_with_include_pattern
          reviewer = Reviewer.new(@valid_config)

          assert reviewer.matches_file?("lib/models/user.rb")
          assert reviewer.matches_file?("src/components/Button.ts")
          refute reviewer.matches_file?("app/models/user.rb")
        end

        def test_matches_file_with_exclude_pattern
          reviewer = Reviewer.new(@valid_config)

          refute reviewer.matches_file?("lib/models/user_test.rb")
          refute reviewer.matches_file?("src/components/Button.spec.ts")
        end

        def test_matches_file_without_patterns
          config = @valid_config.except(:file_patterns)
          reviewer = Reviewer.new(config)

          assert reviewer.matches_file?("any/path/file.rb")
        end

        def test_matches_file_with_only_exclude
          config = @valid_config.merge(file_patterns: { exclude: ["**/*_test.rb"] })
          reviewer = Reviewer.new(config)

          assert reviewer.matches_file?("lib/models/user.rb")
          refute reviewer.matches_file?("lib/models/user_test.rb")
        end

        # Subject filtering tests

        def test_filter_subject_with_string_diff
          reviewer = Reviewer.new(@valid_config)
          diff_content = <<~DIFF
            diff --git a/lib/models/user.rb b/lib/models/user.rb
            index abc123..def456 100644
            --- a/lib/models/user.rb
            +++ b/lib/models/user.rb
            @@ -1,3 +1,4 @@
            +# New line
             class User
             end
            diff --git a/lib/models/user_test.rb b/lib/models/user_test.rb
            index 111111..222222 100644
            --- a/lib/models/user_test.rb
            +++ b/lib/models/user_test.rb
            @@ -1,2 +1,3 @@
            +# Test file
             class UserTest
             end
          DIFF

          filtered = reviewer.filter_subject(diff_content)

          assert_includes filtered, "lib/models/user.rb"
          refute_includes filtered, "lib/models/user_test.rb"
        end

        def test_filter_subject_with_hash
          reviewer = Reviewer.new(@valid_config)
          subject = {
            "files" => [
              "lib/models/user.rb",
              "lib/models/user_test.rb",
              "src/Button.ts"
            ]
          }

          filtered = reviewer.filter_subject(subject)

          assert_equal 2, filtered["files"].length
          assert_includes filtered["files"], "lib/models/user.rb"
          assert_includes filtered["files"], "src/Button.ts"
          refute_includes filtered["files"], "lib/models/user_test.rb"
        end

        def test_filter_subject_without_patterns
          config = @valid_config.except(:file_patterns)
          reviewer = Reviewer.new(config)
          subject = "unchanged content"

          filtered = reviewer.filter_subject(subject)

          assert_equal subject, filtered
        end

        # Serialization tests

        def test_to_h
          reviewer = Reviewer.new(@valid_config)
          hash = reviewer.to_h

          assert_equal "code-fit", hash["name"]
          assert_equal "google:gemini-2.5-pro", hash["model"]
          assert_equal "code_quality", hash["focus"]
          assert_equal 1.0, hash["weight"]
          assert_equal false, hash["critical"]
        end

        def test_to_h_excludes_nil_values
          config = { model: "google:gemini-2.5-flash" }
          reviewer = Reviewer.new(config)
          hash = reviewer.to_h

          refute hash.key?("name")
          refute hash.key?("focus")
          refute hash.key?("system_prompt_additions")
        end

        # Equality tests

        def test_equality
          reviewer1 = Reviewer.new(@valid_config)
          reviewer2 = Reviewer.new(@valid_config)

          assert_equal reviewer1, reviewer2
        end

        def test_inequality_with_different_model
          reviewer1 = Reviewer.new(@valid_config)
          reviewer2 = Reviewer.new(@valid_config.merge(model: "different:model"))

          refute_equal reviewer1, reviewer2
        end

        def test_hash_consistency
          reviewer1 = Reviewer.new(@valid_config)
          reviewer2 = Reviewer.new(@valid_config)

          assert_equal reviewer1.hash, reviewer2.hash
        end

        # provider_class / template tests

        def test_template_from_definition_llm_creates_template
          template = Reviewer.template_from_definition(
            "name" => "correctness",
            "focus" => "correctness",
            "weight" => 1.0,
            "critical" => true,
            "provider_class" => "llm",
            "prompt" => { "base" => "prompt://base/system" }
          )

          assert_equal "correctness", template.name
          assert_equal "correctness", template.focus
          assert_equal "llm", template.provider_class
          assert_equal "llm", template.reviewer_type
          assert_nil template.model
          assert_nil template.provider_ref
        end

        def test_template_from_definition_tools_lint_creates_template
          template = Reviewer.template_from_definition(
            "name" => "lint",
            "focus" => "lint",
            "weight" => 0.6,
            "provider_class" => "tools-lint"
          )

          assert_equal "lint", template.name
          assert_equal "tools-lint", template.provider_class
          assert_equal "tool", template.reviewer_type
          assert_nil template.model
        end

        def test_template_from_definition_raises_for_unknown_class
          error = assert_raises(ArgumentError) do
            Reviewer.template_from_definition(
              "name" => "bad",
              "provider_class" => "unknown-class"
            )
          end
          assert_includes error.message, "unknown-class"
        end

        def test_from_definition_with_provider_class_returns_single_template
          results = Reviewer.from_definition({
            "name" => "correctness",
            "focus" => "correctness",
            "provider_class" => "llm",
            "prompt" => { "base" => "prompt://base/system" }
          })

          assert_equal 1, results.size
          assert_equal "llm", results.first.provider_class
          assert_nil results.first.model
        end

        def test_from_catalog_entry_llm_creates_resolved_reviewer
          template = Reviewer.template_from_definition(
            "name" => "correctness",
            "focus" => "correctness",
            "provider_class" => "llm",
            "prompt" => { "base" => "prompt://base/system" }
          )
          catalog_entry = { "name" => "ro", "model" => "codex:spark@ro" }

          resolved = Reviewer.from_catalog_entry(template, catalog_entry, index: 0)

          assert_equal "correctness", resolved.name
          assert_equal "codex:spark@ro", resolved.model
          assert_equal "llm", resolved.provider_kind
          assert_equal "llm", resolved.reviewer_type
          refute_nil resolved.lane_id
          refute_nil resolved.provider_ref
        end

        def test_from_catalog_entry_tools_lint_creates_resolved_reviewer
          template = Reviewer.template_from_definition(
            "name" => "lint",
            "focus" => "lint",
            "provider_class" => "tools-lint"
          )
          catalog_entry = { "name" => "lint", "tool" => "lint" }

          resolved = Reviewer.from_catalog_entry(template, catalog_entry, index: 0)

          assert_equal "lint", resolved.name
          assert_equal "tool:lint", resolved.model
          assert_equal "tool", resolved.provider_kind
          assert_equal "tool", resolved.reviewer_type
        end

        def test_template_allows_nil_model
          # Template reviewers with provider_class should not require model
          template = Reviewer.new(
            "name" => "correctness",
            "provider_class" => "llm",
            "reviewer_type" => "llm",
            "prompt" => { "base" => "prompt://base/system" }
          )
          assert_nil template.model
          assert_equal "llm", template.provider_class
        end

        def test_to_h_includes_provider_class
          template = Reviewer.template_from_definition(
            "name" => "correctness",
            "focus" => "correctness",
            "provider_class" => "llm",
            "prompt" => { "base" => "prompt://base/system" }
          )
          hash = template.to_h
          assert_equal "llm", hash["provider_class"]
        end
      end
    end
  end
end
