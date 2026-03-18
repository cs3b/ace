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

        def test_from_preset_config_with_reviewers_array
          config = {
            "reviewers" => [
              { "name" => "quality", "model" => "google:gemini-2.5-pro", "focus" => "code_quality" },
              { "name" => "security", "model" => "openai:gpt-4o", "focus" => "security", "critical" => true }
            ]
          }
          reviewers = Reviewer.from_preset_config(config)

          assert_equal 2, reviewers.length
          assert_equal "quality", reviewers[0].name
          assert_equal "google:gemini-2.5-pro", reviewers[0].model
          assert_equal "security", reviewers[1].name
          assert_equal true, reviewers[1].critical
        end

        def test_from_preset_config_with_empty_config
          reviewers = Reviewer.from_preset_config({})
          assert_empty reviewers
        end

        # System prompt enhancement tests

        def test_enhance_system_prompt
          reviewer = Reviewer.new(@valid_config)
          base_prompt = "You are a code reviewer."

          enhanced = reviewer.enhance_system_prompt(base_prompt)

          assert_includes enhanced, "You are a code reviewer."
          assert_includes enhanced, "Focus on SOLID principles."
        end

        def test_enhance_system_prompt_with_nil_base
          reviewer = Reviewer.new(@valid_config)

          enhanced = reviewer.enhance_system_prompt(nil)

          assert_equal "Focus on SOLID principles.", enhanced
        end

        def test_enhance_system_prompt_with_empty_base
          reviewer = Reviewer.new(@valid_config)

          enhanced = reviewer.enhance_system_prompt("")

          assert_equal "Focus on SOLID principles.", enhanced
        end

        def test_enhance_system_prompt_without_additions
          config = @valid_config.except(:system_prompt_additions)
          reviewer = Reviewer.new(config)
          base_prompt = "You are a code reviewer."

          enhanced = reviewer.enhance_system_prompt(base_prompt)

          assert_equal "You are a code reviewer.", enhanced
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
      end
    end
  end
end
